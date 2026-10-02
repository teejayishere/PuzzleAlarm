import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func configurationDefaultsAndBounds() throws {
    let math = try MathConfiguration()
    #expect(math.difficulty == .medium)
    #expect(math.requiredCorrect == 5)
    for (difficulty, length) in [(Difficulty.easy, 4), (.medium, 6), (.hard, 8)] {
        #expect(try MemoryConfiguration(difficulty: difficulty).sequenceLength == length)
    }
    for bad in [-1, 0, 21, Int.max] {
        #expect(throws: DomainError.self) { try MathConfiguration(requiredCorrect: bad) }
        #expect(throws: DomainError.self) { try MemoryConfiguration(requiredRounds: bad) }
    }
    for bad in [Double.nan, .infinity, -1, 0, 31] {
        #expect(throws: DomainError.self) { try MemoryConfiguration(displayDuration: bad) }
    }
    for length in [0, 1, 13, Int.max] {
        #expect(throws: DomainError.self) { try MemoryConfiguration(sequenceLength: length) }
    }
    #expect(throws: DomainError.self) { try AlarmTime(hour: 24, minute: 0) }
    #expect(throws: DomainError.self) { try AlarmTime(hour: -1, minute: 0) }
    #expect(throws: DomainError.self) { try AlarmTime(hour: 1, minute: 60) }
    #expect(try AlarmTime(hour: 0, minute: 0).hour == 0)
    #expect(try AlarmTime(hour: 23, minute: 59).minute == 59)
}

@Test func sequenceEditingPreservesOrderAndRejectsDuplicates() throws {
    let configs = try configurations()
    var sequence = try ChallengeSequence([])
    for item in configs { sequence = try sequence.appending(item) }
    #expect(sequence.items == configs)
    let moved = try sequence.moving(from: 2, to: 0)
    #expect(moved.items.map(\.kind) == [.qr, .math, .memory])
    #expect(try moved.moving(from: 0, to: 2) == sequence)
    #expect(try sequence.moving(from: 1, to: 1) == sequence)
    #expect(try moved.removing(at: 1).items.map(\.kind) == [.qr, .memory])
    #expect(throws: DomainError.self) { try sequence.appending(configs[0]) }
    #expect(throws: DomainError.self) { try ChallengeSequence([configs[1], configs[1]]) }
    #expect(throws: DomainError.self) { try sequence.replacing(at: 0, with: configs[1]) }
    #expect(throws: DomainError.self) { try sequence.removing(at: -1) }
    #expect(throws: DomainError.self) { try sequence.moving(from: 0, to: 3) }
    let easy = ChallengeConfiguration.math(try MathConfiguration(difficulty: .easy, requiredCorrect: 2))
    #expect(try sequence.replacing(at: 0, with: easy).items == [easy, configs[1], configs[2]])
    #expect(try roundTrip(moved) == moved)
}

@Test func definitionValidationEditsAndSoundRoundTrips() throws {
    let alarm = try definition()
    #expect(try roundTrip(alarm) == alarm)
    #expect(alarm.dismissalMode == .challengesRequired)
    let date = try instant("2026-10-01T00:00:00Z")
    let disabled = try alarm.settingEnabled(false, at: date)
    #expect(!disabled.enabled)
    #expect(try disabled.settingEnabled(true, at: date).enabled)
    #expect(disabled.id == alarm.id)
    #expect(disabled.createdAt == alarm.createdAt)
    let revised = try alarm.replacing(
        time: AlarmTime(hour: 23, minute: 59), weekdays: [.sunday], enabled: true,
        mode: .annoyingOnly, challenges: ChallengeSequence([]), sound: .bundled(.siren), at: date
    )
    #expect(revised.time.hour == 23 && revised.weekdays == [.sunday])
    #expect(revised.selectedSound == .bundled(.siren))
    #expect(try roundTrip(revised) == revised)
    #expect(throws: DomainError.self) { try definition(sequence: []) }
    #expect(throws: DomainError.self) { try definition(mode: .annoyingOnly) }
    #expect(throws: DomainError.self) { try alarm.settingEnabled(false, at: .distantPast) }
    for sound in BundledSound.allCases {
        #expect(try roundTrip(SoundSelection.bundled(sound)) == .bundled(sound))
    }
    #expect(try roundTrip(SoundSelection.systemDefault) == .systemDefault)
    for config in try configurations() { #expect(try roundTrip(config) == config) }
}

@Test func invalidDecodedConfigurationCannotBypassInitializers() throws {
    let alarm = try definition()
    let time = try AlarmTime(hour: 1, minute: 0)
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(AlarmTime.self, from: mutatedJSON(time) { $0["hour"] = 99 })
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(AlarmDefinition.self, from: mutatedJSON(alarm) { $0["dismissalMode"] = "unknown" })
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(AlarmDefinition.self, from: mutatedJSON(alarm) { $0["weekdays"] = [0, 8] })
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(MathConfiguration.self, from: mutatedJSON(MathConfiguration()) {
            $0["requiredCorrect"] = 0
        })
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(MemoryConfiguration.self, from: mutatedJSON(MemoryConfiguration()) {
            $0["displayDuration"] = -5
        })
    }
    let sequence = try ChallengeSequence(configurations())
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(ChallengeSequence.self, from: mutatedJSON(sequence) { object in
            if let items = object["items"] as? [Any] { object["items"] = items + items }
        })
    }
}

@Test func qrTargetIsStableUniqueAndRoundTrips() throws {
    let first = QRConfiguration(token: uuid(1))
    let second = QRConfiguration(token: uuid(2))
    #expect(first.expectedPayload == "puzzlealarm://challenge/00000000-0000-0000-0000-000000000001")
    #expect(first.expectedPayload != second.expectedPayload)
    #expect(try roundTrip(first) == first)
}
