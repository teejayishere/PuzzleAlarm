import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

/// Gate 13 crosses the application owner, real reducers and disk persistence.
/// The scheduler records effects only; no fake implements lifecycle decisions.
@MainActor final class OrchestrationIntegrationTests: XCTestCase {
    private var directory: URL!
    private var repository: CompletionFaultRepository!
    private var effects: OrchestrationEffects!
    private var clock: OrchestrationClock!
    private var store: AlarmStore!
    private let qr = QRConfiguration(token: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!)

    private func prepareScenario() {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        repository = CompletionFaultRepository(directory: directory)
        effects = OrchestrationEffects()
        clock = OrchestrationClock(Date(timeIntervalSince1970: 1_790_812_800))
        store = makeStore()
        let output = directory!
        addTeardownBlock { try FileManager.default.removeItem(at: output) }
    }

    private func makeStore() -> AlarmStore {
        AlarmStore(repository: repository, scheduler: effects, clock: clock.now,
            makeMathProblem: { _ in try MathProblem(id: UUID(), prompt: "2 + 3", expectedAnswer: 5) },
            makeMemoryRound: { _ in try MemoryRound(id: UUID(), digits: [1, 2]) },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }

    private func create(order: [ChallengeKind] = [.math, .memory, .qr],
                        recurring: Bool = true) async throws -> WakeUpSession {
        var draft = try AlarmEditorDraft(id: UUID(), now: clock.now())
        draft.hour = 6; draft.minute = 30
        draft.weekdays = recurring ? Set(Weekday.allCases) : []
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence(order.map { kind in
            switch kind {
            case .math: .math(try MathConfiguration(requiredCorrect: 1))
            case .memory: .memory(try MemoryConfiguration(sequenceLength: 2, requiredRounds: 1))
            case .qr: .qr(qr)
            }
        })
        _ = await store.save(draft)
        return try XCTUnwrap(store.state?.sessions.first { $0.session.parentAlarmID == draft.id }?.session)
    }

    private func activate(_ session: WakeUpSession) async {
        clock.set(session.scheduledWakeUpDate)
        await store.refresh()
        XCTAssertEqual(store.wakeUpSessionID, session.id)
    }

    private func solveCurrent(_ id: UUID) async throws {
        let record = try XCTUnwrap(store.session(id))
        let current = try XCTUnwrap(record.session.currentChallenge)
        let identity = ChallengeIdentity(sessionID: id, index: record.session.currentChallengeIndex, kind: current.kind)
        switch current {
        case .math:
            await store.prepareMath(identity)
            let saved = try XCTUnwrap(store.session(id))
            let problem = try XCTUnwrap(MathEngine(restoring: saved).problem)
            let result = await store.submitMath("5", problemID: problem.id, identity: identity)
            XCTAssertEqual(result, .completed)
        case .memory:
            await store.prepareMemory(identity)
            let saved = try XCTUnwrap(store.session(id))
            let round = try XCTUnwrap(MemoryEngine(restoring: saved).round)
            let hidden = await store.hideMemory(identity, roundID: round.id)
            XCTAssertTrue(hidden)
            let result = await store.submitMemory("12", roundID: round.id, identity: identity)
            XCTAssertEqual(result, .completed)
        case let .qr(configuration):
            let result = await store.submitQR(configuration.expectedPayload, identity: identity)
            XCTAssertEqual(result, .completed)
        }
    }

    private func durable() async throws -> RepositoryState {
        guard case let .loaded(snapshot, _) = try await DiskRepository(directory: directory).load() else {
            throw PersistenceError.io("Missing integration state")
        }
        return snapshot.state
    }

    private func assertDurableState(file: StaticString = #filePath, line: UInt = #line) async throws {
        let persisted = try await durable()
        XCTAssertEqual(persisted, store.state, file: file, line: line)
    }

    func testAAllFiveScheduleWithOneImmutableOccurrence() async throws {
        prepareScenario()
        let session = try await create()
        XCTAssertEqual(session.phase, .armed)
        XCTAssertEqual(effects.values.schedules.map(\.plannedAlarm), session.plan.alarms)
        XCTAssertEqual(effects.values.schedules.map(\.sessionID), Array(repeating: session.id, count: 5))
        XCTAssertEqual(Set(effects.values.alarms.map(\.id)), Set(session.plan.alarms.map(\.id)))
        try await assertDurableState()
        await store.refresh()
        XCTAssertEqual(effects.values.schedules.count, 5)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
    }

    func testBPartialFailureRollsBackIncludingUncertainOSSuccess() async throws {
        prepareScenario()
        effects.configure { $0.failSchedule = 3; $0.scheduleFailsAfterEffect = true }
        let session = try await create()
        XCTAssertEqual(session.phase, .cancelled)
        XCTAssertNil(session.completedAt)
        XCTAssertTrue(session.challengeCompletedAt.isEmpty)
        XCTAssertEqual(effects.values.schedules.count, 3)
        XCTAssertEqual(effects.values.cancellations, Array(session.plan.alarms.prefix(3)).map(\.id))
        XCTAssertTrue(effects.values.alarms.isEmpty)
        XCTAssertEqual(store.state?.operations.first?.failure, .scheduling)
        XCTAssertEqual(store.status(try XCTUnwrap(store.alarms.first)), "Needs attention")
        await store.refresh()
        XCTAssertEqual(effects.values.schedules.count, 3, "Recovery must not automatically retry a failed generation")
        try await assertDurableState()
    }

    func testCStoppedPrimaryDoesNotCompleteOrCancelBackups() async throws {
        prepareScenario()
        let session = try await create()
        effects.configure { $0.alarms.removeAll { $0.id == session.primaryAlarmID } }
        await activate(session)
        XCTAssertEqual(store.session(session.id)?.session.phase, .active)
        XCTAssertEqual(store.session(session.id)?.session.currentChallengeIndex, 0)
        XCTAssertNil(store.session(session.id)?.session.completedAt)
        XCTAssertEqual(Set(effects.values.alarms.map(\.id)), Set(session.backupAlarmIDs))
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        XCTAssertEqual(effects.values.schedules.count, 5)
        XCTAssertTrue(store.issues.contains(.activeAlarmMissing(session.primaryAlarmID)))
    }

    func testDFirstChallengeLeavesBackupsAndRejectsStaleCallback() async throws {
        prepareScenario()
        let session = try await create(order: [.qr, .math, .memory])
        await activate(session)
        let revision = store.routeRevision
        try await solveCurrent(session.id)
        XCTAssertEqual(store.session(session.id)?.session.currentChallengeIndex, 1)
        XCTAssertEqual(store.session(session.id)?.session.currentChallenge?.kind, .math)
        XCTAssertEqual(store.routeRevision, revision, "Intermediate success must not invoke lifecycle reconciliation")
        let duplicate = await store.submitQR(qr.expectedPayload,
            identity: ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr))
        XCTAssertEqual(duplicate, .stale)
        XCTAssertEqual(effects.values.alarms.count, 5)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        // A new owner reconstructs the current challenge from disk, never a UI success flag.
        repository = CompletionFaultRepository(directory: directory); store = makeStore()
        await store.refresh()
        XCTAssertEqual(store.wakeUpSessionID, session.id)
        XCTAssertEqual(store.session(session.id)?.session.currentChallengeIndex, 1)
        XCTAssertEqual(store.session(session.id)?.session.phase, .active)
    }

