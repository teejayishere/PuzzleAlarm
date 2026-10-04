import Foundation

extension AlarmLifecycleCoordinator {
    func recover(context: ScheduleContext) async throws -> LifecycleReport {
        let initial = try await repository.load()
        let wasMissing = initial == .missing
        let now = clock()
        try validateDate(now)
        let snapshot = try observed()
        let initialState = try await state()
        try checkOwnership(initialState, observed: snapshot)

        // Due challenge occurrences stay mandatory even if Stop removed every OS ID.
        for record in initialState.sessions {
            let value = record.session
            if value.phase == .armed && value.scheduledWakeUpDate <= now {
                try await update { state in
                    try state.updateSession(value.id, at: now) { try $0.activate(at: now) }
                }
            }
            if [.completing, .cancellationPartiallyFailed, .cancelling, .schedulingFailed].contains(value.phase) {
                try await cancelIDs(value.plan.alarms.map(\.id))
            }
        }

        // Legacy definitions/sessions are adopted where a matching immutable
        // snapshot proves the relationship; never reconstruct links from the OS.
        let current = try await state()
        for definition in current.definitions {
            try await update { state in
                let actual = try state.definition(definition.id)
                if let old = state.operations.first(where: { $0.configuration.id == actual.id }) {
                    if old.oneTimeConsumed || old.action == .delete { return }
                    if old.configuration == actual { return }
                }
                state.put(try self.prepared(state, definition: actual,
                    action: actual.enabled ? .ensure : .disable, context: context, now: now, observed: snapshot))
            }
        }

        for operation in try await state().operations {
            if operation.action == .ensure {
                try await ensureTarget(parent: operation.configuration.id, token: operation.id, context: context)
            } else {
                try await cancelIDs(operation.retiringIDs)
                try await finishRetirementOperation(parent: operation.configuration.id, token: operation.id)
            }
        }
        let result = try await state()
        let finalSnapshot = try observed()
        try checkOwnership(result, observed: finalSnapshot)
        let inventory = try ReconciliationInventory(state: result,
            observedOwnedIDs: finalSnapshot.filter { $0.scope == .puzzleAlarm }.map(\.id))
        var issues: [LifecycleReport.Issue] = []
        for item in inventory.entries {
            if item.status == .potentiallyOrphanedOwned { issues.append(.orphaned(item.id)) }
            if item.status == .stalePresent { issues.append(.stalePresent(item.id)) }
            if item.status == .persistedMissing,
               let id = item.ownership?.sessionID,
               result.sessions.contains(where: { $0.session.id == id && $0.session.phase == .active }) {
                issues.append(.activeAlarmMissing(item.id))
            }
        }
        for operation in result.operations {
            if let failure = operation.failure { issues.append(.operationFailed(operation.configuration.id, failure)) }
            if operation.action == .delete && result.definitions.contains(where: { $0.id == operation.configuration.id }) {
                issues.append(.deletionDeferred(operation.configuration.id))
            }
        }
        return LifecycleReport(wasMissing: wasMissing, state: result, issues: issues)
    }

    func ensureTarget(parent: UUID, token: UUID, context: ScheduleContext) async throws {
        var operation = try checkedOperation(try await state(), parent: parent, token: token)
        if operation.oneTimeConsumed { return }
        if operation.status == .failed && operation.failure != .cancellation {
            // Automatic recovery retries cleanup only. Rescheduling a failed
            // generation needs explicit retry, preventing an infinite alarm loop.
            let ids = try targetIDs(operation, in: await state())
            try await cancelIDs(ids)
            return
        }

        if let sessionID = operation.sessionID,
           let value = try await state().sessions.first(where: { $0.session.id == sessionID })?.session {
            if value.phase == .active { return }
            if [.completing, .cancellationPartiallyFailed].contains(value.phase) {
                try await cancelIDs(value.plan.alarms.map(\.id))
                return
            }
            if value.phase == .completed {
                if operation.configuration.weekdays.isEmpty {
                    try await consumeOneTime(parent: parent, token: token)
                    return
                }
                let now = clock()
                try await update { state in
                    _ = try self.checkedOperation(state, parent: parent, token: token)
                    state.put(LifecycleOperation(id: self.makeID(), configuration: try state.definition(parent),
                                                 context: context))
                }
                let next = try await state().operation(parent)
                // Only one successor is created in this call; it is strictly future.
                try await allocateTarget(parent: parent, token: next.id, after: max(now, value.scheduledWakeUpDate))
                try await ensureTarget(parent: parent, token: next.id, context: context)
                return
            }
            if value.phase == .cancelled && operation.status != .failed {
                try await fail(parent, token: token, reason: .scheduling)
                return
            }
        }
        if operation.sessionID == nil && operation.ordinaryID == nil {
            try await allocateTarget(parent: parent, token: token, after: clock())
        }
        operation = try await state().operation(parent)
        if let sessionID = operation.sessionID {
            try await scheduleSession(sessionID, parent: parent, token: token)
        } else if let id = operation.ordinaryID {
            try await scheduleOrdinary(id, parent: parent, token: token)
        }
        operation = try await state().operation(parent)
        guard operation.status != .failed && !operation.oneTimeConsumed else { return }
        try await cancelIDs(operation.retiringIDs)
        let current = try await state()
        let unresolved = try current.ownershipLedger().contains {
            operation.retiringIDs.contains($0.alarmKitID) && $0.cancellation != .succeeded
        }
        if unresolved {
            try await fail(parent, token: token, reason: .cancellation)
        } else {
            try await update { state in
                var value = try self.checkedOperation(state, parent: parent, token: token)
                value.status = .ready; value.failure = nil
                state.put(value)
            }
        }
    }

