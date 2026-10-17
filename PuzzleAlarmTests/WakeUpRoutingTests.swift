import AppIntents
import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor
final class WakeUpRoutingTests: XCTestCase {
    private let now = UITestEnvironment.now

    private func seed(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler,
                      due: Bool = true, active: Bool = false) async throws -> UUID {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence([.math(try MathConfiguration(requiredCorrect: 1))])
        let definition = try draft.definition(at: now)
        let ids = (0..<5).map { _ in UUID() }
        var value = try WakeUpSession(id: UUID(), definition: definition,
            context: ScheduleContext(timeZoneIdentifier: "UTC"),
            plan: BackupPlan(at: due ? now : now.addingTimeInterval(60), ids: ids), createdAt: now)
        try value.beginScheduling()
        for id in ids { try value.beginScheduleAttempt(id: id); try value.recordScheduled(id: id) }
        try value.arm()
        if active { try value.activate(at: now) }
        _ = try await repository.commit(RepositoryState(definitions: [definition],
            sessions: [PersistedSession(session: value, updatedAt: now)]), expecting: .missing)
        effects.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
        return value.id
    }
    private func store(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler) -> AlarmStore {
        let date = now
        return AlarmStore(repository: repository, scheduler: effects, clock: { date },
            makeMathProblem: { _ in try MathProblem(id: UUID(), prompt: "2 + 3", expectedAnswer: 5) },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }
    func testColdIntentUsesSameOwnerActivatesDueAndDuplicateStaleEventsPreserveProgress() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let id = try await seed(repository, effects)
        let store = store(repository, effects), environment = AppEnvironment(store: nil)
        await environment.start()
        let live = AppEnvironment(store: store)
        let intent = OpenOccurrenceIntent(occurrenceID: id)
        await intent.route(to: live)
        XCTAssertTrue(live.ready)
        XCTAssertTrue(live.store === store)
        XCTAssertEqual(store.wakeUpSessionID, id)
        XCTAssertEqual(store.session(id)?.session.phase, .active)
        let identity = ChallengeIdentity(sessionID: id, index: 0, kind: .math)
        await store.prepareMath(identity)
        let saved = try XCTUnwrap(store.session(id))
        async let duplicate: Void = intent.route(to: live)
        async let stale: Void = OpenOccurrenceIntent(occurrenceID: UUID()).route(to: live)
        async let foreground: Void = live.foreground()
        _ = await (duplicate, stale, foreground)
        XCTAssertEqual(store.session(id), saved)
        XCTAssertEqual(store.wakeUpSessionID, id)
        XCTAssertTrue(effects.values.cancellations.isEmpty && effects.values.schedules.isEmpty)
        XCTAssertEqual(effects.values.authorizationRequests, 0)
    }
    func testInterruptedCancellationRecoversAndCompletedIntentCannotReopenOrReschedule() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let id = try await seed(repository, effects, active: true)
        let store = store(repository, effects)
        await store.refresh()
        let identity = ChallengeIdentity(sessionID: id, index: 0, kind: .math)
        await store.prepareMath(identity)
        let problem = try XCTUnwrap(MathEngine(restoring: XCTUnwrap(store.session(id))).problem)
        effects.configure { $0.failCancellation = true }
        let result = await store.submitMath("5", problemID: problem.id, identity: identity)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(store.session(id)?.session.phase, .cancellationPartiallyFailed)
        XCTAssertNil(store.wakeUpSessionID)
        effects.configure { $0.failCancellation = false }
        // Recreate process-local presentation/owner from the same durable state.
        let restored = self.store(repository, effects)
        let environment = AppEnvironment(store: restored)
        let intent = OpenOccurrenceIntent(occurrenceID: id)
        await intent.route(to: environment)
        XCTAssertEqual(restored.session(id)?.session.phase, .completed)
        XCTAssertNil(restored.wakeUpSessionID)
        let cancellations = effects.values.cancellations
        let saved = restored.session(id)
        await intent.route(to: environment)
        await environment.foreground()
        XCTAssertEqual(restored.session(id), saved)
        XCTAssertEqual(effects.values.cancellations, cancellations)
        XCTAssertTrue(effects.values.schedules.isEmpty)
    }
    func testNoSessionFutureSessionMalformedIntentAndDeniedAccess() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let store = store(repository, effects), environment = AppEnvironment(store: nil)
        await environment.foreground()
        let live = AppEnvironment(store: store)
        let invalid = OpenOccurrenceIntent()
        invalid.occurrenceID = "invalid"
        await invalid.route(to: live)
        XCTAssertFalse(live.ready)
        await OpenOccurrenceIntent(occurrenceID: UUID()).route(to: live)
        XCTAssertTrue(live.ready)
        XCTAssertNil(store.wakeUpSessionID)
        let futureRepository = InMemoryRepository()
        let id = try await seed(futureRepository, effects, due: false)
        let future = self.store(futureRepository, effects)
        await OpenOccurrenceIntent(occurrenceID: id).route(to: AppEnvironment(store: future))
        XCTAssertNil(future.wakeUpSessionID)
        XCTAssertEqual(future.session(id)?.session.phase, .armed)
        let deniedRepository = InMemoryRepository()
        let active = try await seed(deniedRepository, effects, active: true)
        effects.configure { $0.authorization = .denied }
        let denied = self.store(deniedRepository, effects)
        await OpenOccurrenceIntent(occurrenceID: active).route(to: AppEnvironment(store: denied))
        XCTAssertEqual(denied.wakeUpSessionID, active)
        XCTAssertFalse(denied.confirmed)
        XCTAssertEqual(effects.values.authorizationRequests, 0)
    }
    func testConcurrentStartupWaitsForPreparationAndFailureDoesNotExposeNormalUI() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let id = try await seed(repository, effects)
        let store = store(repository, effects)
        var preparations = 0
        let environment = AppEnvironment(store: store) {
            preparations += 1
            await Task.yield()
        }
        async let start: Void = environment.start()
        async let event: Void = OpenOccurrenceIntent(occurrenceID: id).route(to: environment)
        _ = await (start, event)
        XCTAssertEqual(preparations, 1)
        XCTAssertTrue(environment.ready)
        XCTAssertEqual(store.wakeUpSessionID, id)
        let failed = AppEnvironment(store: store) { throw TestAlarmScheduler.TestEffectError.failed }
        await failed.start()
        XCTAssertFalse(failed.ready)
        XCTAssertNotNil(failed.failure)
    }
    func testRealIntentPerformUsesApplicationEnvironment() async throws {
        _ = try await OpenOccurrenceIntent(occurrenceID: UUID()).perform()
        XCTAssertTrue(AppEnvironment.live.ready)
    }
    func testFailedRefreshRetainsDueObligationAndRetryUsesSameSession() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let id = try await seed(repository, effects, active: true)
        let store = store(repository, effects)
        let environment = AppEnvironment(store: store)
        await environment.start()
        let saved = store.session(id)
        let revision = store.routeRevision
        effects.configure { $0.failSnapshot = true }
        await OpenOccurrenceIntent(occurrenceID: id).route(to: environment)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertFalse(store.confirmed)
        XCTAssertEqual(store.session(id), saved)
        XCTAssertEqual(store.wakeUpSessionID, id)
        XCTAssertGreaterThan(store.routeRevision, revision)
        effects.configure { $0.failSnapshot = false }
        await environment.foreground()
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(store.wakeUpSessionID, id)
        XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.cancellations.isEmpty)
    }
    func testIntentDuringSuspendedOwnerCommandIsCoalescedAndRoutedAfterCommit() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let id = try await seed(repository, effects, active: true)
        let store = store(repository, effects), environment = AppEnvironment(store: nil)
        await environment.start()
        let live = AppEnvironment(store: store)
        await live.start()
        let revision = store.routeRevision
        let pause = RoutingPause()
        effects.configure { $0.afterSchedule = { await pause.wait() } }
        var draft = try store.newDraft()
        // A separate ordinary alarm command suspends inside the same owner.
        try draft.setMode(.annoyingOnly)
        let command = Task { await store.save(draft) }
        await pause.started()
        await OpenOccurrenceIntent(occurrenceID: id).route(to: live)
        await live.foreground()
        XCTAssertTrue(store.isBusy)
        XCTAssertEqual(store.routeRevision, revision)
        await pause.release()
        _ = await command.value
        XCTAssertFalse(store.isBusy)
        XCTAssertEqual(store.routeRevision, revision + 1)
        XCTAssertEqual(store.wakeUpSessionID, id)
        XCTAssertEqual(store.session(id)?.session.phase, .active)
        XCTAssertEqual(effects.values.schedules.count, 1)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
    }
}

private actor RoutingPause {
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