    func testEAllFinalEngineKindsCleanAndCreateExactlyOneSuccessor() async throws {
        prepareScenario()
        // Each engine is the final engine in one real three-challenge sequence.
        let orders: [[ChallengeKind]] = [[.math, .memory, .qr], [.qr, .math, .memory], [.memory, .qr, .math]]
        for order in orders {
            let session = try await create(order: order)
            await activate(session)
            for index in 0..<3 {
                XCTAssertEqual(store.session(session.id)?.session.currentChallengeIndex, index)
                try await solveCurrent(session.id)
                if index < 2 { XCTAssertFalse(effects.values.cancellations.contains(session.primaryAlarmID)) }
            }
            let completed = try XCTUnwrap(store.session(session.id)?.session)
            XCTAssertEqual(completed.phase, .completed)
            XCTAssertEqual(completed.challengeCompletedAt.count, 3)
            XCTAssertNotNil(completed.completedAt)
            XCTAssertEqual(completed.definitionSnapshot, session.definitionSnapshot)
            XCTAssertEqual(effects.values.cancellations.filter { session.plan.alarms.map(\.id).contains($0) }, session.plan.alarms.map(\.id))
            let successors = try XCTUnwrap(store.state).sessions.filter {
                $0.session.parentAlarmID == session.parentAlarmID && $0.session.id != session.id
            }
            XCTAssertEqual(successors.count, 1)
            XCTAssertEqual(successors.first?.session.phase, .armed)
            XCTAssertGreaterThan(try XCTUnwrap(successors.first?.session.scheduledWakeUpDate), clock.now())
            let calls = effects.values.schedules.count
            await store.refresh()
            XCTAssertEqual(effects.values.schedules.count, calls)
            try await assertDurableState()
            // Retire this parent's future chain before testing another order.
            await store.setEnabled(try XCTUnwrap(store.definition(session.parentAlarmID)), false)
        }
    }

