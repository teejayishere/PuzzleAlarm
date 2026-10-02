import Foundation
@testable import PuzzleAlarmCore

enum FixtureError: Error { case invalidDate }

func uuid(_ value: UInt8) -> UUID {
    UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, value))
}

func instant(_ value: String) throws -> Date {
    guard let result = ISO8601DateFormatter().date(from: value) else { throw FixtureError.invalidDate }
    return result
}

func configurations() throws -> [ChallengeConfiguration] {
    [
        .math(try MathConfiguration()),
        .memory(try MemoryConfiguration(requiredRounds: 3)),
        .qr(QRConfiguration(token: uuid(99)))
    ]
}

func definition(
    sequence: [ChallengeConfiguration]? = nil, hour: Int = 6, minute: Int = 30,
    weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
    enabled: Bool = true, mode: DismissalMode = .challengesRequired
) throws -> AlarmDefinition {
    try AlarmDefinition(
        id: uuid(1), time: AlarmTime(hour: hour, minute: minute), weekdays: weekdays, enabled: enabled,
        dismissalMode: mode, challengeSequence: ChallengeSequence(sequence ?? configurations()),
        selectedSound: .systemDefault,
        createdAt: instant("2025-01-01T00:00:00Z"), updatedAt: instant("2025-01-01T00:00:00Z")
    )
}

func session(sequence: [ChallengeConfiguration]? = nil) throws -> WakeUpSession {
    try WakeUpSession(
        id: uuid(2), definition: definition(sequence: sequence),
        context: ScheduleContext(timeZoneIdentifier: "America/Chicago"),
        plan: BackupPlan(at: instant("2026-10-05T11:30:00Z"), ids: (10...14).map { uuid(UInt8($0)) }),
        createdAt: instant("2026-10-01T00:00:00Z")
    )
}

func armedSession(sequence: [ChallengeConfiguration]? = nil) throws -> WakeUpSession {
    var value = try session(sequence: sequence)
    try value.beginScheduling()
    for alarm in value.plan.alarms {
        try value.beginScheduleAttempt(id: alarm.id)
        try value.recordScheduled(id: alarm.id)
    }
    try value.arm()
    return value
}

func activeSession(sequence: [ChallengeConfiguration]? = nil) throws -> WakeUpSession {
    var value = try armedSession(sequence: sequence)
    try value.activate(at: value.scheduledWakeUpDate)
    return value
}

func solvedSession() throws -> WakeUpSession {
    var value = try activeSession()
    for index in 0..<value.definitionSnapshot.challengeSequence.items.count {
        try value.recordChallengeSuccess(expectedIndex: index, at: value.scheduledWakeUpDate)
    }
    return value
}

func cancelAll(_ value: inout WakeUpSession) throws {
    for id in value.remainingCancellationIDs {
        try value.beginCancellation(id: id)
        try value.recordCancellation(id: id, succeeded: true)
    }
}

func roundTrip<T: Codable>(_ value: T) throws -> T {
    try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
}

func mutatedJSON<T: Encodable>(
    _ value: T, _ mutate: (inout [String: Any]) -> Void
) throws -> Data {
    let data = try JSONEncoder().encode(value)
    guard var object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw FixtureError.invalidDate
    }
    mutate(&object)
    return try JSONSerialization.data(withJSONObject: object)
}
