#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class ChallengeConfigurationTests: XCTestCase, @unchecked Sendable {
    func testMathSettingsRoundTripIndependently() throws {
        for difficulty in Difficulty.allCases {
            for count in [1, 7, 20] {
                let value = ChallengeConfiguration.math(try MathConfiguration(difficulty: difficulty, requiredCorrect: count))
                try assertRoundTrip(value)
            }
        }
    }

    func testMemorySettingsRoundTripIncludingFractionalDuration() throws {
        for difficulty in Difficulty.allCases {
            for (length, seconds, rounds) in [(2, 1.0, 1), (8, 2.5, 4), (12, 30.0, 20)] {
                let value = ChallengeConfiguration.memory(try MemoryConfiguration(difficulty: difficulty,
                    sequenceLength: length, displayDuration: seconds, requiredRounds: rounds))
                try assertRoundTrip(value)
            }
        }
    }

    func testQRIdentityAndPayloadRoundTrip() throws {
        let token = SimulatorUITestFixture.qrToken
        let value = ChallengeConfiguration.qr(QRConfiguration(token: token))
        try assertRoundTrip(value)
        XCTAssertEqual(QRConfiguration(token: token).expectedPayload,
            "puzzlealarm://challenge/6a000000-0000-4000-8000-000000000003")
    }

    func testDuplicateAddsPreserveAllExistingValuesAndIdentity() throws {
        var draft = try fixture()
        let original = try draft.definition(at: date)
        for kind in ChallengeKind.allCases { draft.add(kind) }
        XCTAssertEqual(try draft.definition(at: date), original)
        var empty = AlarmDraft(); empty.mode = .challengesRequired
        for kind in ChallengeKind.allCases { empty.add(kind) }
        let first = try empty.definition(at: date)
        for kind in ChallengeKind.allCases { empty.add(kind) }
        XCTAssertEqual(try empty.definition(at: date), first)
        XCTAssertEqual(first.challengeSequence.items.map(\.kind), [.math, .memory, .qr])
    }

    func testMoveUpPreservesExactConfigurations() throws {
        var draft = try fixture()
        let before = try draft.definition(at: date).challengeSequence.items
        draft.move(2, by: -1)
        XCTAssertEqual(try draft.definition(at: date).challengeSequence.items, [before[0], before[2], before[1]])
    }

    func testMoveDownPreservesExactConfigurations() throws {
        var draft = try fixture()
        let before = try draft.definition(at: date).challengeSequence.items
        draft.move(0, by: 1)
        XCTAssertEqual(try draft.definition(at: date).challengeSequence.items, [before[1], before[0], before[2]])
    }

    func testMoveBoundariesAndInvalidIndicesDoNothing() throws {
        var draft = try fixture()
        let before = try draft.definition(at: date)
        for (index, offset) in [(0, -1), (2, 1), (-1, 1), (3, -1)] {
            draft.move(index, by: offset)
            XCTAssertEqual(try draft.definition(at: date), before)
        }
    }

    func testRemovalPreservesSurvivorsAndRejectsEmptyRequiredSequence() throws {
        for index in 0..<3 {
            var draft = try fixture()
            var expected = try draft.definition(at: date).challengeSequence.items
            expected.remove(at: index); draft.challenges.remove(at: index)
            XCTAssertEqual(try draft.definition(at: date).challengeSequence.items, expected)
        }
        var draft = try fixture(); draft.challenges.removeAll()
        XCTAssertFalse(draft.canSave)
        XCTAssertThrowsError(try draft.definition(at: date))
    }

    func testModeConversionRetainsUnsavedSequenceAndClearsSavedOrdinarySequence() throws {
        var draft = try fixture()
        let original = try draft.definition(at: date)
        draft.mode = .annoyingOnly
        let ordinary = try draft.definition(at: date)
        XCTAssertTrue(ordinary.challengeSequence.items.isEmpty)
        draft.mode = .challengesRequired
        XCTAssertEqual(try draft.definition(at: date), original)
        var reopened = AlarmDraft(ordinary)
        reopened.mode = .challengesRequired
        XCTAssertFalse(reopened.canSave)
        XCTAssertThrowsError(try reopened.definition(at: date))
        reopened.add(.math)
        XCTAssertTrue(reopened.canSave)
        XCTAssertEqual(try reopened.definition(at: date).challengeSequence.items,
            [.math(try MathConfiguration())])
        XCTAssertEqual(reopened.id, original.id)
    }

    private var date: Date { Date(timeIntervalSince1970: 1_800_000_000) }
    private func fixture() throws -> AlarmDraft {
        AlarmDraft(try XCTUnwrap(SimulatorUITestFixture.state("challenge").definitions.first))
    }
    private func assertRoundTrip(_ configuration: ChallengeConfiguration) throws {
        let fixture = try XCTUnwrap(SimulatorUITestFixture.state("challenge").definitions.first)
        let expected = try fixture.replacing(time: fixture.time, weekdays: fixture.weekdays,
            enabled: fixture.enabled, mode: fixture.dismissalMode,
            challenges: ChallengeSequence([configuration]), sound: fixture.selectedSound, at: date)
        let draft = AlarmDraft(expected)
        XCTAssertEqual(draft.challenges.map(\.id), [configuration.kind])
        XCTAssertEqual(try draft.challenges[0].configuration(), configuration)
        XCTAssertEqual(try draft.definition(at: date), expected)
        XCTAssertEqual(try AlarmDraft(draft.definition(at: date)).definition(at: date), expected)
    }
}
#endif
