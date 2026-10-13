import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor final class MemoryStoreTests: XCTestCase {
    private func seed(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler,
                      count: Int = 2) async throws -> ChallengeIdentity {
        let now = UITestEnvironment.now
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence([.memory(try MemoryConfiguration(sequenceLength: 4, requiredRounds: count))])
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
        return ChallengeIdentity(sessionID: session.id, index: 0, kind: .memory)
    }
    private func store(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler) -> AlarmStore {
        let date = UITestEnvironment.now
        return AlarmStore(repository: repository, scheduler: effects, clock: { date },
            makeMemoryRound: { _ in try MemoryRound(id: UUID(), digits: [0, 1, 2, 3]) },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }
    private func engine(_ store: AlarmStore, _ identity: ChallengeIdentity) throws -> MemoryEngine {
        try MemoryEngine(restoring: XCTUnwrap(store.session(identity.sessionID)))
    }
    func testFailedWritesSafeResumeFreshWrongRoundDuplicatesAndCleanup() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects)
        let store = store(repository, effects)
        await store.refresh()
        await repository.failNext(.write); await store.prepareMemory(identity)
        XCTAssertNotNil(store.errorMessage); XCTAssertNil(store.session(identity.sessionID)?.checkpoint)
        await store.prepareMemory(identity)
        let first = try XCTUnwrap(engine(store, identity).round)
        await store.prepareMemory(identity)
        XCTAssertEqual(try engine(store, identity).round, first)
        await repository.failNext(.write)
        let failedHide = await store.hideMemory(identity)
        XCTAssertFalse(failedHide)
        let hidden = await store.hideMemory(identity)
        XCTAssertTrue(hidden); XCTAssertNil(try engine(store, identity).visibleDigits(at: UITestEnvironment.now))
        let wrong = await store.submitMemory("9999", roundID: first.id, identity: identity)
        XCTAssertEqual(wrong, .wrong)
        let second = try XCTUnwrap(engine(store, identity).round)
        XCTAssertEqual(second.digits, [1, 1, 2, 3]); XCTAssertNotEqual(second.id, first.id)
        let staleHide = await store.hideMemory(identity, roundID: first.id)
        XCTAssertTrue(staleHide); XCTAssertEqual(try engine(store, identity).phase, .visible)
        _ = await store.hideMemory(identity)
        await repository.failNext(.write)
        let failed = await store.submitMemory("1123", roundID: second.id, identity: identity)
        XCTAssertNil(failed); XCTAssertEqual(try engine(store, identity).successfulRounds, 0)
        let correct = await store.submitMemory("1123", roundID: second.id, identity: identity)
        XCTAssertEqual(correct, .correct)
        let restored = self.store(repository, effects); await restored.refresh()
        _ = await restored.hideMemory(identity)
        XCTAssertEqual(try engine(restored, identity).successfulRounds, 1)
        XCTAssertNil(try engine(restored, identity).visibleDigits(at: UITestEnvironment.now))
        let duplicate = await restored.submitMemory("1123", roundID: second.id, identity: identity)
        XCTAssertEqual(duplicate, .stale)
        let third = try XCTUnwrap(engine(restored, identity).round)
        effects.configure { $0.failCancellation = true }
        let completion = await restored.submitMemory("0123", roundID: third.id, identity: identity)
        XCTAssertEqual(completion, .completed)
        XCTAssertEqual(restored.session(identity.sessionID)?.session.phase, .cancellationPartiallyFailed)
        effects.configure { $0.failCancellation = false }; await restored.refresh()
        XCTAssertEqual(restored.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertTrue(effects.values.alarms.isEmpty && effects.values.schedules.isEmpty)
    }
    func testProductionFactoryRevokedAccessAndDurableSuccess() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects, count: 1)
        effects.configure { $0.authorization = .denied }
        let date = UITestEnvironment.now
        let store = AlarmStore(repository: repository, scheduler: effects, clock: { date },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        await store.refresh(); await store.prepareMemory(identity)
        let round = try XCTUnwrap(engine(store, identity).round)
        XCTAssertEqual(round.digits.count, 4)
        let early = await store.submitMemory("0000", roundID: round.id, identity: identity)
        XCTAssertEqual(early, .notHidden)
        _ = await store.hideMemory(identity)
        let invalid = await store.submitMemory("abc", roundID: round.id, identity: identity)
        XCTAssertEqual(invalid, .invalid)
        let result = await store.submitMemory(round.digits.map(String.init).joined(), roundID: round.id, identity: identity)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(store.session(identity.sessionID)?.session.phase, .completing)
        XCTAssertFalse(store.confirmed)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        XCTAssertEqual(effects.values.authorizationRequests, 0)
        effects.configure { $0.authorization = .authorized }; await store.refresh()
        XCTAssertEqual(store.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertEqual(effects.values.cancellations.count, 5)
    }
    func testCompetingSafeResumesWaitForBusyOwnerAndCoalescedForegroundRefresh() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects)
        let store = store(repository, effects)
        await store.refresh(); await store.prepareMemory(identity)
        let pause = MemoryStorePause()
        effects.configure { $0.afterSchedule = { await pause.wait() } }
        let date = UITestEnvironment.now
        let draft = try AlarmEditorDraft(id: UUID(), now: date)
        let save = Task { await store.save(draft) }
        await pause.started()
        XCTAssertTrue(store.isBusy)
        var started = 0
        let hides = (0..<4).map { _ in
            Task { started += 1; return await store.hideMemory(identity) }
        }
        while started < 4 { await Task.yield() }
        await store.refresh() // Queue the same coalesced foreground refresh as production.
        await pause.release()
        _ = await save.value
        for hide in hides { let hidden = await hide.value; XCTAssertTrue(hidden) }
        XCTAssertFalse(store.isBusy)
        XCTAssertEqual(try engine(store, identity).phase, .hidden)
        XCTAssertNil(try engine(store, identity).visibleDigits(at: date))
        XCTAssertEqual(try engine(store, identity).successfulRounds, 0)
    }
}

private actor MemoryStorePause {
    private var continuation: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?
    private var entered = false
    func wait() async {
        entered = true; observer?.resume(); observer = nil
        await withCheckedContinuation { continuation = $0 }
    }
    func started() async {
        if entered { return }
        await withCheckedContinuation { observer = $0 }
    }
    func release() { continuation?.resume(); continuation = nil }
}
