import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class AlarmManagementTests: XCTestCase, @unchecked Sendable {
    @MainActor
    func testDraftPreservesIdentityFractionalDurationTokenAndOrder() throws {
        var draft = AlarmDraft()
        draft.mode = .challengesRequired
        draft.weekdays = [.monday, .friday]
        draft.hour = 6; draft.minute = 35; draft.soundIndex = 3
        draft.add(.memory); draft.add(.math); draft.add(.qr); draft.add(.math)
        XCTAssertEqual(draft.challenges.count, 3)
        draft.challenges[0].seconds = 2.5
        draft.challenges[0].rounds = 4
        draft.challenges[1].difficulty = .hard
        draft.challenges[1].correctCount = 12
        draft.move(2, by: -1)
        draft.move(0, by: -1)
        XCTAssertEqual(draft.challenges.map(\.kind), [.memory, .qr, .math])
        let now = Date()
        let saved = try draft.definition(at: now)
        let reopened = AlarmDraft(saved)
        XCTAssertEqual(try reopened.definition(at: now), saved)
        XCTAssertEqual(saved.selectedSound, .bundled(.siren))
        var ordinary = reopened
        ordinary.mode = .annoyingOnly
        XCTAssertTrue(try ordinary.definition(at: now).challengeSequence.items.isEmpty)
        ordinary.mode = .challengesRequired
        XCTAssertEqual(try ordinary.definition(at: now).challengeSequence, saved.challengeSequence)
        ordinary.challenges.removeAll()
        XCTAssertFalse(ordinary.canSave)
        XCTAssertThrowsError(try ordinary.definition(at: now))
    }

    @MainActor
    func testDiskCRUDThroughInjectedSchedulingAndRelaunch() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let scheduler = ManagementScheduler()
        let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler)
        let model = AlarmListModel(service: service, repository: repository)
        await model.refresh()
        var draft = AlarmDraft()
        draft.weekdays = [.monday, .friday]
        let created = await model.save(draft)
        XCTAssertTrue(created)
        XCTAssertEqual(scheduler.snapshot.count, 1)
        guard let original = model.definitions.first else { return XCTFail("No alarm") }
        draft = AlarmDraft(original)
        draft.mode = .challengesRequired
        draft.add(.memory); draft.add(.math); draft.add(.qr)
        draft.move(2, by: -1)
        draft.soundIndex = 2
        let edited = await model.save(draft)
        XCTAssertTrue(edited)
        XCTAssertEqual(scheduler.snapshot.count, 5)
        let restartedRepository = DiskRepository(directory: directory)
        let restarted = AlarmListModel(service: LifecycleAlarmManagementService(
            repository: restartedRepository, scheduler: scheduler), repository: restartedRepository)
        await restarted.refresh()
        XCTAssertEqual(restarted.definitions, model.definitions)
        XCTAssertEqual(restarted.definitions.first?.challengeSequence.items.map(\.kind), [.memory, .qr, .math])
        let disabled = await restarted.execute(.disable(original.id))
        XCTAssertTrue(disabled)
        XCTAssertEqual(scheduler.snapshot.count, 0)
        XCTAssertEqual(restarted.definitions.first?.enabled, false)
        let enabled = await restarted.execute(.enable(original.id))
        XCTAssertTrue(enabled)
        XCTAssertEqual(scheduler.snapshot.count, 5)
        let deleted = await restarted.execute(.delete(original.id))
        XCTAssertTrue(deleted)
        XCTAssertTrue(restarted.definitions.isEmpty)
        XCTAssertTrue(scheduler.snapshot.isEmpty)
        await model.refresh()
        XCTAssertTrue(model.definitions.isEmpty)
    }

    @MainActor
    func testPermissionIsExplicitAndDisabledConfigurationCanPersist() async throws {
        let repository = InMemoryRepository()
        let scheduler = ManagementScheduler()
        scheduler.configure(authorization: .notDetermined, requestResult: .denied)
        let model = AlarmListModel(service: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler), repository: repository)
        await model.refresh()
        XCTAssertEqual(scheduler.requests, 0)
        var draft = AlarmDraft()
        let rejected = await model.save(draft)
        XCTAssertFalse(rejected)
        XCTAssertEqual(scheduler.requests, 1)
        XCTAssertTrue(model.definitions.isEmpty)
        XCTAssertNotNil(model.errorMessage)
        draft.enabled = false
        let saved = await model.save(draft)
        XCTAssertTrue(saved)
        XCTAssertEqual(model.definitions.first?.enabled, false)
        XCTAssertTrue(scheduler.snapshot.isEmpty)
    }

    @MainActor
    func testSchedulingFailureIsVisibleAndExplicitRetryRecovers() async throws {
        let repository = InMemoryRepository()
        let scheduler = ManagementScheduler()
        scheduler.setFailure(true)
        let model = AlarmListModel(service: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler), repository: repository)
        await model.refresh()
        var draft = AlarmDraft(); draft.weekdays = [.monday]
        let saved = await model.save(draft)
        XCTAssertTrue(saved) // Configuration persisted, scheduling failed separately.
        XCTAssertNotNil(model.message)
        XCTAssertNotNil(model.status(for: draft.id))
        XCTAssertTrue(model.canRetry(draft.id))
        XCTAssertTrue(scheduler.snapshot.isEmpty)
        scheduler.setFailure(false)
        let retried = await model.execute(.retry(draft.id))
        XCTAssertTrue(retried)
        XCTAssertNil(model.status(for: draft.id))
        XCTAssertFalse(model.canRetry(draft.id))
        XCTAssertEqual(scheduler.snapshot.count, 1)
    }

    @MainActor
    func testCorruptDiskFailsClosedWithoutReplacingData() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("state.json")
        let corrupt = Data("not repository data".utf8)
        try corrupt.write(to: file)
        let repository = DiskRepository(directory: directory)
        let scheduler = ManagementScheduler()
        let model = AlarmListModel(service: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler), repository: repository)
        await model.refresh()
        XCTAssertFalse(model.loaded)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
        XCTAssertTrue(scheduler.snapshot.isEmpty)
    }

    @MainActor
    func testStaleEditorCannotOverwriteNewerConfiguration() async throws {
        let repository = InMemoryRepository()
        let scheduler = ManagementScheduler()
        let model = AlarmListModel(service: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler), repository: repository)
        await model.refresh()
        var draft = AlarmDraft(); draft.enabled = false
        _ = await model.save(draft)
        let original = try XCTUnwrap(model.definitions.first)
        var current = AlarmDraft(original); current.minute = 42
        let changed = await model.save(current)
        XCTAssertTrue(changed)
        var stale = AlarmDraft(original); stale.minute = 5
        let rejected = await model.save(stale)
        XCTAssertFalse(rejected)
        XCTAssertEqual(model.definitions.first?.time.minute, 42)
        XCTAssertNotNil(model.errorMessage)
    }

    @MainActor
    func testThrownAcknowledgmentReloadsDurableConfiguration() async throws {
        let repository = InMemoryRepository()
        let base = LifecycleAlarmManagementService(repository: repository, scheduler: ManagementScheduler())
        let model = AlarmListModel(service: ThrowAfterSavingService(base: base), repository: repository)
        var draft = AlarmDraft(); draft.enabled = false
        let result = await model.save(draft)
        XCTAssertFalse(result)
        XCTAssertEqual(model.definitions.first?.id, draft.id)
        XCTAssertTrue(model.loaded)
        XCTAssertFalse(model.busy)
        XCTAssertNotNil(model.errorMessage)
    }

    @MainActor
    func testBusyModelRejectsOverlappingCommands() async throws {
        let repository = InMemoryRepository()
        let gate = GatedManagementService(base: LifecycleAlarmManagementService(
            repository: repository, scheduler: ManagementScheduler()))
        let model = AlarmListModel(service: gate, repository: repository)
        let first = Task { await model.execute(.refresh) }
        await gate.waitUntilStarted()
        XCTAssertTrue(model.busy)
        let second = await model.execute(.refresh)
        XCTAssertFalse(second)
        await gate.release()
        let completed = await first.value
        XCTAssertTrue(completed)
        XCTAssertFalse(model.busy)
    }
}

