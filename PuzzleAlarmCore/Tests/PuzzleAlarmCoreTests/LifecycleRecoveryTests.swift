import Foundation
import Testing
@testable import PuzzleAlarmCore

@Suite("Lifecycle recovery")
struct LifecycleRecoveryTests {
    @Test(arguments: 0...5)
    func restartAfterEachSchedulingSideEffectUsesPersistedIDs(_ count: Int) async throws {
        var value = try session()
        try value.beginScheduling()
        for index in 0..<max(1, count) {
            let id = value.plan.alarms[index].id
            try value.beginScheduleAttempt(id: id)
            if index < count - 1 { try value.recordScheduled(id: id) }
        }
        let repository = InMemoryRepository()
        _ = try await repository.commit(RepositoryState(definitions: [value.definitionSnapshot], sessions: [
            PersistedSession(session: value, updatedAt: value.createdAt)
        ]), expecting: .missing)
        let restarted = InMemoryRepository(storedRepresentation: await repository.storedRepresentation())
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.alarms = value.plan.alarms.prefix(count).map { .init(id: $0.id, state: .scheduled) } }
        let coordinator = try orchestrator(restarted, scheduler)
        let result = try await coordinator.startup(context: lifecycleContext())
        #expect(result.state.sessions.count == 1 && result.state.sessions[0].session.phase == .armed)
        #expect(result.state.sessions[0].session.plan == value.plan)
        #expect(scheduler.schedules.map(\.plannedAlarm.id) == Array(value.plan.alarms.dropFirst(count)).map(\.id))
        let saved = try await restarted.load()
        _ = try await coordinator.startup(context: lifecycleContext())
        #expect(try await restarted.load() == saved)
        #expect(scheduler.schedules.count == 5 - count)
    }

    @Test(arguments: [false, true])
    func plannedOrAllAcknowledgedBeforeArmRecoversWithoutNewIdentity(_ allAcknowledged: Bool) async throws {
        var value = try session()
        if allAcknowledged {
            try value.beginScheduling()
            for alarm in value.plan.alarms {
                try value.beginScheduleAttempt(id: alarm.id); try value.recordScheduled(id: alarm.id)
            }
        }
        let repository = InMemoryRepository()
        _ = try await repository.commit(RepositoryState(definitions: [value.definitionSnapshot], sessions: [
            PersistedSession(session: value, updatedAt: value.createdAt)
        ]), expecting: .missing)
        let scheduler = FakeAlarmScheduler()
        if allAcknowledged { scheduler.configure { $0.alarms = value.plan.alarms.map { .init(id: $0.id, state: .scheduled) } } }
        let result = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.id == value.id)
        #expect(result.state.sessions[0].session.phase == .armed)
        #expect(scheduler.schedules.count == (allAcknowledged ? 0 : 5))
    }

    @Test func scheduleAcknowledgmentWriteFailureRetainsInFlightAndDoesNotRepeatOSSuccess() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.afterSchedule = { _ in await repository.failNext(.write) } }
        let coordinator = try orchestrator(repository, scheduler)
        await #expect(throws: PersistenceError.self) {
            try await coordinator.create(definition(), context: lifecycleContext())
        }
        let pending = try await repositoryState(repository)
        #expect(pending.sessions[0].session.scheduling[0] == .inFlight)
        #expect(scheduler.schedules.count == 1)
        scheduler.configure { $0.afterSchedule = nil }
        let restarted = InMemoryRepository(storedRepresentation: await repository.storedRepresentation())
        let result = try await orchestrator(restarted, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .armed)
        #expect(scheduler.schedules.count == 5)
    }

    @Test(arguments: [false, true])
    func cancellationCrashWindowUsesSnapshotAbsenceOrRetriesPresence(_ present: Bool) async throws {
        var value = try session()
        try value.beginScheduling()
        for alarm in value.plan.alarms.prefix(3) {
            try value.beginScheduleAttempt(id: alarm.id)
            if alarm.ordinal == 2 { try value.recordScheduleFailure(id: alarm.id) }
            else { try value.recordScheduled(id: alarm.id) }
        }
        try value.beginCancellation(id: value.primaryAlarmID)
        try value.recordCancellation(id: value.primaryAlarmID, succeeded: true)
        try value.beginCancellation(id: value.backupAlarmIDs[0])
        var operation = LifecycleOperation(id: uuid(70), configuration: value.definitionSnapshot, context: value.context)
        operation.sessionID = value.id; operation.status = .failed; operation.failure = .scheduling
        let repository = InMemoryRepository()
        _ = try await repository.commit(RepositoryState(definitions: [value.definitionSnapshot], sessions: [
            PersistedSession(session: value, updatedAt: value.createdAt)
        ], operations: [operation]), expecting: .missing)
        let scheduler = FakeAlarmScheduler()
        let ids = present ? [value.backupAlarmIDs[0], value.backupAlarmIDs[1]] : [value.backupAlarmIDs[1]]
        scheduler.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
        let result = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .cancelled)
        #expect(scheduler.cancellations == ids)
        #expect(scheduler.schedules.isEmpty)
        #expect(result.state.sessions[0].session.completedAt == nil)
    }

    @Test(arguments: [0, 1, 4])
    func futureArmedMissingSiblingNeverRemainsArmedOrCompletes(_ index: Int) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let armed = try await coordinator.create(definition(), context: lifecycleContext())
        let id = armed.state.sessions[0].session.plan.alarms[index].id
        scheduler.configure { $0.alarms.removeAll { $0.id == id } }
        let result = try await coordinator.startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .cancelled)
        #expect(result.state.sessions[0].session.completedAt == nil)
        #expect(result.state.operations[0].failure == .missingAlarm)
        #expect(scheduler.schedules.count == 5 && scheduler.cancellations.count == 4)
    }

    @Test func dueMissingAlarmsBecomeActiveWithoutChallengeSuccess() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let armed = try await coordinator.create(definition(), context: lifecycleContext())
        clock.set(armed.state.sessions[0].session.scheduledWakeUpDate)
        scheduler.configure { $0.alarms = [] }
        let result = try await coordinator.startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .active)
        #expect(result.state.sessions[0].session.currentChallengeIndex == 0)
        #expect(result.state.sessions[0].session.completedAt == nil)
        #expect(result.issues.count == 5 && scheduler.cancellations.isEmpty)
    }

    @Test func snapshotFailureAndCorruptStorageCannotProduceEmptySuccess() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.snapshotFails = true }
        await #expect(throws: LifecycleTestFailure.self) {
            try await orchestrator(repository, scheduler).create(definition(), context: lifecycleContext())
        }
        #expect(try await repository.load() == .missing)
        scheduler.configure { $0.snapshotFails = false }
        let corrupt = InMemoryRepository(storedRepresentation: Data("{".utf8))
        await #expect(throws: PersistenceError.corrupt) {
            try await orchestrator(corrupt, scheduler).startup(context: lifecycleContext())
        }
        #expect(scheduler.values.calls.isEmpty)
        #expect(await corrupt.storedRepresentation() == Data("{".utf8))
    }

    @Test func missingVersusEmptyAndForeignVersusOrphanRemainDistinct() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.alarms = [.init(id: uuid(80), state: .scheduled),
                                           .init(id: uuid(81), state: .scheduled, scope: .foreign)] }
        let coordinator = try orchestrator(repository, scheduler)
        let missing = try await coordinator.startup(context: lifecycleContext())
        #expect(missing.wasMissing && missing.issues == [.orphaned(uuid(80))])
        #expect(try await repository.load() == .missing)
        _ = try await repository.commit(RepositoryState(), expecting: .missing)
        let empty = try await coordinator.startup(context: lifecycleContext())
        #expect(!empty.wasMissing && empty.issues == missing.issues)
        #expect(scheduler.values.calls.isEmpty)
    }

    @Test func duplicateSnapshotAndForeignOwnershipConflictFailBeforeEffects() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.alarms = Array(repeating: .init(id: uuid(80), state: .scheduled), count: 2) }
        await #expect(throws: LifecycleError.duplicateObserved(uuid(80))) {
            try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        }
        scheduler.configure { $0.alarms = [] }
        let coordinator = try orchestrator(repository, scheduler)
        let ready = try await coordinator.create(definition(), context: lifecycleContext())
        let id = ready.state.sessions[0].session.primaryAlarmID
        scheduler.configure { $0.alarms = [.init(id: id, state: .scheduled, scope: .foreign)] }
        await #expect(throws: LifecycleError.foreignOwnership(id)) {
            try await coordinator.disable(uuid(1), context: lifecycleContext())
        }
        #expect(scheduler.cancellations.isEmpty)
    }

    @Test func ordinaryFailureAndMissingRecoveryRetainStableOwnership() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.failSchedule = 1; $0.failAfterEffect = true }
        let coordinator = try orchestrator(repository, scheduler)
        let failed = try await coordinator.create(lifecycleOrdinary(), context: lifecycleContext())
        let id = failed.state.detachedOwnership[0].alarmKitID
        #expect(failed.state.operations[0].failure == .scheduling)
        #expect(failed.state.detachedOwnership[0].cancellation == .succeeded)
        #expect(scheduler.cancellations == [id])
        scheduler.configure { $0.failSchedule = nil }
        let ready = try await coordinator.retry(uuid(1), context: lifecycleContext())
        #expect(ready.state.operations[0].status == .ready)
        #expect(scheduler.schedules.map(\.plannedAlarm.id) == [id, id])
        scheduler.configure { $0.alarms = [] }
        let missing = try await coordinator.startup(context: lifecycleContext())
        #expect(missing.state.operations[0].failure == .missingAlarm)
        _ = try await coordinator.startup(context: lifecycleContext())
        #expect(scheduler.schedules.count == 2)
        _ = try await coordinator.retry(uuid(1), context: lifecycleContext())
        #expect(scheduler.schedules.map(\.plannedAlarm.id) == [id, id, id])
    }

    @Test(arguments: [false, true])
    func ordinaryInFlightRecoveryReconcilesPresenceOrRetriesSameID(_ present: Bool) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.afterSchedule = { _ in await repository.failNext(.write) } }
        let coordinator = try orchestrator(repository, scheduler)
        await #expect(throws: PersistenceError.self) {
            try await coordinator.create(lifecycleOrdinary(), context: lifecycleContext())
        }
        let id = try await repositoryState(repository).detachedOwnership[0].alarmKitID
        scheduler.configure { $0.afterSchedule = nil; if !present { $0.alarms = [] } }
        let recovered = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(recovered.state.detachedOwnership[0].scheduling == .scheduled)
        #expect(scheduler.schedules.count == (present ? 1 : 2))
        #expect(scheduler.schedules.allSatisfy { $0.plannedAlarm.id == id })
    }

    @Test func elapsedOneTimeIntentNeverSchedulesInThePast() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.afterSchedule = { _ in await repository.failNext(.write) } }
        await #expect(throws: PersistenceError.self) {
            try await orchestrator(repository, scheduler).create(lifecycleOrdinary(days: []), context: lifecycleContext())
        }
        let wake = try await repositoryState(repository).detachedOwnership[0].intendedDate
        scheduler.configure { $0.afterSchedule = nil; $0.alarms = [] }
        let result = try await orchestrator(repository, scheduler, now: wake).startup(context: lifecycleContext())
        #expect(result.state.operations[0].failure == .elapsedOccurrence)
        #expect(result.state.operations[0].oneTimeConsumed)
        #expect(!result.state.definitions[0].enabled && scheduler.schedules.count == 1)
    }

    @Test func stalePositiveSnapshotDoesNotRepeatAcknowledgedCancellation() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        _ = try await coordinator.create(lifecycleOrdinary(), context: lifecycleContext())
        let stale = scheduler.values.alarms
        scheduler.configure { $0.snapshotOverride = stale }
        let first = try await coordinator.disable(uuid(1), context: lifecycleContext())
        #expect(first.issues.contains(.stalePresent(stale[0].id)))
        let persisted = try await repository.load()
        _ = try await coordinator.startup(context: lifecycleContext())
        #expect(scheduler.cancellations.count == 1)
        #expect(try await repository.load() == persisted)
    }
}
