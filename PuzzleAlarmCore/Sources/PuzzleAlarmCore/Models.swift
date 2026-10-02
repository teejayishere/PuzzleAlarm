import Foundation

public enum DomainError: Error, Equatable, Sendable {
    case invalidConfiguration(String)
    case invalidTransition
    case unknownAlarm
    case outOfOrder
}

func require(_ condition: Bool, _ message: String) throws {
    guard condition else { throw DomainError.invalidConfiguration(message) }
}

func validateDate(_ date: Date) throws {
    try require(date.timeIntervalSince1970.isFinite && date >= .distantPast && date <= .distantFuture,
                "Date outside supported range")
}

public enum Weekday: Int, Codable, CaseIterable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

public struct AlarmTime: Codable, Equatable, Sendable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) throws {
        try require((0...23).contains(hour) && (0...59).contains(minute), "Invalid wall-clock time")
        self.hour = hour
        self.minute = minute
    }

    private enum CodingKeys: String, CodingKey { case hour, minute }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(hour: c.decode(Int.self, forKey: .hour), minute: c.decode(Int.self, forKey: .minute))
    }
}

public enum DismissalMode: String, Codable, Sendable {
    case annoyingOnly = "annoying_only"
    case challengesRequired = "challenges_required"
}

public enum BundledSound: String, Codable, CaseIterable, Sendable {
    case harshBuzzer = "harsh_buzzer"
    case rapidBeeps = "rapid_beeps"
    case siren
    case escalating
}

// Selection identifiers only; no claim that these resources exist before Stage 11.
public enum SoundSelection: Codable, Equatable, Sendable {
    case systemDefault
    case bundled(BundledSound)
}

public struct AlarmDefinition: Codable, Equatable, Sendable {
    public let id: UUID
    public let time: AlarmTime
    // Empty means one-time at the next local wall-clock occurrence.
    public let weekdays: Set<Weekday>
    public let enabled: Bool
    public let dismissalMode: DismissalMode
    public let challengeSequence: ChallengeSequence
    public let selectedSound: SoundSelection
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID, time: AlarmTime, weekdays: Set<Weekday>, enabled: Bool,
        dismissalMode: DismissalMode, challengeSequence: ChallengeSequence,
        selectedSound: SoundSelection, createdAt: Date, updatedAt: Date
    ) throws {
        try validateDate(createdAt)
        try validateDate(updatedAt)
        try require(updatedAt >= createdAt, "Update precedes creation")
        try require(
            dismissalMode == .challengesRequired ? !challengeSequence.items.isEmpty : challengeSequence.items.isEmpty,
            "Challenge mode needs 1...3 challenges; annoying-only mode needs none"
        )
        self.id = id
        self.time = time
        self.weekdays = weekdays
        self.enabled = enabled
        self.dismissalMode = dismissalMode
        self.challengeSequence = challengeSequence
        self.selectedSound = selectedSound
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func settingEnabled(_ enabled: Bool, at date: Date) throws -> Self {
        try replacing(time: time, weekdays: weekdays, enabled: enabled, mode: dismissalMode,
                      challenges: challengeSequence, sound: selectedSound, at: date)
    }

    // Replacement is pure configuration editing; scheduling side effects belong to Stage 5.
    public func replacing(
        time: AlarmTime, weekdays: Set<Weekday>, enabled: Bool, mode: DismissalMode,
        challenges: ChallengeSequence, sound: SoundSelection, at date: Date
    ) throws -> Self {
        try require(date >= updatedAt, "Edit timestamp regressed")
        return try Self(id: id, time: time, weekdays: weekdays, enabled: enabled,
                        dismissalMode: mode, challengeSequence: challenges, selectedSound: sound,
                        createdAt: createdAt, updatedAt: date)
    }

    private enum CodingKeys: String, CodingKey {
        case id, time, weekdays, enabled, dismissalMode, challengeSequence, selectedSound, createdAt, updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: c.decode(UUID.self, forKey: .id), time: c.decode(AlarmTime.self, forKey: .time),
            weekdays: c.decode(Set<Weekday>.self, forKey: .weekdays),
            enabled: c.decode(Bool.self, forKey: .enabled),
            dismissalMode: c.decode(DismissalMode.self, forKey: .dismissalMode),
            challengeSequence: c.decode(ChallengeSequence.self, forKey: .challengeSequence),
            selectedSound: c.decode(SoundSelection.self, forKey: .selectedSound),
            createdAt: c.decode(Date.self, forKey: .createdAt),
            updatedAt: c.decode(Date.self, forKey: .updatedAt)
        )
    }
}