    func testFCancellationFailureContinuesAndDefersSuccessorUntilCleanup() async throws {
        prepareScenario()
        let session = try await create(order: [.qr])
        await activate(session)
        let failedID = session.plan.alarms[1].id
        effects.configure { $0.failCancellation = [failedID] }
        try await solveCurrent(session.id)
        XCTAssertEqual(effects.values.cancellations, session.plan.alarms.map(\.id))
        XCTAssertEqual(store.session(session.id)?.session.phase, .cancellationPartiallyFailed)
        XCTAssertNil(store.session(session.id)?.session.completedAt)
        XCTAssertEqual(effects.values.alarms.map(\.id), [failedID])
        XCTAssertEqual(store.state?.sessions.count, 1)
        XCTAssertEqual(effects.values.schedules.count, 5)
        let duplicate = await store.submitQR(qr.expectedPayload,
            identity: ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr))
        XCTAssertEqual(duplicate, .stale)
        XCTAssertEqual(effects.values.cancellations.count, 5)
        effects.configure { $0.failCancellation = [] }
        await store.refresh() // Product cleanup retry, not a test rerun.
        XCTAssertEqual(store.session(session.id)?.session.phase, .completed)
        XCTAssertEqual(effects.values.cancellations, session.plan.alarms.map(\.id) + [failedID])
        XCTAssertEqual(store.state?.sessions.count, 2)
        XCTAssertEqual(effects.values.schedules.count, 10)
    }

    func testGCompletionAcknowledgmentLossRecoversFromDiskWithoutRepeatedCancel() async throws {
        prepareScenario()
        let session = try await create(order: [.qr])
        await activate(session)
        await repository.interruptOnce { $0.sessions.first?.session.cancellation.first == .succeeded }
        try await solveCurrent(session.id)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertEqual(store.session(session.id)?.session.phase, .completing)
        XCTAssertEqual(store.session(session.id)?.session.cancellation.first, .inFlight)
        XCTAssertEqual(effects.values.cancellations, [session.primaryAlarmID])
        XCTAssertEqual(store.state?.sessions.count, 1)
        repository = CompletionFaultRepository(directory: directory); store = makeStore()
        await store.refresh()
        XCTAssertEqual(store.session(session.id)?.session.phase, .completed)
        XCTAssertEqual(effects.values.cancellations, session.plan.alarms.map(\.id))
        XCTAssertEqual(effects.values.schedules.count, 10)
        let saved = try await durable()
        await store.refresh()
        let afterRefresh = try await durable()
        XCTAssertEqual(afterRefresh, saved)
        XCTAssertEqual(effects.values.cancellations.count, 5)
        XCTAssertEqual(effects.values.schedules.count, 10)
    }

    func testHSchedulingAcknowledgmentLossReusesDurableIdentity() async throws {
        prepareScenario()
        await repository.interruptOnce { $0.sessions.first?.session.scheduling.first == .scheduled }
        let session = try await create()
        XCTAssertNotNil(store.errorMessage)
        XCTAssertEqual(session.phase, .scheduling)
        XCTAssertEqual(session.scheduling.first, .inFlight)
        XCTAssertEqual(effects.values.schedules.count, 1)
        repository = CompletionFaultRepository(directory: directory); store = makeStore()
        await store.refresh()
        XCTAssertEqual(store.session(session.id)?.session.plan, session.plan)
        XCTAssertEqual(store.session(session.id)?.session.phase, .armed)
        XCTAssertEqual(effects.values.schedules.map(\.plannedAlarm.id), session.plan.alarms.map(\.id))
        XCTAssertEqual(store.state?.sessions.count, 1)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        try await assertDurableState()
    }

    func testIEditingActiveAlarmPreservesObligationAndReplacesOnlyFutureChain() async throws {
        prepareScenario()
        let session = try await create(order: [.qr])
        await activate(session)
        var edit = AlarmEditorDraft(try XCTUnwrap(store.definition(session.parentAlarmID)))
        edit.hour = 8; edit.sound = .siren
        _ = await store.save(edit)
        XCTAssertEqual(store.session(session.id)?.session.definitionSnapshot, session.definitionSnapshot)
        XCTAssertEqual(store.session(session.id)?.session.phase, .active)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        let future = try XCTUnwrap(store.state?.sessions.last?.session)
        XCTAssertNotEqual(future.id, session.id)
        XCTAssertEqual(future.definitionSnapshot.time.hour, 8)
        XCTAssertEqual(future.definitionSnapshot.selectedSound, .bundled(.siren))
        XCTAssertGreaterThan(future.scheduledWakeUpDate, clock.now())
        try await solveCurrent(session.id)
        XCTAssertEqual(store.session(session.id)?.session.phase, .completed)
        XCTAssertEqual(store.state?.sessions.count, 2, "Completion must not create a second edited successor")
        XCTAssertEqual(Set(effects.values.alarms.map(\.id)), Set(future.plan.alarms.map(\.id)))
        XCTAssertEqual(effects.values.schedules.count, 10)
        try await assertDurableState()
    }

    func testJDisablePreservesActiveChallengeButPreventsNextOccurrence() async throws {
        prepareScenario()
        let session = try await create(order: [.qr])
        await activate(session)
        await store.setEnabled(try XCTUnwrap(store.definition(session.parentAlarmID)), false)
        XCTAssertFalse(try XCTUnwrap(store.definition(session.parentAlarmID)).enabled)
        XCTAssertEqual(store.wakeUpSessionID, session.id)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        try await solveCurrent(session.id)
        XCTAssertEqual(store.session(session.id)?.session.phase, .completed)
        XCTAssertEqual(store.state?.sessions.count, 1)
        XCTAssertTrue(effects.values.alarms.isEmpty)
        clock.set(clock.now().addingTimeInterval(86_400))
        repository = CompletionFaultRepository(directory: directory); store = makeStore()
        await store.refresh()
        XCTAssertNil(store.wakeUpSessionID)
        XCTAssertEqual(effects.values.schedules.count, 5)
        XCTAssertEqual(store.status(try XCTUnwrap(store.alarms.first)), "Off")
        try await assertDurableState()
    }
}

