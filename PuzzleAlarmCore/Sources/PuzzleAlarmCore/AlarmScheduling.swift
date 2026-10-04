import Foundation

public enum AlarmAuthorization: Equatable, Sendable {
    case notDetermined, authorized, denied, unknown
}

public struct RegisteredAlarm: Equatable, Sendable {
    public enum State: Equatable, Sendable { case scheduled, alerting, countdown, paused, unknown }
    public enum Scope: Equatable, Sendable { case puzzleAlarm, foreign }
    public let id: UUID
    public let state: State
    public let scope: Scope
    public init(id: UUID, state: State, scope: Scope = .puzzleAlarm) {
        self.id = id; self.state = state; self.scope = scope
    }
}

public struct AlarmRequest: Equatable, Sendable {
    public enum Schedule: Equatable, Sendable {
        case fixed(Date)
        case weekly(AlarmTime, Set<Weekday>)
    }
    public let plannedAlarm: PlannedAlarm
    public let sessionID: UUID?
    public let parentAlarmID: UUID
    public let selectedSound: SoundSelection
    public let schedule: Schedule

    public init(session: WakeUpSession, alarmID: UUID) throws {
        guard let alarm = session.plan.alarms.first(where: { $0.id == alarmID }) else {
            throw DomainError.unknownAlarm
        }
        plannedAlarm = alarm
        sessionID = session.id
        parentAlarmID = session.parentAlarmID
        selectedSound = session.definitionSnapshot.selectedSound
        schedule = .fixed(alarm.date)
    }

    public init(definition: AlarmDefinition, alarmID: UUID, date: Date) throws {
        try validateDate(date)
        try require(definition.dismissalMode == .annoyingOnly, "Ordinary request requires ordinary mode")
        plannedAlarm = PlannedAlarm(id: alarmID, date: date, ordinal: 0)
        sessionID = nil
        parentAlarmID = definition.id
        selectedSound = definition.selectedSound
        schedule = definition.weekdays.isEmpty ? .fixed(date) : .weekly(definition.time, definition.weekdays)
    }
}

// One boundary, shared by the application service, production adapter and fake.
// Snapshot scope is explicit; only the Apple app-scoped adapter labels all results owned.
public protocol AlarmScheduling: Sendable {
    var authorization: AlarmAuthorization { get }
    func requestAuthorization() async throws -> AlarmAuthorization
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm
    func cancel(id: UUID) throws
    func currentAlarms() throws -> [RegisteredAlarm]
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async
}
