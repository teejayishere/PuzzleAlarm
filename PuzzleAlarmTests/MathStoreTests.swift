import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor
final class MathStoreTests: XCTestCase {
    private func seed(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler,
                      count: Int = 2) async throws -> ChallengeIdentity {
        let now = UITestEnvironment.now
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence([.math(try MathConfiguration(requiredCorrect: count))])
        let definition = try draft.definition(at: now)
        let ids = (0..<5).map { _ in UUID() }
        var session = try WakeUpSession(id: UUID(), definition: definition,
            context: ScheduleContext(timeZoneIdentifier: "UTC"), plan: BackupPlan(at: now, ids: ids), createdAt: now)
        try session.beginScheduling()
        for id in ids { try session.beginScheduleAttempt(id: id); try session.recordScheduled(id: id) }
        try session.arm(); try session.activate(at: now)
        _ = try await repository.commit(RepositoryState(definitions: [definition],
            sessions: [PersistedSession(session: session, updatedAt: now)]), expecting: .missing)
        effects.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
        return ChallengeIdentity(sessionID: session.id, index: 0, kind: .math)
    }
    private func store(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler) -> AlarmStore {
        let date = UITestEnvironment.now
        return AlarmStore(repository: repository, scheduler: effects, clock: { date },
            makeMathProblem: { _ in try MathProblem(id: UUID(), prompt: "2 + 3", expectedAnswer: 5) },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }
    func testProductionGeneratorAndRevokedAccessDoNotClaimExternalConfirmation() async throws {
        let repository = InMemoryRepository()
        let effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects, count: 1)
        effects.configure { $0.authorization = .denied }
        let date = UITestEnvironment.now
        let store = AlarmStore(repository: repository, scheduler: effects, clock: { date },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        await store.refresh()
        XCTAssertFalse(store.confirmed)
        await store.prepareMath(identity)
        let engine = try MathEngine(restoring: XCTUnwrap(store.session(identity.sessionID)))
        let problem = try XCTUnwrap(engine.problem)
        XCTAssertFalse(problem.prompt.isEmpty)
        XCTAssertFalse(store.confirmed)
        let invalid = await store.submitMath("1.5", problemID: problem.id, identity: identity)
        XCTAssertEqual(invalid, .invalid)
        let result = await store.submitMath(String(problem.expectedAnswer), problemID: problem.id, identity: identity)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(store.session(identity.sessionID)?.session.phase, .completing)
        XCTAssertFalse(store.confirmed)
        XCTAssertTrue(effects.values.cancellations.isEmpty && effects.values.schedules.isEmpty)
        XCTAssertEqual(effects.values.authorizationRequests, 0)
        effects.configure { $0.authorization = .authorized }
        await store.refresh()
        XCTAssertEqual(store.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertEqual(effects.values.cancellations.count, 5)
    }
    func testPrepareFailedWriteRetryRestorationDuplicatesAndCleanup() async throws {
        let repository = InMemoryRepository()
        let effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects)
        let store = store(repository, effects)
        await store.refresh()
        await repository.failNext(.write)
        await store.prepareMath(identity)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertNil(store.session(identity.sessionID)?.checkpoint)
        await store.prepareMath(identity)
        let first = try XCTUnwrap(MathEngine(restoring: XCTUnwrap(store.session(identity.sessionID))).problem)
        await store.prepareMath(identity)
        XCTAssertEqual(try MathEngine(restoring: XCTUnwrap(store.session(identity.sessionID))).problem, first)
        await repository.failNext(.write)
        let failed = await store.submitMath("5", problemID: first.id, identity: identity)
        XCTAssertNil(failed)
        XCTAssertEqual(try MathEngine(restoring: XCTUnwrap(store.session(identity.sessionID))).correctAnswers, 0)
        let wrong = await store.submitMath("9", problemID: first.id, identity: identity)
        XCTAssertEqual(wrong, .wrong)
        let correct = await store.submitMath("5", problemID: first.id, identity: identity)
        XCTAssertEqual(correct, .correct)
        let restoredStore = self.store(repository, effects)
        await restoredStore.refresh()
        let restored = try MathEngine(restoring: XCTUnwrap(restoredStore.session(identity.sessionID)))
        XCTAssertEqual(restored.correctAnswers, 1)
        let second = try XCTUnwrap(restored.problem)
        XCTAssertNotEqual(second.id, first.id)
        let duplicate = await restoredStore.submitMath("5", problemID: first.id, identity: identity)
        XCTAssertEqual(duplicate, .stale)
        effects.configure { $0.failCancellation = true }
        let completion = await restoredStore.submitMath("5", problemID: second.id, identity: identity)
        XCTAssertEqual(completion, .completed)
        XCTAssertEqual(restoredStore.session(identity.sessionID)?.session.phase, .cancellationPartiallyFailed)
        XCTAssertEqual(effects.values.cancellations.count, 5)
        effects.configure { $0.failCancellation = false }
        await restoredStore.refresh()
        XCTAssertEqual(restoredStore.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertTrue(effects.values.alarms.isEmpty)
        XCTAssertTrue(effects.values.schedules.isEmpty)
    }
}
