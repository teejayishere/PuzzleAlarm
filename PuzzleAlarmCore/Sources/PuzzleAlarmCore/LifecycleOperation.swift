import Foundation

// A durable command, not a second authority for current parent configuration.
// configuration is the immutable target generation; the parent may supersede it.
public struct LifecycleOperation: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Sendable { case ensure, disable, delete }
    public enum Status: String, Codable, Sendable { case pending, ready, failed }
    public enum Failure: String, Codable, Sendable {
        case scheduling, cancellation, missingAlarm, elapsedOccurrence, superseded
    }
    public let id: UUID
    public let configuration: AlarmDefinition
    public let context: ScheduleContext
    public var action: Action
    public var status: Status
    public var sessionID: UUID?
    public var ordinaryID: UUID?
    public var retiringIDs: [UUID]
    public var oneTimeConsumed: Bool
    public var failure: Failure?

    public init(id: UUID, configuration: AlarmDefinition, context: ScheduleContext,
                action: Action = .ensure, retiringIDs: [UUID] = []) {
        self.id = id; self.configuration = configuration; self.context = context
        self.action = action; status = .pending; self.retiringIDs = retiringIDs
        oneTimeConsumed = false
    }

    func validate(in state: RepositoryState) throws {
        try require(sessionID == nil || ordinaryID == nil, "Two target representations")
        try require(Set(retiringIDs).count == retiringIDs.count, "Duplicate retirement ID")
        try require(status == .failed ? failure != nil : failure == nil, "Invalid operation outcome")
        if let sessionID {
            guard let value = state.sessions.first(where: { $0.session.id == sessionID })?.session else {
                throw DomainError.invalidConfiguration("Missing operation session")
            }
            try require(value.parentAlarmID == configuration.id && value.definitionSnapshot == configuration,
                        "Wrong operation parent or snapshot")
        }
        if let ordinaryID {
            guard let entry = state.detachedOwnership.first(where: { $0.alarmKitID == ordinaryID }) else {
                throw DomainError.invalidConfiguration("Missing ordinary ownership")
            }
            try require(entry.parentAlarmID == configuration.id && entry.sessionID == nil,
                        "Wrong ordinary ownership")
            try require(configuration.dismissalMode == .annoyingOnly, "Wrong ordinary configuration")
        }
        let ledger = try state.ownershipLedger()
        for id in retiringIDs {
            try require(ledger.contains { $0.alarmKitID == id && $0.parentAlarmID == configuration.id },
                        "Missing retirement ownership")
        }
    }
}

extension RepositoryState {
    func definition(_ id: UUID) throws -> AlarmDefinition {
        guard let value = definitions.first(where: { $0.id == id }) else { throw DomainError.unknownAlarm }
        return value
    }

    func operation(_ parent: UUID) throws -> LifecycleOperation {
        guard let value = operations.first(where: { $0.configuration.id == parent }) else {
            throw DomainError.unknownAlarm
        }
        return value
    }

    mutating func put(_ operation: LifecycleOperation) {
        if let index = operations.firstIndex(where: { $0.configuration.id == operation.configuration.id }) {
            operations[index] = operation
        } else { operations.append(operation) }
    }

    mutating func updateSession(_ id: UUID, at date: Date,
                                _ body: (inout WakeUpSession) throws -> Void) throws {
        guard let index = sessions.firstIndex(where: { $0.session.id == id }) else { throw DomainError.unknownAlarm }
        let original = sessions[index]
        var value = original.session
        try body(&value)
        guard value != original.session else { return }
        sessions[index] = try PersistedSession(session: value, updatedAt: max(date, original.updatedAt),
            checkpoint: value.phase == .active ? original.checkpoint : nil)
    }

    mutating func updateDetached(_ id: UUID, scheduling: SchedulingStatus? = nil,
                                cancellation: CancellationStatus? = nil) throws {
        guard let index = detachedOwnership.firstIndex(where: { $0.alarmKitID == id }) else {
            throw DomainError.unknownAlarm
        }
        let old = detachedOwnership[index]
        detachedOwnership[index] = try AlarmOwnership(alarmKitID: id, sessionID: old.sessionID,
            parentAlarmID: old.parentAlarmID, ordinal: old.ordinal, intendedDate: old.intendedDate,
            scheduling: scheduling ?? old.scheduling, cancellation: cancellation ?? old.cancellation)
    }
}
