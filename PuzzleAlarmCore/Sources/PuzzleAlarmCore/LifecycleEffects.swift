import Foundation

extension AlarmLifecycleCoordinator {
    func scheduleSession(_ id: UUID, parent: UUID, token: UUID) async throws {
        let now = clock()
        var value = try await session(id)
        if value.phase == .active { return }
        if value.phase == .degraded {
            try await fail(parent, token: token, reason: .missingAlarm)
            try await cancelIDs(value.plan.alarms.map(\.id))
            return
        }
        if value.phase == .armed {
            let snapshot = try observed()
            try checkOwnership(try await state(), observed: snapshot)
            if let missing = value.plan.alarms.first(where: { item in !snapshot.contains { $0.id == item.id } }) {
                try await update { state in
                    _ = try self.checkedOperation(state, parent: parent, token: token)
                    try state.updateSession(id, at: now) { try $0.recordMissingArmedAlarm(id: missing.id) }
                }
                try await fail(parent, token: token, reason: .missingAlarm)
                try await cancelIDs(value.plan.alarms.map(\.id))
            }
            return
        }
        guard value.scheduledWakeUpDate > now else {
            try await fail(parent, token: token, reason: .elapsedOccurrence)
            try await cancelIDs(value.plan.alarms.map(\.id))
            return
        }
        if value.phase == .planned {
            try await update { state in
                _ = try self.checkedOperation(state, parent: parent, token: token)
                try state.updateSession(id, at: now) { try $0.beginScheduling() }
            }
        }
        value = try await session(id)
        guard value.phase == .scheduling else {
            try await fail(parent, token: token, reason: .scheduling)
            try await cancelIDs(value.plan.alarms.map(\.id))
            return
        }
        for (index, alarm) in value.plan.alarms.enumerated() {
            let fresh = try await session(id)
            let snapshot = try observed()
            try checkOwnership(try await state(), observed: snapshot)
            let present = snapshot.contains { $0.id == alarm.id }
            if fresh.scheduling[index] == .scheduled {
                if present { continue }
                try await fail(parent, token: token, reason: .missingAlarm)
                try await cancelIDs(value.plan.alarms.map(\.id))
                return
            }
            try await update { state in
                _ = try self.checkedOperation(state, parent: parent, token: token)
                try state.updateSession(id, at: now) { _ = try $0.beginScheduleAttempt(id: alarm.id) }
            }
            // Revalidate the current command after the persistence await.
            let latest = try await state()
            _ = try checkedOperation(latest, parent: parent, token: token)
            let effectSnapshot = try observed()
            try checkOwnership(latest, observed: effectSnapshot)
            if !effectSnapshot.contains(where: { $0.id == alarm.id }) {
                guard clock() < value.scheduledWakeUpDate else {
                    try await fail(parent, token: token, reason: .elapsedOccurrence)
                    try await cancelIDs(value.plan.alarms.map(\.id))
                    return
                }
                let request = try AlarmRequest(session: fresh, alarmID: alarm.id)
                let succeeded: Bool
                do {
                    let result = try await scheduler.schedule(request)
                    succeeded = result.id == alarm.id && result.scope == .puzzleAlarm
                } catch { succeeded = false }
                if !succeeded {
                    try await update { state in
                        try state.updateSession(id, at: now) { try $0.recordScheduleFailure(id: alarm.id) }
                    }
                    try await fail(parent, token: token, reason: .scheduling)
                    try await cancelIDs(value.plan.alarms.map(\.id))
                    return
                }
            }
            // Persistence errors propagate; an uncertain OS success must not be
            // relabeled as an acknowledged schedule failure.
            try await update { state in
                try state.updateSession(id, at: now) { try $0.recordScheduled(id: alarm.id) }
            }
        }
        guard clock() < value.scheduledWakeUpDate else {
            try await fail(parent, token: token, reason: .elapsedOccurrence)
            try await cancelIDs(value.plan.alarms.map(\.id))
            return
        }
        let final = try observed()
        try checkOwnership(try await state(), observed: final)
        guard value.plan.alarms.allSatisfy({ alarm in final.contains { $0.id == alarm.id } }) else {
            try await fail(parent, token: token, reason: .missingAlarm)
            try await cancelIDs(value.plan.alarms.map(\.id))
            return
        }
        try await update { state in
            _ = try self.checkedOperation(state, parent: parent, token: token)
            try state.updateSession(id, at: now) { try $0.arm() }
        }
    }

