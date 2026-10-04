import Foundation
import PuzzleAlarmCore

enum SoundChoice: String, CaseIterable, Identifiable {
    case systemDefault, harshBuzzer, rapidBeeps, siren, escalating
    var id: String { rawValue }
    var selection: SoundSelection {
        switch self {
        case .systemDefault: .systemDefault
        case .harshBuzzer: .bundled(.harshBuzzer)
        case .rapidBeeps: .bundled(.rapidBeeps)
        case .siren: .bundled(.siren)
        case .escalating: .bundled(.escalating)
        }
    }
    init(_ selection: SoundSelection) {
        self = Self.allCases.first { $0.selection == selection } ?? .systemDefault
    }
    var title: String {
        switch self {
        case .systemDefault: "System Default"
        case .harshBuzzer: "Harsh Buzzer"
        case .rapidBeeps: "Rapid Beeps"
        case .siren: "Siren"
        case .escalating: "Escalating"
        }
    }
}

struct AlarmEditorDraft: Identifiable {
    let id: UUID
    let createdAt: Date
    var original: AlarmDefinition?
    var hour: Int
    var minute: Int
    var weekdays: Set<Weekday>
    var enabled: Bool
    var mode: DismissalMode
    var sequence: ChallengeSequence
    var sound: SoundChoice

    init(id: UUID, now: Date) throws {
        self.id = id; createdAt = now; original = nil
        hour = 7; minute = 0; weekdays = []; enabled = true
        mode = .annoyingOnly; sequence = try ChallengeSequence([]); sound = .systemDefault
    }
    init(_ alarm: AlarmDefinition) {
        id = alarm.id; createdAt = alarm.createdAt; original = alarm
        hour = alarm.time.hour; minute = alarm.time.minute; weekdays = alarm.weekdays
        enabled = alarm.enabled; mode = alarm.dismissalMode
        sequence = alarm.challengeSequence; sound = SoundChoice(alarm.selectedSound)
    }
    mutating func setMode(_ value: DismissalMode) throws {
        mode = value
        if value == .annoyingOnly { sequence = try ChallengeSequence([]) }
    }
    mutating func add(_ kind: ChallengeKind, token: UUID) throws {
        let value: ChallengeConfiguration
        switch kind {
        case .math: value = .math(try MathConfiguration())
        case .memory: value = .memory(try MemoryConfiguration())
        case .qr: value = .qr(QRConfiguration(token: token))
        }
        sequence = try sequence.appending(value)
    }
    mutating func move(_ index: Int, by offset: Int) throws {
        sequence = try sequence.moving(from: index, to: index + offset)
    }
    mutating func remove(_ index: Int) throws { sequence = try sequence.removing(at: index) }
    mutating func replace(_ index: Int, with value: ChallengeConfiguration) throws {
        sequence = try sequence.replacing(at: index, with: value)
    }
    var validationMessage: String? {
        if mode == .challengesRequired && sequence.items.isEmpty { return "Add at least one challenge." }
        return nil
    }
    func definition(at now: Date) throws -> AlarmDefinition {
        let time = try AlarmTime(hour: hour, minute: minute)
        let challenges = mode == .annoyingOnly ? try ChallengeSequence([]) : sequence
        if let original {
            if time == original.time && weekdays == original.weekdays && enabled == original.enabled &&
                mode == original.dismissalMode && challenges == original.challengeSequence &&
                sound.selection == original.selectedSound { return original }
            return try original.replacing(time: time, weekdays: weekdays, enabled: enabled, mode: mode,
                challenges: challenges, sound: sound.selection, at: max(now, original.updatedAt))
        }
        return try AlarmDefinition(id: id, time: time, weekdays: weekdays, enabled: enabled,
            dismissalMode: mode, challengeSequence: challenges, selectedSound: sound.selection,
            createdAt: createdAt, updatedAt: max(now, createdAt))
    }
    // A fixed Gregorian reference day represents UI time only; it is never persisted.
    var pickerDate: Date {
        get { AlarmPresentation.wallCalendar.date(from: DateComponents(year: 2001, month: 1, day: 1,
                    hour: hour, minute: minute)) ?? createdAt }
        set {
            let components = AlarmPresentation.wallCalendar.dateComponents([.hour, .minute], from: newValue)
            hour = components.hour ?? hour; minute = components.minute ?? minute
        }
    }
}