private final class OrchestrationClock: @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date
    init(_ date: Date) { self.date = date }
    func now() -> Date { lock.withLock { date } }
    func set(_ date: Date) { lock.withLock { self.date = date } }
}

/// Reject an acknowledgment before committing it, after the real owner has made
/// its effect. Reopening uses a fresh repository and only the surviving disk bytes.
private actor CompletionFaultRepository: PuzzleAlarmRepository {
    let disk: DiskRepository
    private var interruption: (@Sendable (RepositoryState) -> Bool)?
    init(directory: URL) { disk = DiskRepository(directory: directory) }
    func interruptOnce(_ predicate: @escaping @Sendable (RepositoryState) -> Bool) { interruption = predicate }
    func load() async throws -> RepositoryRead { try await disk.load() }
    func commit(_ state: RepositoryState, expecting version: RepositoryVersion) async throws -> RepositorySnapshot {
        if interruption?(state) == true {
            interruption = nil
            throw PersistenceError.io("Injected interruption before acknowledgment")
        }
        return try await disk.commit(state, expecting: version)
    }
}

private final class OrchestrationEffects: AlarmScheduling, @unchecked Sendable {
    struct Storage {
        var alarms: [RegisteredAlarm] = []
        var schedules: [AlarmRequest] = []
        var cancellations: [UUID] = []
        var failSchedule: Int?
        var scheduleFailsAfterEffect = false
        var failCancellation: Set<UUID> = []
    }
    private let lock = NSLock()
    private var storage = Storage()
    var authorization: AlarmAuthorization { .authorized }
    func requestAuthorization() async throws -> AlarmAuthorization { .authorized }
    func configure(_ body: (inout Storage) -> Void) { lock.withLock { body(&storage) } }
    var values: Storage { lock.withLock { storage } }
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        try lock.withLock {
            storage.schedules.append(request)
            let fail = storage.schedules.count == storage.failSchedule
            let alarm = RegisteredAlarm(id: request.plannedAlarm.id, state: .scheduled)
            if !fail || storage.scheduleFailsAfterEffect { storage.alarms.append(alarm) }
            if fail { throw PersistenceError.io("Injected scheduling failure") }
            return alarm
        }
    }
    func cancel(id: UUID) throws {
        try lock.withLock {
            storage.cancellations.append(id)
            if storage.failCancellation.contains(id) { throw PersistenceError.io("Injected cancellation failure") }
            storage.alarms.removeAll { $0.id == id }
        }
    }
    func currentAlarms() throws -> [RegisteredAlarm] { values.alarms }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async { receive(values.alarms) }
}