    func scheduleOrdinary(_ id: UUID, parent: UUID, token: UUID) async throws {
        let current = try await state()
        let operation = try checkedOperation(current, parent: parent, token: token)
        let entry = try ownership(id, in: current)
        let snapshot = try observed()
        try checkOwnership(current, observed: snapshot)
        let present = snapshot.contains { $0.id == id }
        if entry.scheduling == .scheduled {
            if present { return }
            if operation.configuration.weekdays.isEmpty && entry.intendedDate <= clock() {
                try await cancelIDs([id])
                try await consumeOneTime(parent: parent, token: token)
            } else {
                try await fail(parent, token: token, reason: .missingAlarm)
                try await cancelIDs([id])
            }
            return
        }
        if !present && operation.configuration.weekdays.isEmpty && entry.intendedDate <= clock() {
            try await cancelIDs([id])
            try await consumeOneTime(parent: parent, token: token)
            try await fail(parent, token: token, reason: .elapsedOccurrence)
            return
        }
        try await update { state in
            _ = try self.checkedOperation(state, parent: parent, token: token)
            try state.updateDetached(id, scheduling: .inFlight)
        }
        let latest = try await state()
        _ = try checkedOperation(latest, parent: parent, token: token)
        let effectSnapshot = try observed()
        try checkOwnership(latest, observed: effectSnapshot)
        if !effectSnapshot.contains(where: { $0.id == id }) {
            if operation.configuration.weekdays.isEmpty && entry.intendedDate <= clock() {
                try await cancelIDs([id])
                try await consumeOneTime(parent: parent, token: token)
                try await fail(parent, token: token, reason: .elapsedOccurrence)
                return
            }
            let request = try AlarmRequest(definition: operation.configuration, alarmID: id, date: entry.intendedDate)
            let succeeded: Bool
            do {
                let result = try await scheduler.schedule(request)
                succeeded = result.id == id && result.scope == .puzzleAlarm
            } catch { succeeded = false }
            if !succeeded {
                try await update { try $0.updateDetached(id, scheduling: .failed) }
                try await fail(parent, token: token, reason: .scheduling)
                try await cancelIDs([id])
                return
            }
        }
        try await update { try $0.updateDetached(id, scheduling: .scheduled) }
    }

    func cancelIDs(_ ids: [UUID]) async throws {
        for id in ids {
            let current = try await state()
            let entry = try ownership(id, in: current)
            if entry.cancellation == .succeeded { continue }
            let snapshot = try observed()
            try checkOwnership(current, observed: snapshot)
            let now = clock()
            let attached = entry.sessionID.flatMap { sessionID in
                current.sessions.first { $0.session.id == sessionID }?.session
            }
            if let attached {
                if attached.phase == .active { continue }
                if [.armed, .degraded].contains(attached.phase) && protected(attached, now: now, observed: snapshot) { continue }
                try await update { state in
                    try state.updateSession(attached.id, at: now) { session in
                        if [.planned, .scheduling, .armed, .degraded].contains(session.phase) { try session.requestRetirement() }
                        _ = try session.beginCancellation(id: id)
                    }
                }
            } else {
                try await update { try $0.updateDetached(id, cancellation: .inFlight) }
            }
            let latest = try await state()
            let effectSnapshot = try observed()
            try checkOwnership(latest, observed: effectSnapshot)
            let succeeded: Bool
            if effectSnapshot.contains(where: { $0.id == id }) {
                // Only durable, known ownership can reach this OS call.
                _ = try ownership(id, in: latest)
                do { try scheduler.cancel(id: id); succeeded = true }
                catch { succeeded = false }
            } else { succeeded = true }
            try await update { state in
                if let attached {
                    try state.updateSession(attached.id, at: now) {
                        try $0.recordCancellation(id: id, succeeded: succeeded)
                    }
                } else {
                    try state.updateDetached(id, cancellation: succeeded ? .succeeded : .failed)
                }
            }
        }
        // Cleanup is complete only after every ledger acknowledgment, never
        // merely because one cancel call succeeded or a snapshot was empty.
        let current = try await state()
        let touched = Set(ids)
        for record in current.sessions where record.session.plan.alarms.contains(where: { touched.contains($0.id) }) {
            let value = record.session
            guard value.remainingCancellationIDs.isEmpty else { continue }
            let now = max(clock(), value.challengeCompletedAt.last ?? value.createdAt)
            if [.completing, .cancellationPartiallyFailed].contains(value.phase) {
                try await update { state in
                    try state.updateSession(value.id, at: now) { try $0.finalizeCompletion(at: now) }
                }
            } else if [.cancelling, .schedulingFailed].contains(value.phase) {
                try await update { state in
                    try state.updateSession(value.id, at: now) { try $0.finishRetirement() }
                }
            }
        }
    }

    func session(_ id: UUID) async throws -> WakeUpSession {
        guard let value = try await state().sessions.first(where: { $0.session.id == id })?.session else {
            throw DomainError.unknownAlarm
        }
        return value
    }

    func ownership(_ id: UUID, in state: RepositoryState) throws -> AlarmOwnership {
        guard let value = try state.ownershipLedger().first(where: { $0.alarmKitID == id }) else {
            throw DomainError.unknownAlarm
        }
        return value
    }
}
