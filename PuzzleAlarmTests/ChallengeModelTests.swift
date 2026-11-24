#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class ChallengeModelTests: XCTestCase, @unchecked Sendable {
    @MainActor
    func testRunNowPersistsAllThreeChallengesRestoresAndCancelsOnlyAfterFullSequence() async throws {
        let pendingKey = "PuzzleAlarm.pendingOccurrenceID"
        UserDefaults.standard.removeObject(forKey: pendingKey)
        defer { UserDefaults.standard.removeObject(forKey: pendingKey) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let clock = try SimulatorClock(directory: directory)
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler,
            clock: { clock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let qr = QRConfiguration(token: UUID())
        let definition = try makeDefinition([
            .math(try MathConfiguration(requiredCorrect: 2)),
            .memory(try MemoryConfiguration(displayDuration: 1, requiredRounds: 1)), .qr(qr)
        ], now: clock.now())
        _ = try await service.perform(.create(definition))
        let armed = try await record(in: repository, parentID: definition.id)
        let originalIDs = Set(armed.session.plan.alarms.map(\.id))
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
        let model = ChallengeModel(repository: repository, service: service,
            clock: { clock.now() }, advancePreviewClock: { try clock.advance(to: $0) })
        await model.runNow(alarmID: definition.id)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.current?.sessionID, armed.session.id)
        XCTAssertEqual(model.current?.phase, .active)
        let first = try await record(in: repository, parentID: definition.id)
        guard case let .math(firstID, _, firstAnswer)? = first.checkpoint?.detail else {
            return XCTFail("Run Now did not persist the generated math problem")
        }
        await model.submit(.submitMath(problemID: firstID, answer: String(firstAnswer)))
        let partial = try await record(in: repository, parentID: definition.id)
        XCTAssertEqual(partial.session.progress, .math(correctAnswers: 1))
        XCTAssertEqual(partial.session.currentChallengeIndex, 0)
        await model.submit(.submitMath(problemID: firstID, answer: String(firstAnswer)))
        let replayed = try await record(in: repository, parentID: definition.id)
        XCTAssertEqual(replayed, partial)
        XCTAssertNil(model.errorMessage)
        guard case let .math(secondID, _, secondAnswer)? = partial.checkpoint?.detail else {
            return XCTFail("Next math problem was not persisted")
        }
        await model.submit(.submitMath(problemID: secondID, answer: String(secondAnswer)))
        let afterMath = try await record(in: repository, parentID: definition.id)
        XCTAssertEqual(afterMath.session.currentChallengeIndex, 1)
        XCTAssertEqual(afterMath.session.phase, .active)
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
        XCTAssertTrue(afterMath.session.cancellation.allSatisfy { $0 == .notRequested })

        // Reopen the disk repository and model before the sequence is finished.
        let reopened = DiskRepository(directory: directory)
        let restoredClock = try SimulatorClock(directory: directory)
        let restoredService = LifecycleAlarmManagementService(repository: reopened, scheduler: scheduler,
            clock: { restoredClock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let restored = ChallengeModel(repository: reopened, service: restoredService,
            clock: { restoredClock.now() }, advancePreviewClock: { try restoredClock.advance(to: $0) })
        await restored.refresh()
        XCTAssertNil(restored.errorMessage)
        XCTAssertEqual(restored.current?.sessionID, armed.session.id)
        XCTAssertEqual(restored.current?.challengeIndex, 1)
        let memory = try await record(in: reopened, parentID: definition.id)
        XCTAssertEqual(memory.checkpoint, afterMath.checkpoint)
        guard case let .memory(roundID, digits, _, deadline)? = memory.checkpoint?.detail else {
            return XCTFail("Restored model did not preserve the memory round")
        }
        try restoredClock.advance(to: XCTUnwrap(deadline))
        await restored.tick()
        guard case let .memory(_, shownDigits, phase, _, _, _)? = restored.current?.content else {
            return XCTFail("Missing hidden memory presentation")
        }
        XCTAssertNil(shownDigits)
        XCTAssertEqual(phase, .hidden)
        await restored.submit(.submitMemory(roundID: roundID, answer: digits.map(String.init).joined()))
        XCTAssertEqual(restored.current?.challengeIndex, 2)
        XCTAssertEqual(restored.current?.content, .qr)
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
        await restored.submit(.scanQR(payload: QRConfiguration(token: UUID()).expectedPayload))
        XCTAssertEqual(restored.current?.challengeIndex, 2)
        XCTAssertEqual(restored.current?.phase, .active)
        await restored.submit(.scanQR(payload: qr.expectedPayload))
        XCTAssertNil(restored.errorMessage)
        XCTAssertFalse(restored.busy)
        let completed = try await record(in: reopened, parentID: definition.id)
        XCTAssertEqual(completed.session.id, armed.session.id)
        XCTAssertEqual(completed.session.phase, .completed)
        XCTAssertEqual(completed.session.currentChallengeIndex, 3)
        XCTAssertEqual(completed.session.challengeCompletedAt.count, 3)
        XCTAssertNotNil(completed.session.completedAt)
        XCTAssertNil(completed.checkpoint)
        XCTAssertTrue(completed.session.cancellation.allSatisfy { $0 == .succeeded })
        XCTAssertTrue(Set(try scheduler.currentAlarms().map(\.id)).isDisjoint(with: originalIDs))
        XCTAssertEqual(restored.current?.phase, .completed)
        XCTAssertEqual(restored.current?.content, .finished)
        // Neither an unknown notification hint nor an old completed occurrence
        // can reopen the host or manufacture another wake-up session on relaunch.
        for hint in [UUID(), completed.session.id] {
            UserDefaults.standard.set(hint.uuidString, forKey: pendingKey)
            let fresh = ChallengeModel(repository: reopened, service: restoredService,
                clock: { restoredClock.now() })
            await fresh.refresh()
            XCTAssertNil(fresh.errorMessage)
            XCTAssertNil(fresh.current)
            XCTAssertNil(UserDefaults.standard.string(forKey: pendingKey))
            let retained = try await record(in: reopened, parentID: definition.id)
            XCTAssertEqual(retained, completed)
            guard case let .loaded(snapshot, _) = try await reopened.load() else {
                return XCTFail("Completed session storage disappeared")
            }
            XCTAssertEqual(snapshot.state.sessions.count, 1)
        }
    }

    @MainActor
    func testFutureHintsDoNotOpenHostAndOrdinaryRefreshRoutesActualDueOccurrence() async throws {
        let pendingKey = "PuzzleAlarm.pendingOccurrenceID"
        UserDefaults.standard.removeObject(forKey: pendingKey)
        defer { UserDefaults.standard.removeObject(forKey: pendingKey) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let clock = try SimulatorClock(directory: directory)
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler,
            clock: { clock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let now = clock.now()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let future = calendar.dateComponents([.hour, .minute], from: now.addingTimeInterval(3_600))
        let definition = try AlarmDefinition(id: UUID(),
            time: AlarmTime(hour: XCTUnwrap(future.hour), minute: XCTUnwrap(future.minute)), weekdays: [],
            enabled: true, dismissalMode: .challengesRequired,
            challengeSequence: ChallengeSequence([.qr(QRConfiguration(token: UUID()))]),
            selectedSound: .systemDefault, createdAt: now, updatedAt: now)
        _ = try await service.perform(.create(definition))
        let armed = try await record(in: repository, parentID: definition.id)
        let originalIDs = Set(armed.session.plan.alarms.map(\.id))
        XCTAssertEqual(originalIDs.count, 5)
        XCTAssertEqual(armed.session.phase, .armed)
        XCTAssertGreaterThan(armed.session.scheduledWakeUpDate, clock.now())
        let model = ChallengeModel(repository: repository, service: service, clock: { clock.now() })
        for hint in [UUID(), armed.session.id] {
            UserDefaults.standard.set(hint.uuidString, forKey: pendingKey)
            await model.refresh()
            XCTAssertNil(model.errorMessage)
            XCTAssertNil(model.current, "Hints cannot activate a future occurrence")
            XCTAssertEqual(model.nextWakeUpDate, armed.session.scheduledWakeUpDate)
            XCTAssertNil(UserDefaults.standard.string(forKey: pendingKey))
            let unchanged = try await record(in: repository, parentID: definition.id)
            XCTAssertEqual(unchanged, armed)
        }

        // No preview command: the normal foreground refresh must detect due work.
        try clock.advance(to: armed.session.scheduledWakeUpDate)
        UserDefaults.standard.set(UUID().uuidString, forKey: pendingKey)
        await model.refresh()
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.current?.sessionID, armed.session.id)
        XCTAssertEqual(model.current?.phase, .active)
        XCTAssertEqual(model.current?.challengeIndex, 0)
        XCTAssertEqual(model.current?.content, .qr)
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
        let due = try await record(in: repository, parentID: definition.id)
        XCTAssertTrue(due.session.challengeCompletedAt.isEmpty)
        XCTAssertNil(due.session.completedAt)
        XCTAssertTrue(due.session.cancellation.allSatisfy { $0 == .notRequested })
        UserDefaults.standard.set(armed.session.id.uuidString, forKey: pendingKey)
        let fresh = ChallengeModel(repository: repository, service: service, clock: { clock.now() })
        await fresh.refresh()
        XCTAssertNil(fresh.errorMessage)
        XCTAssertEqual(fresh.current?.sessionID, armed.session.id)
        XCTAssertEqual(fresh.current?.phase, .active)
        XCTAssertNil(UserDefaults.standard.string(forKey: pendingKey))
        guard case let .loaded(snapshot, _) = try await repository.load() else {
            return XCTFail("Due session storage disappeared")
        }
        XCTAssertEqual(snapshot.state.sessions.count, 1)
        XCTAssertEqual(snapshot.state.sessions.first, due)
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
    }

    @MainActor
    func testFailedProgressCommitKeepsChallengeAndBackupsUntilDurableRetry() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = RejectingChallengeRepository(base: DiskRepository(directory: directory))
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let clock = try SimulatorClock(directory: directory)
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler,
            clock: { clock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let qr = QRConfiguration(token: UUID())
        let definition = try makeDefinition([.qr(qr)], now: clock.now())
        _ = try await service.perform(.create(definition))
        let model = ChallengeModel(repository: repository, service: service,
            clock: { clock.now() }, advancePreviewClock: { try clock.advance(to: $0) })
        await model.runNow(alarmID: definition.id)
        XCTAssertNil(model.errorMessage)
        let before = try await record(in: repository, parentID: definition.id)
        let presentation = try XCTUnwrap(model.current)
        let originalIDs = Set(try scheduler.currentAlarms().map(\.id))
        XCTAssertEqual(originalIDs.count, 5)
        await repository.setRejectWrites(true)
        await model.submit(.scanQR(payload: qr.expectedPayload))
        let failed = try await record(in: repository, parentID: definition.id)
        XCTAssertEqual(failed, before)
        XCTAssertEqual(failed.session.phase, .active)
        XCTAssertTrue(failed.session.challengeCompletedAt.isEmpty)
        XCTAssertNil(failed.session.completedAt)
        XCTAssertEqual(model.current, presentation)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.busy)
        XCTAssertEqual(Set(try scheduler.currentAlarms().map(\.id)), originalIDs)
        await repository.setRejectWrites(false)
        await model.submit(.scanQR(payload: qr.expectedPayload))
        XCTAssertNil(model.errorMessage)
        let retried = try await record(in: repository, parentID: definition.id)
        XCTAssertEqual(retried.session.phase, .completed)
        XCTAssertEqual(retried.session.challengeCompletedAt.count, 1)
        XCTAssertEqual(model.current?.phase, .completed)
        XCTAssertTrue(Set(try scheduler.currentAlarms().map(\.id)).isDisjoint(with: originalIDs))
    }

    @MainActor
    func testHintSelectsSecondDueSessionAndLateQRCallbackCannotCompleteTheNextSession() async throws {
        let pendingKey = "PuzzleAlarm.pendingOccurrenceID"
        UserDefaults.standard.removeObject(forKey: pendingKey)
        defer { UserDefaults.standard.removeObject(forKey: pendingKey) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let clock = try SimulatorClock(directory: directory)
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler,
            clock: { clock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let qr = QRConfiguration(token: UUID())
        let now = clock.now()
        let first = try makeDefinition([.qr(qr)], now: now)
        let second = try makeDefinition([.qr(qr)], now: now)
        _ = try await service.perform(.create(first))
        _ = try await service.perform(.create(second))
        let firstArmed = try await record(in: repository, parentID: first.id)
        let secondArmed = try await record(in: repository, parentID: second.id)
        try clock.advance(to: max(firstArmed.session.scheduledWakeUpDate, secondArmed.session.scheduledWakeUpDate))
        UserDefaults.standard.set(secondArmed.session.id.uuidString, forKey: pendingKey)
        let model = ChallengeModel(repository: repository, service: service, clock: { clock.now() })
        await model.refresh()
        XCTAssertNil(model.errorMessage)
        let oldDisplay = try XCTUnwrap(model.current)
        XCTAssertEqual(oldDisplay.sessionID, secondArmed.session.id,
                       "Preparing the hinted session must preserve its selection")
        XCTAssertEqual(oldDisplay.content, .qr)
        XCTAssertNil(UserDefaults.standard.string(forKey: pendingKey))
        await model.submit(.scanQR(payload: qr.expectedPayload), expecting: oldDisplay)
        XCTAssertNil(model.errorMessage)
        let secondCompleted = try await record(in: repository, parentID: second.id)
        XCTAssertEqual(secondCompleted.session.phase, .completed)
        let nextDisplay = try XCTUnwrap(model.current)
        XCTAssertEqual(nextDisplay.sessionID, firstArmed.session.id)
        XCTAssertEqual(nextDisplay.phase, .active)
        XCTAssertEqual(nextDisplay.content, .qr)
        let beforeLateCallback = try await record(in: repository, parentID: first.id)
        await model.submit(.scanQR(payload: qr.expectedPayload), expecting: oldDisplay)
        let afterLateCallback = try await record(in: repository, parentID: first.id)
        XCTAssertEqual(afterLateCallback, beforeLateCallback)
        XCTAssertTrue(afterLateCallback.session.challengeCompletedAt.isEmpty)
        XCTAssertEqual(model.current, nextDisplay)
        XCTAssertNil(model.errorMessage)
        let observed = Set(try scheduler.currentAlarms().map(\.id))
        XCTAssertEqual(observed, Set(firstArmed.session.plan.alarms.map(\.id)))
        await model.submit(.scanQR(payload: qr.expectedPayload), expecting: nextDisplay)
        XCTAssertNil(model.errorMessage)
        let firstCompleted = try await record(in: repository, parentID: first.id)
        XCTAssertEqual(firstCompleted.session.phase, .completed)
        XCTAssertEqual(firstCompleted.session.challengeCompletedAt.count, 1)
        XCTAssertTrue(try scheduler.currentAlarms().isEmpty)
    }

    @MainActor
    func testCompletedAnswersRemainUnfinishedUntilFailedAlarmCancellationRecovers() async throws {
        let pendingKey = "PuzzleAlarm.pendingOccurrenceID"
        UserDefaults.standard.removeObject(forKey: pendingKey)
        defer { UserDefaults.standard.removeObject(forKey: pendingKey) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let scheduler = OneCancellationFailureScheduler(base: try SimulatorAlarmScheduler(directory: directory))
        let clock = try SimulatorClock(directory: directory)
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler,
            clock: { clock.now() }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        let qr = QRConfiguration(token: UUID())
        let definition = try makeDefinition([.qr(qr)], now: clock.now())
        _ = try await service.perform(.create(definition))
        let model = ChallengeModel(repository: repository, service: service,
            clock: { clock.now() }, advancePreviewClock: { try clock.advance(to: $0) })
        await model.runNow(alarmID: definition.id)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.current?.phase, .active)
        XCTAssertEqual(try scheduler.currentAlarms().count, 5)
        scheduler.failNextCancellation()
        await model.submit(.scanQR(payload: qr.expectedPayload), expecting: model.current)
        let failed = try await record(in: DiskRepository(directory: directory), parentID: definition.id)
        XCTAssertEqual(failed.session.currentChallengeIndex, 1)
        XCTAssertEqual(failed.session.challengeCompletedAt.count, 1)
        XCTAssertNil(failed.checkpoint)
        XCTAssertEqual(failed.session.phase, .cancellationPartiallyFailed)
        XCTAssertNil(failed.session.completedAt)
        XCTAssertEqual(model.current?.phase, .cancellationPartiallyFailed)
        let remainingIDs = Set(try scheduler.currentAlarms().map(\.id))
        XCTAssertEqual(remainingIDs.count, 1)
        XCTAssertEqual(remainingIDs, Set(failed.session.remainingCancellationIDs))
        await model.refresh()
        XCTAssertNil(model.errorMessage)
        let recovered = try await record(in: DiskRepository(directory: directory), parentID: definition.id)
        XCTAssertEqual(recovered.session.id, failed.session.id)
        XCTAssertEqual(recovered.session.phase, .completed)
        XCTAssertNotNil(recovered.session.completedAt)
        XCTAssertEqual(recovered.session.challengeCompletedAt, failed.session.challengeCompletedAt)
        XCTAssertTrue(recovered.session.cancellation.allSatisfy { $0 == .succeeded })
        XCTAssertTrue(try scheduler.currentAlarms().isEmpty)
        XCTAssertEqual(model.current?.phase, .completed)
    }

    func testPreviewClockPersistsItsAdvanceAndRejectsCorruptStorage() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let advanced = Date().addingTimeInterval(3_600)
        let clock = try SimulatorClock(directory: directory)
        try clock.advance(to: advanced)
        let reopened = try SimulatorClock(directory: directory)
        XCTAssertGreaterThanOrEqual(reopened.now(), advanced)
        try reopened.advance(to: advanced.addingTimeInterval(-60))
        XCTAssertGreaterThanOrEqual(reopened.now(), advanced)
        try Data("not-json".utf8).write(to: directory.appendingPathComponent("simulator-clock.json"))
        XCTAssertThrowsError(try SimulatorClock(directory: directory))
    }

    private func makeDefinition(_ challenges: [ChallengeConfiguration], now: Date) throws -> AlarmDefinition {
        // A one-time alarm avoids creating a later repeating occurrence after cleanup.
        try AlarmDefinition(id: UUID(), time: AlarmTime(hour: 6, minute: 30), weekdays: [],
            enabled: true, dismissalMode: .challengesRequired,
            challengeSequence: ChallengeSequence(challenges), selectedSound: .systemDefault,
            createdAt: now, updatedAt: now)
    }

    private func record(in repository: any PuzzleAlarmRepository, parentID: UUID) async throws -> PersistedSession {
        guard case let .loaded(snapshot, _) = try await repository.load(),
              let record = snapshot.state.sessions.first(where: { $0.session.parentAlarmID == parentID })
        else { throw ChallengeModelFixtureError.missingSession }
        return record
    }
}

private enum ChallengeModelFixtureError: Error { case missingSession }

private actor RejectingChallengeRepository: PuzzleAlarmRepository {
    private let base: any PuzzleAlarmRepository
    private var rejectWrites = false

    init(base: any PuzzleAlarmRepository) { self.base = base }
    func setRejectWrites(_ reject: Bool) { rejectWrites = reject }
    func load() async throws -> RepositoryRead { try await base.load() }
    func commit(_ state: RepositoryState, expecting version: RepositoryVersion) async throws -> RepositorySnapshot {
        if rejectWrites { throw PersistenceError.io("Injected challenge commit failure") }
        return try await base.commit(state, expecting: version)
    }
}

private final class OneCancellationFailureScheduler: AlarmScheduling, @unchecked Sendable {
    private let base: SimulatorAlarmScheduler
    private let lock = NSLock()
    private var shouldFail = false
    init(base: SimulatorAlarmScheduler) { self.base = base }
    var authorization: AlarmAuthorization { base.authorization }
    func failNextCancellation() { lock.withLock { shouldFail = true } }
    func requestAuthorization() async throws -> AlarmAuthorization { try await base.requestAuthorization() }
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm { try await base.schedule(request) }
    func currentAlarms() throws -> [RegisteredAlarm] { try base.currentAlarms() }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async {
        await base.observeAlarms(receive)
    }
    func cancel(id: UUID) throws {
        let fail = lock.withLock { let value = shouldFail; shouldFail = false; return value }
        if fail { throw PersistenceError.io("Injected one-time cancellation failure") }
        try base.cancel(id: id)
    }
}
#endif
