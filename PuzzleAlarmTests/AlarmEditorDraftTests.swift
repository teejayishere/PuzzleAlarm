import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

final class AlarmEditorDraftTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_790_812_800)

    func testNewDraftIsOneTimeAndDomainDefaultsAreUsed() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        XCTAssertTrue(try draft.definition(at: now).weekdays.isEmpty)
        XCTAssertEqual(AlarmPresentation.repeatSummary(draft.weekdays), "Once")
        try draft.setMode(.challengesRequired)
        XCTAssertNotNil(draft.validationMessage)
        XCTAssertThrowsError(try draft.definition(at: now))
        try draft.add(.math, token: UUID())
        XCTAssertEqual(draft.sequence.items, [.math(try MathConfiguration())])
        XCTAssertNil(draft.validationMessage)
    }
    func testEditRoundTripPreservesIdentityTimeAndSound() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        draft.hour = 23; draft.minute = 59; draft.sound = .siren
        draft.weekdays = [.monday, .friday]
        let original = try draft.definition(at: now)
        var edit = AlarmEditorDraft(original)
        XCTAssertEqual(try edit.definition(at: now.addingTimeInterval(99)), original)
        edit.minute = 58
        let changed = try edit.definition(at: now.addingTimeInterval(1))
        XCTAssertEqual(changed.id, original.id)
        XCTAssertEqual(changed.createdAt, original.createdAt)
        XCTAssertEqual(changed.selectedSound, .bundled(.siren))
        XCTAssertEqual(changed.time.minute, 58)
        XCTAssertEqual(original.time.minute, 59)
    }
    func testChallengeOrderUniquenessAndQRIdentitySurviveRepeatedEdits() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        let token = UUID()
        try draft.setMode(.challengesRequired)
        try draft.add(.memory, token: UUID())
        try draft.add(.math, token: UUID())
        try draft.add(.qr, token: token)
        XCTAssertThrowsError(try draft.add(.qr, token: UUID()))
        try draft.move(1, by: -1)
        var restored = AlarmEditorDraft(try draft.definition(at: now))
        XCTAssertEqual(restored.sequence.items.map(\.kind), [.math, .memory, .qr])
        XCTAssertEqual(restored.sequence.items.last, .qr(QRConfiguration(token: token)))
        try restored.move(2, by: -1); try restored.move(1, by: 1)
        XCTAssertEqual(restored.sequence, draft.sequence)
        try restored.remove(0)
        XCTAssertEqual(restored.sequence.items.map(\.kind), [.memory, .qr])
        try restored.setMode(.annoyingOnly)
        XCTAssertTrue(try restored.definition(at: now).challengeSequence.items.isEmpty)
    }
    func testConfiguredMathAndMemoryPersistAndDelegateRanges() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        try draft.setMode(.challengesRequired)
        try draft.add(.math, token: UUID()); try draft.add(.memory, token: UUID())
        try draft.replace(0, with: .math(MathConfiguration(difficulty: .hard, requiredCorrect: 20)))
        try draft.replace(1, with: .memory(MemoryConfiguration(difficulty: .hard, sequenceLength: 12,
            displayDuration: 30, requiredRounds: 20)))
        let restored = AlarmEditorDraft(try draft.definition(at: now))
        XCTAssertEqual(restored.sequence, draft.sequence)
        XCTAssertThrowsError(try MathConfiguration(requiredCorrect: 21))
        XCTAssertThrowsError(try MemoryConfiguration(sequenceLength: 13))
    }
    func testWallTimeConversionDoesNotStoreAnArbitraryDate() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        draft.hour = 0; draft.minute = 5
        let date = draft.pickerDate
        draft.hour = 12; draft.pickerDate = date
        XCTAssertEqual(try draft.definition(at: now).time, try AlarmTime(hour: 0, minute: 5))
    }
    func testAllSoundChoicesAndRepeatLabels() throws {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        for sound in SoundChoice.allCases {
            draft.sound = sound
            XCTAssertEqual(AlarmEditorDraft(try draft.definition(at: now)).sound, sound)
        }
        XCTAssertEqual(AlarmPresentation.repeatSummary(Set(Weekday.allCases)), "Every day")
        XCTAssertEqual(AlarmPresentation.repeatSummary([.saturday, .sunday]), "Weekends")
        XCTAssertEqual(AlarmPresentation.repeatSummary([.monday, .wednesday, .friday]), "Mon, Wed, Fri")
    }
}
