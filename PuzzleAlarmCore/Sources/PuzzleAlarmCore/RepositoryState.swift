import Foundation

public enum PersistenceError: Error, Equatable, Sendable {
    case corrupt
    case unsupportedSchema(Int)
    case conflict
    case interruptedInitialWrite
    case io(String)
    case duplicateOwnership(UUID)
}

public struct AlarmOwnership: Codable, Equatable, Sendable {
    public let alarmKitID: UUID
    public let sessionID: UUID?
    public let parentAlarmID: UUID
    public let ordinal: Int
    public let intendedDate: Date
    public let scheduling: SchedulingStatus
    public let cancellation: CancellationStatus
    public var isPrimary: Bool { ordinal == 0 }

    public init(alarmKitID: UUID, sessionID: UUID?, parentAlarmID: UUID, ordinal: Int,
                intendedDate: Date, scheduling: SchedulingStatus, cancellation: CancellationStatus) throws {
        try validateDate(intendedDate)
        try require((0...4).contains(ordinal) && (sessionID != nil || ordinal == 0), "Invalid ownership ordinal")
        self.alarmKitID = alarmKitID
        self.sessionID = sessionID
        self.parentAlarmID = parentAlarmID
        self.ordinal = ordinal
        self.intendedDate = intendedDate
        self.scheduling = scheduling
        self.cancellation = cancellation
    }

    private enum CodingKeys: String, CodingKey {
        case alarmKitID, sessionID, parentAlarmID, ordinal, intendedDate, scheduling, cancellation
    }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(alarmKitID: c.decode(UUID.self, forKey: .alarmKitID),
                      sessionID: c.decodeIfPresent(UUID.self, forKey: .sessionID),
                      parentAlarmID: c.decode(UUID.self, forKey: .parentAlarmID),
                      ordinal: c.decode(Int.self, forKey: .ordinal),
                      intendedDate: c.decode(Date.self, forKey: .intendedDate),
                      scheduling: c.decode(SchedulingStatus.self, forKey: .scheduling),
                      cancellation: c.decode(CancellationStatus.self, forKey: .cancellation))
    }
}

public struct RepositoryState: Codable, Equatable, Sendable {
    public var definitions: [AlarmDefinition]
    public var sessions: [PersistedSession]
    // Records without a retained session (including future ordinary alarms and
    // recovery tombstones). Session records must never be duplicated here.
    public var detachedOwnership: [AlarmOwnership]

    public init(definitions: [AlarmDefinition] = [], sessions: [PersistedSession] = [],
                detachedOwnership: [AlarmOwnership] = []) throws {
        self.definitions = definitions
        self.sessions = sessions
        self.detachedOwnership = detachedOwnership
        try validate()
    }

    // Canonical ledger view. Session facts are encoded exactly once, in session.
    public func ownershipLedger() throws -> [AlarmOwnership] {
        try sessions.flatMap { record in
            let session = record.session
            return try session.plan.alarms.enumerated().map { index, alarm in
                try AlarmOwnership(alarmKitID: alarm.id, sessionID: session.id,
                                   parentAlarmID: session.parentAlarmID, ordinal: alarm.ordinal,
                                   intendedDate: alarm.date, scheduling: session.scheduling[index],
                                   cancellation: session.cancellation[index])
            }
        } + detachedOwnership
    }

    public func validate() throws {
        try require(Set(definitions.map(\.id)).count == definitions.count, "Duplicate definition ID")
        try require(Set(sessions.map { $0.session.id }).count == sessions.count, "Duplicate session ID")
        for record in sessions { try record.validate() }
        let sessionIDs = Set(sessions.map { $0.session.id })
        for entry in detachedOwnership {
            try require(entry.sessionID.map { !sessionIDs.contains($0) } ?? true,
                        "Detached ownership duplicates an existing session authority")
        }
        var seen: Set<UUID> = []
        for entry in try ownershipLedger() {
            guard seen.insert(entry.alarmKitID).inserted else {
                throw PersistenceError.duplicateOwnership(entry.alarmKitID)
            }
        }
    }

    private enum CodingKeys: String, CodingKey { case definitions, sessions, detachedOwnership }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(definitions: c.decode([AlarmDefinition].self, forKey: .definitions),
                      sessions: c.decode([PersistedSession].self, forKey: .sessions),
                      detachedOwnership: c.decode([AlarmOwnership].self, forKey: .detachedOwnership))
    }
}