private actor GatedManagementService: AlarmManagementService {
    let base: LifecycleAlarmManagementService
    var started = false
    var waiting: CheckedContinuation<Void, Never>?
    var observer: CheckedContinuation<Void, Never>?
    init(base: LifecycleAlarmManagementService) { self.base = base }
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport {
        await withCheckedContinuation { continuation in
            waiting = continuation; started = true
            observer?.resume(); observer = nil
        }
        return try await base.perform(command)
    }
    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { observer = $0 }
    }
    func release() { waiting?.resume(); waiting = nil }
}

private struct ThrowAfterSavingService: AlarmManagementService {
    let base: LifecycleAlarmManagementService
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport {
        _ = try await base.perform(command)
        throw PersistenceError.io("Injected after durable save")
    }
}

private final class ManagementScheduler: AlarmScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var ids: Set<UUID> = []
    private var auth: AlarmAuthorization = .authorized
    private var answer: AlarmAuthorization = .authorized
    private var requestCount = 0
    private var fail = false
    var authorization: AlarmAuthorization { lock.withLock { auth } }
    var requests: Int { lock.withLock { requestCount } }
    var snapshot: [RegisteredAlarm] { lock.withLock { ids.map { .init(id: $0, state: .scheduled) } } }
    func configure(authorization: AlarmAuthorization, requestResult: AlarmAuthorization) {
        lock.withLock { auth = authorization; answer = requestResult }
    }
    func setFailure(_ value: Bool) { lock.withLock { fail = value } }
    func requestAuthorization() async throws -> AlarmAuthorization {
        lock.withLock { requestCount += 1; auth = answer; return auth }
    }
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        try lock.withLock {
            if fail { throw PersistenceError.io("Injected schedule failure") }
            ids.insert(request.plannedAlarm.id)
        }
        return .init(id: request.plannedAlarm.id, state: .scheduled)
    }
    func cancel(id: UUID) throws { lock.withLock { _ = ids.remove(id) } }
    func currentAlarms() throws -> [RegisteredAlarm] { snapshot }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async { receive(snapshot) }
}
