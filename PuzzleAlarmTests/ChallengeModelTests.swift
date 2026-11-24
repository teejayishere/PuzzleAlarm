#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class ChallengeModelTests: XCTestCase, @unchecked Sendable {
    @MainActor
    func testRunNowPersistsAllThreeChallengesRestoresAndCancelsOnlyAfterFullSequence() async throws {
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
#endif
