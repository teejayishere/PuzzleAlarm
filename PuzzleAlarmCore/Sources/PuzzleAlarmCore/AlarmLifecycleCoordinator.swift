import Foundation

public enum LifecycleError: Error, Equatable, Sendable {
    case busy, conflictLimit, superseded, foreignOwnership(UUID), duplicateObserved(UUID)
}

public struct LifecycleReport: Equatable, Sendable {
    public enum Issue: Equatable, Sendable {
        case operationFailed(UUID, LifecycleOperation.Failure)
        case activeAlarmMissing(UUID)
        case orphaned(UUID)
        case stalePresent(UUID)
        case deletionDeferred(UUID)
    }
    public let wasMissing: Bool
    public let state: RepositoryState
    public let issues: [Issue]
}

// One live instance per repository owns OS effects. Reentrant lifecycle commands
// are rejected explicitly; repository CAS still protects other storage writers.
public actor AlarmLifecycleCoordinator {
    let repository: any PuzzleAlarmRepository
    let scheduler: any AlarmScheduling
    let clock: @Sendable () -> Date
    let makeID: @Sendable () -> UUID
    var busy = false

    public init(repository: any PuzzleAlarmRepository, scheduler: any AlarmScheduling,
                clock: @escaping @Sendable () -> Date = { Date() },
                makeID: @escaping @Sendable () -> UUID = { UUID() }) {
        self.repository = repository; self.scheduler = scheduler
        self.clock = clock; self.makeID = makeID
    }

    public func startup(context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        return try await recover(context: context)
    }

    public func create(_ definition: AlarmDefinition, context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        _ = try observed()
        try await update { state in
            if let prior = state.definitions.first(where: { $0.id == definition.id }) {
                guard prior == definition else { throw LifecycleError.superseded }
                return
            }
            // Retained delete tombstones prohibit accidentally reusing an identity.
            try require(!state.operations.contains { $0.configuration.id == definition.id }, "Retired definition ID")
            state.definitions.append(definition)
        }
        return try await recover(context: context)
    }

    public func enable(_ id: UUID, context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let alarms = try observed()
        let now = clock()
        try await update { state in
            let old = try state.definition(id)
            if state.operations.first(where: { $0.configuration.id == id })?.oneTimeConsumed == true { return }
            if old.enabled { return }
            let enabled = try old.settingEnabled(true, at: now)
            state.definitions[state.definitions.firstIndex(where: { $0.id == id })!] = enabled
            state.put(try self.prepared(state, definition: enabled, action: .ensure,
                                       context: context, now: now, observed: alarms))
        }
        return try await recover(context: context)
    }

    public func disable(_ id: UUID, context: ScheduleContext) async throws -> LifecycleReport {
        try await retire(id, action: .disable, context: context)
    }

    public func delete(_ id: UUID, context: ScheduleContext) async throws -> LifecycleReport {
        try await retire(id, action: .delete, context: context)
    }

    private func retire(_ id: UUID, action: LifecycleOperation.Action,
                        context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let alarms = try observed()
        let now = clock()
        try await update { state in
            guard let index = state.definitions.firstIndex(where: { $0.id == id }) else { return }
            if let prior = state.operations.first(where: { $0.configuration.id == id }),
               prior.action == action && !state.definitions[index].enabled { return }
            let old = state.definitions[index]
            let disabled = try old.enabled ? old.settingEnabled(false, at: now) : old
            state.definitions[index] = disabled
            var operation = try self.prepared(state, definition: disabled, action: action,
                                              context: context, now: now, observed: alarms)
            operation.oneTimeConsumed = old.weekdays.isEmpty
            state.put(operation)
        }
        return try await recover(context: context)
    }

    public func edit(_ replacement: AlarmDefinition, expecting original: AlarmDefinition,
                     context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let alarms = try observed()
        let now = clock()
        try await update { state in
            let old = try state.definition(replacement.id)
            if old == replacement { return }
            guard old == original else { throw LifecycleError.superseded }
            try require(replacement.id == original.id && replacement.createdAt == original.createdAt &&
                        replacement.updatedAt >= original.updatedAt, "Invalid edit identity/time")
            state.definitions[state.definitions.firstIndex(where: { $0.id == replacement.id })!] = replacement
            state.put(try self.prepared(state, definition: replacement,
                action: replacement.enabled ? .ensure : .disable, context: context, now: now, observed: alarms))
        }
        return try await recover(context: context)
    }

    public func retry(_ id: UUID, context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let now = clock()
        _ = try observed()
        try await update { state in
            var operation = try state.operation(id)
            guard operation.status == .failed && !operation.oneTimeConsumed else { return }
            if let sessionID = operation.sessionID,
               let session = state.sessions.first(where: { $0.session.id == sessionID })?.session,
               session.phase == .cancelled {
                try state.updateSession(sessionID, at: now) { try $0.restartAfterRollback(at: now) }
            }
            if let ordinaryID = operation.ordinaryID,
               let entry = state.detachedOwnership.first(where: { $0.alarmKitID == ordinaryID }),
               entry.cancellation == .succeeded {
                try require(entry.intendedDate > now || !operation.configuration.weekdays.isEmpty,
                            "Cannot retry elapsed one-time occurrence")
                try state.updateDetached(ordinaryID, scheduling: .planned, cancellation: .notRequested)
            }
            operation.status = .pending; operation.failure = nil
            state.put(operation)
        }
        return try await recover(context: context)
    }

    public func scheduleNextOccurrence(_ id: UUID, context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        _ = try await state().definition(id)
        return try await recover(context: context)
    }

    // This accepts no success event. It only cleans sessions already moved to
    // completing by the separately trusted domain challenge transitions.
    public func finishConfirmedChallenges(context: ScheduleContext) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        return try await recover(context: context)
    }

    func enter() throws {
        guard !busy else { throw LifecycleError.busy }
        busy = true
    }

    func state() async throws -> RepositoryState {
        switch try await repository.load() {
        case .missing: return try RepositoryState()
        case let .loaded(snapshot, _): return snapshot.state
        }
    }

    @discardableResult
    func update(_ change: (inout RepositoryState) throws -> Void) async throws -> RepositoryState {
        for _ in 0..<3 {
            let read = try await repository.load()
            var value: RepositoryState
            switch read {
            case .missing: value = try RepositoryState()
            case let .loaded(snapshot, _): value = snapshot.state
            }
            let previous = value
            try change(&value)
            try value.validate()
            if value == previous { return previous }
            do { return try await repository.commit(value, expecting: read.version).state }
            catch PersistenceError.conflict { continue }
        }
        throw LifecycleError.conflictLimit
    }

    func observed() throws -> [RegisteredAlarm] {
        let values = try scheduler.currentAlarms()
        var seen: Set<UUID> = []
        for value in values {
            guard seen.insert(value.id).inserted else { throw LifecycleError.duplicateObserved(value.id) }
        }
        return values
    }

    func checkOwnership(_ state: RepositoryState, observed: [RegisteredAlarm]) throws {
        let known = Set(try state.ownershipLedger().map(\.alarmKitID))
        for value in observed where value.scope == .foreign && known.contains(value.id) {
            throw LifecycleError.foreignOwnership(value.id)
        }
    }

    func checkedOperation(_ state: RepositoryState, parent: UUID, token: UUID) throws -> LifecycleOperation {
        let operation = try state.operation(parent)
        guard operation.id == token else { throw LifecycleError.superseded }
        if operation.action == .ensure && !operation.oneTimeConsumed {
            guard try state.definition(parent) == operation.configuration else { throw LifecycleError.superseded }
        }
        return operation
    }

    func protected(_ session: WakeUpSession, now: Date, observed: [RegisteredAlarm]) -> Bool {
        if [.active, .completing, .cancellationPartiallyFailed].contains(session.phase) { return true }
        return [.armed, .degraded].contains(session.phase) && (session.scheduledWakeUpDate <= now ||
            observed.contains { $0.state == .alerting && session.plan.alarms.map(\.id).contains($0.id) })
    }

    func prepared(_ state: RepositoryState, definition: AlarmDefinition, action: LifecycleOperation.Action,
                  context: ScheduleContext, now: Date, observed: [RegisteredAlarm]) throws -> LifecycleOperation {
        let protectedIDs = Set(state.sessions.filter { protected($0.session, now: now, observed: observed) }
            .flatMap { $0.session.plan.alarms.map(\.id) })
        let retire = try state.ownershipLedger().filter {
            $0.parentAlarmID == definition.id && $0.cancellation != .succeeded && !protectedIDs.contains($0.alarmKitID)
        }.map(\.alarmKitID)
        var operation = LifecycleOperation(id: makeID(), configuration: definition, context: context,
                                  action: action, retiringIDs: retire)
        if action == .ensure, let existing = state.sessions.first(where: {
            $0.session.definitionSnapshot == definition &&
            ![.completed, .cancelled].contains($0.session.phase)
        })?.session {
            operation.sessionID = existing.id
            operation.retiringIDs.removeAll { existing.plan.alarms.map(\.id).contains($0) }
        }
        return operation
    }

    func fail(_ parent: UUID, token: UUID, reason: LifecycleOperation.Failure) async throws {
        try await update { state in
            var operation = try state.operation(parent)
            guard operation.id == token else { throw LifecycleError.superseded }
            operation.status = .failed; operation.failure = reason
            state.put(operation)
        }
    }
}
