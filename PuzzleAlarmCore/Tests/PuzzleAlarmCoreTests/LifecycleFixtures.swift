import Foundation
import Testing
@testable import PuzzleAlarmCore

enum LifecycleTestFailure: Error { case injected }

// The fake stores OS IDs and outcomes only, never implements recovery/business policy.
final class FakeAlarmScheduler: AlarmScheduling, @unchecked Sendable {
    enum Call: Equatable, Sendable { case schedule(AlarmRequest), cancel(UUID) }
    struct Storage {
        var alarms: [RegisteredAlarm] = []
        var calls: [Call] = []
        var scheduleCount = 0
        var failSchedule: Int?
        var failAfterEffect = false
        var failCancellation: Set<UUID> = []
        var cancelFailsAfterEffect = false
        var snapshotFails = false
        var snapshotOverride: [RegisteredAlarm]?
        var afterSchedule: (@Sendable (AlarmRequest) async throws -> Void)?
    }
    private let lock = NSLock()
    private var storage = Storage()
    var authorization: AlarmAuthorization { .authorized }
    func requestAuthorization() async throws -> AlarmAuthorization { .authorized }
    func configure(_ body: (inout Storage) -> Void) { lock.withLock { body(&storage) } }
    var values: Storage { lock.withLock { storage } }

    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        let result = lock.withLock { () -> (Bool, (@Sendable (AlarmRequest) async throws -> Void)?) in
            storage.calls.append(.schedule(request)); storage.scheduleCount += 1
            let fail = storage.scheduleCount == storage.failSchedule
            if !fail || storage.failAfterEffect {
                storage.alarms.removeAll { $0.id == request.plannedAlarm.id }
                storage.alarms.append(.init(id: request.plannedAlarm.id, state: .scheduled))
            }
            return (fail, storage.afterSchedule)
        }
        if result.0 { throw LifecycleTestFailure.injected }
        try await result.1?(request)
        return RegisteredAlarm(id: request.plannedAlarm.id, state: .scheduled)
    }
    func cancel(id: UUID) throws {
        try lock.withLock {
            storage.calls.append(.cancel(id))
            if storage.failCancellation.contains(id) {
                if storage.cancelFailsAfterEffect { storage.alarms.removeAll { $0.id == id } }
                throw LifecycleTestFailure.injected
            }
            storage.alarms.removeAll { $0.id == id }
        }
    }
    func currentAlarms() throws -> [RegisteredAlarm] {
        try lock.withLock {
            if storage.snapshotFails { throw LifecycleTestFailure.injected }
            return storage.snapshotOverride ?? storage.alarms
        }
    }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async {
        if let snapshot = try? currentAlarms() { receive(snapshot) }
    }
    var schedules: [AlarmRequest] { values.calls.compactMap { if case let .schedule(r) = $0 { r } else { nil } } }
    var cancellations: [UUID] { values.calls.compactMap { if case let .cancel(id) = $0 { id } else { nil } } }
}

final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date
    init(_ value: Date) { self.value = value }
    func now() -> Date { lock.withLock { value } }
    func set(_ date: Date) { lock.withLock { value = date } }
}

actor FaultRepository: PuzzleAlarmRepository {
    let storage = InMemoryRepository()
    var reject: (@Sendable (RepositoryState) -> Bool)?
    var interfere: (@Sendable (InMemoryRepository) async throws -> Void)?
    var interferenceCondition: (@Sendable (RepositoryState) -> Bool)?
    var alwaysConflict = false
    var attempts = 0
    func load() async throws -> RepositoryRead { try await storage.load() }
    func commit(_ state: RepositoryState, expecting version: RepositoryVersion) async throws -> RepositorySnapshot {
        attempts += 1
        if alwaysConflict { throw PersistenceError.conflict }
        if let action = interfere, interferenceCondition?(state) ?? true {
            interfere = nil
            try await action(storage)
            throw PersistenceError.conflict
        }
        if reject?(state) == true { reject = nil; throw PersistenceError.io("injected acknowledgment") }
        return try await storage.commit(state, expecting: version)
    }
    func rejectOnce(_ predicate: @escaping @Sendable (RepositoryState) -> Bool) { reject = predicate }
    func interfereOnce(_ action: @escaping @Sendable (InMemoryRepository) async throws -> Void,
                       when condition: @escaping @Sendable (RepositoryState) -> Bool = { _ in true }) {
        interfere = action; interferenceCondition = condition
    }
    func conflictForever() { alwaysConflict = true }
}

func lifecycleContext() throws -> ScheduleContext { try ScheduleContext(timeZoneIdentifier: "UTC") }
func lifecycleNow() throws -> Date { try instant("2026-10-01T00:00:00Z") }
func lifecycleOrdinary(days: Set<Weekday> = [.monday], enabled: Bool = true) throws -> AlarmDefinition {
    try definition(sequence: [], weekdays: days, enabled: enabled, mode: .annoyingOnly)
}
func repositoryState(_ repository: any PuzzleAlarmRepository) async throws -> RepositoryState {
    guard case let .loaded(snapshot, _) = try await repository.load() else { return try RepositoryState() }
    return snapshot.state
}
func orchestrator(_ repository: any PuzzleAlarmRepository, _ scheduler: FakeAlarmScheduler,
                  now: Date? = nil) throws -> AlarmLifecycleCoordinator {
    let date = try now ?? lifecycleNow()
    return AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: { date })
}
