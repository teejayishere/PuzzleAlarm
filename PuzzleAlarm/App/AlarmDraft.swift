import Foundation
import PuzzleAlarmCore

struct ChallengeDraft: Identifiable {
    var id: ChallengeKind { kind }
    let kind: ChallengeKind
    var difficulty: Difficulty = .medium
    var correctCount = 5
    var length = 6
    var seconds: Double = 3
    var rounds = 1
    var token = UUID()

    init(kind: ChallengeKind) { self.kind = kind }

    init(_ configuration: ChallengeConfiguration) {
        kind = configuration.kind
        switch configuration {
        case let .math(value): difficulty = value.difficulty; correctCount = value.requiredCorrect
        case let .memory(value):
            difficulty = value.difficulty; length = value.sequenceLength
            seconds = value.displayDuration; rounds = value.requiredRounds
        case let .qr(value): token = value.token
        }
    }

    func configuration() throws -> ChallengeConfiguration {
        switch kind {
        case .math: return .math(try MathConfiguration(difficulty: difficulty, requiredCorrect: correctCount))
        case .memory:
            return .memory(try MemoryConfiguration(difficulty: difficulty, sequenceLength: length,
                displayDuration: Double(seconds), requiredRounds: rounds))
        case .qr: return .qr(QRConfiguration(token: token))
        }
    }
}

struct AlarmDraft: Identifiable {
    let id: UUID
    let original: AlarmDefinition?
    var hour: Int
    var minute: Int
    var weekdays: Set<Weekday>
    var enabled: Bool
    var mode: DismissalMode
    var challenges: [ChallengeDraft]
    var soundIndex: Int

    init(_ definition: AlarmDefinition? = nil) {
        original = definition
        id = definition?.id ?? UUID()
        hour = definition?.time.hour ?? 7
        minute = definition?.time.minute ?? 0
        weekdays = definition?.weekdays ?? []
        enabled = definition?.enabled ?? true
        mode = definition?.dismissalMode ?? .annoyingOnly
        challenges = definition?.challengeSequence.items.map(ChallengeDraft.init) ?? []
        soundIndex = Self.sounds.firstIndex(of: definition?.selectedSound ?? .systemDefault) ?? 0
    }

    static let sounds: [SoundSelection] = [.systemDefault] + BundledSound.allCases.map { .bundled($0) }
    static let soundNames = ["System default", "Harsh buzzer", "Rapid beeps", "Siren", "Escalating"]

    // A time-of-day is not today's occurrence. A fixed UTC reference prevents
    // a DST gap on today's date from silently changing the selected hour.
    static let timePickerCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    var timeSelection: Date {
        get { Date(timeIntervalSinceReferenceDate: Double(hour * 3_600 + minute * 60)) }
        set {
            hour = Self.timePickerCalendar.component(.hour, from: newValue)
            minute = Self.timePickerCalendar.component(.minute, from: newValue)
        }
    }

    var canSave: Bool { mode == .annoyingOnly || !challenges.isEmpty }

    mutating func add(_ kind: ChallengeKind) {
        guard !challenges.contains(where: { $0.kind == kind }) else { return }
        challenges.append(ChallengeDraft(kind: kind))
    }

    mutating func move(_ index: Int, by offset: Int) {
        let target = index + offset
        guard challenges.indices.contains(index), challenges.indices.contains(target) else { return }
        challenges.swapAt(index, target)
    }

    func definition(at now: Date) throws -> AlarmDefinition {
        let sequence = try ChallengeSequence(mode == .annoyingOnly ? [] : challenges.map { try $0.configuration() })
        let time = try AlarmTime(hour: hour, minute: minute)
        let sound = Self.sounds[soundIndex]
        if let original {
            return try original.replacing(time: time, weekdays: weekdays, enabled: enabled,
                mode: mode, challenges: sequence, sound: sound, at: max(now, original.updatedAt))
        }
        return try AlarmDefinition(id: id, time: time, weekdays: weekdays, enabled: enabled,
            dismissalMode: mode, challengeSequence: sequence, selectedSound: sound,
            createdAt: now, updatedAt: now)
    }
}

extension ChallengeKind {
    var title: String {
        switch self { case .math: "Math"; case .memory: "Memory"; case .qr: "QR Code" }
    }
}

extension Weekday {
    var title: String { ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][rawValue - 1] }
}