    func allocateTarget(parent: UUID, token: UUID, after: Date) async throws {
        let now = clock()
        let observed = try observed()
        try await update { state in
            var operation = try self.checkedOperation(state, parent: parent, token: token)
            guard operation.sessionID == nil && operation.ordinaryID == nil else { return }
            guard let date = try OccurrenceCalculator.next(for: operation.configuration,
                                                          after: after, context: operation.context) else { return }
            let occupied = Set(observed.map(\.id) + (try state.ownershipLedger().map(\.alarmKitID)))
            if operation.configuration.dismissalMode == .challengesRequired {
                let id = self.makeID()
                let ids = (0..<5).map { _ in self.makeID() }
                try require(ids.allSatisfy { !occupied.contains($0) }, "Generated alarm ID collision")
                let session = try WakeUpSession(id: id, definition: operation.configuration,
                    context: operation.context, plan: BackupPlan(at: date, ids: ids), createdAt: now)
                state.sessions.append(try PersistedSession(session: session, updatedAt: now))
                operation.sessionID = id
            } else {
                let id = self.makeID()
                try require(!occupied.contains(id), "Generated alarm ID collision")
                state.detachedOwnership.append(try AlarmOwnership(alarmKitID: id, sessionID: nil,
                    parentAlarmID: parent, ordinal: 0, intendedDate: date,
                    scheduling: .planned, cancellation: .notRequested))
                operation.ordinaryID = id
            }
            state.put(operation)
        }
    }

    func targetIDs(_ operation: LifecycleOperation, in state: RepositoryState) throws -> [UUID] {
        if let id = operation.ordinaryID { return [id] }
        if let id = operation.sessionID {
            guard let session = state.sessions.first(where: { $0.session.id == id })?.session else {
                throw DomainError.unknownAlarm
            }
            return session.plan.alarms.map(\.id)
        }
        return []
    }

    func consumeOneTime(parent: UUID, token: UUID) async throws {
        let now = clock()
        try await update { state in
            var operation = try self.checkedOperation(state, parent: parent, token: token)
            operation.oneTimeConsumed = true; operation.status = .ready; operation.failure = nil
            if let index = state.definitions.firstIndex(where: { $0.id == parent }), state.definitions[index].enabled {
                state.definitions[index] = try state.definitions[index].settingEnabled(false, at: now)
            }
            state.put(operation)
        }
    }

    func finishRetirementOperation(parent: UUID, token: UUID) async throws {
        let now = clock()
        let snapshot = try observed()
        try await update { state in
            var operation = try state.operation(parent)
            guard operation.id == token else { throw LifecycleError.superseded }
            let unresolved = try state.ownershipLedger().contains {
                operation.retiringIDs.contains($0.alarmKitID) && $0.cancellation != .succeeded
            }
            operation.status = unresolved ? .failed : .ready
            operation.failure = unresolved ? .cancellation : nil
            if operation.action == .delete && !unresolved {
                let protected = state.sessions.contains {
                    $0.session.parentAlarmID == parent && self.protected($0.session, now: now, observed: snapshot)
                }
                if !protected { state.definitions.removeAll { $0.id == parent } }
            }
            state.put(operation)
        }
    }
}
