import Foundation
import Testing
@testable import PuzzleAlarmCore

@Suite("Lifecycle adversarial")
struct LifecycleAdversarialTests {
    @Test func conflictReloadPreservesNewerConfigurationInsteadOfOverwritingIt() async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try lifecycleOrdinary()
        _ = try await coordinator.create(original, context: lifecycleContext())
        let newer = try original.replacing(time: AlarmTime(hour: 10, minute: 0), weekdays: [.sunday],
            enabled: true, mode: .annoyingOnly, challenges: ChallengeSequence([]),
            sound: .bundled(.siren), at: lifecycleNow())
        await repository.interfereOnce { storage in
            guard case let .loaded(snapshot, _) = try await storage.load() else { throw FixtureError.invalidDate }
            var state = snapshot.state
            state.definitions[0] = newer
            _ = try await storage.commit(state, expecting: snapshot.version)
        }
        let requested = try original.settingEnabled(false, at: lifecycleNow())
        await #expect(throws: LifecycleError.superseded) {
            try await coordinator.edit(requested, expecting: original, context: lifecycleContext())
        }
        #expect(try await repositoryState(repository).definitions[0] == newer)
        #expect(scheduler.schedules.count == 1 && scheduler.cancellations.isEmpty)
        let recovered = try await coordinator.startup(context: lifecycleContext())
        #expect(recovered.state.definitions[0] == newer)
        #expect(scheduler.schedules.last?.selectedSound == .bundled(.siren))
        #expect(scheduler.schedules.last?.schedule == .weekly(newer.time, newer.weekdays))
    }

    @Test func conflictsDuringScheduleAndCancellationAcknowledgmentMergeNewerState() async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let unrelated = try AlarmDefinition(id: uuid(99), time: AlarmTime(hour: 9, minute: 0),
            weekdays: [], enabled: false, dismissalMode: .annoyingOnly, challengeSequence: ChallengeSequence([]),
            selectedSound: .systemDefault, createdAt: lifecycleNow(), updatedAt: lifecycleNow())
        let interference: @Sendable (InMemoryRepository) async throws -> Void = { storage in
            guard case let .loaded(snapshot, _) = try await storage.load() else { throw FixtureError.invalidDate }
            var state = snapshot.state
            if !state.definitions.contains(where: { $0.id == unrelated.id }) { state.definitions.append(unrelated) }
            _ = try await storage.commit(state, expecting: snapshot.version)
        }
        scheduler.configure { $0.afterSchedule = { request in
            if request.plannedAlarm.ordinal == 0 { await repository.interfereOnce(interference) }
        } }
        let coordinator = try orchestrator(repository, scheduler)
        let ready = try await coordinator.create(definition(), context: lifecycleContext())
        #expect(ready.state.definitions.contains(unrelated))
        #expect(ready.state.sessions[0].session.phase == .armed)
        await repository.interfereOnce(interference)
        let disabled = try await coordinator.disable(uuid(1), context: lifecycleContext())
        #expect(disabled.state.definitions.contains(unrelated))
        #expect(disabled.state.sessions[0].session.phase == .cancelled)
    }

    @Test func conflictRetryIsBoundedAndCannotReachOSBeforeIntent() async throws {
        let repository = FaultRepository()
        await repository.conflictForever()
        let scheduler = FakeAlarmScheduler()
        await #expect(throws: LifecycleError.conflictLimit) {
            try await orchestrator(repository, scheduler).create(definition(), context: lifecycleContext())
        }
        #expect(await repository.attempts == 3)
        #expect(scheduler.values.calls.isEmpty)
        #expect(try await repository.load() == .missing)
    }

    @Test func reentrantLifecycleEventIsRejectedDuringExternalAwait() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        scheduler.configure { $0.afterSchedule = { request in
            await #expect(throws: LifecycleError.busy) {
                try await coordinator.disable(request.parentAlarmID, context: lifecycleContext())
            }
        } }
        let result = try await coordinator.create(definition(), context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .armed)
        #expect(result.state.definitions[0].enabled && scheduler.cancellations.isEmpty)
    }

    @Test(arguments: 1...5)
    func restartDuringReplacementAfterEveryNewOSSuccessRetainsOldUntilNewHealthy(_ position: Int) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try definition()
        let first = try await coordinator.create(original, context: lifecycleContext())
        let oldIDs = Set(first.state.sessions[0].session.plan.alarms.map(\.id))
        let replacement = try original.replacing(time: AlarmTime(hour: 9, minute: 0), weekdays: [.monday],
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: .bundled(.escalating), at: lifecycleNow())
        scheduler.configure { $0.afterSchedule = { request in
            if !oldIDs.contains(request.plannedAlarm.id) && request.plannedAlarm.ordinal == position - 1 {
                await repository.failNext(.write)
            }
        } }
        await #expect(throws: PersistenceError.self) {
            try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        }
        #expect(scheduler.cancellations.isEmpty)
        #expect(oldIDs.isSubset(of: Set(scheduler.values.alarms.map(\.id))))
        scheduler.configure { $0.afterSchedule = nil }
        let restarted = InMemoryRepository(storedRepresentation: await repository.storedRepresentation())
        let result = try await orchestrator(restarted, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions.count == 2 && result.state.sessions[1].session.phase == .armed)
        #expect(Set(scheduler.cancellations) == oldIDs)
        #expect(scheduler.schedules.count == 10)
    }

    @Test func staleTerminalOwnershipIsRetainedAndNeverInventsCompletion() async throws {
        var value = try solvedSession()
        try cancelAll(&value); try value.finalizeCompletion(at: value.scheduledWakeUpDate)
        let disabled = try value.definitionSnapshot.settingEnabled(false, at: value.scheduledWakeUpDate)
        let repository = InMemoryRepository()
        _ = try await repository.commit(RepositoryState(definitions: [disabled], sessions: [
            PersistedSession(session: value, updatedAt: value.scheduledWakeUpDate)
        ]), expecting: .missing)
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.alarms = [.init(id: value.primaryAlarmID, state: .scheduled)] }
        let result = try await orchestrator(repository, scheduler, now: value.scheduledWakeUpDate).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session == value)
        #expect(result.issues.contains(.stalePresent(value.primaryAlarmID)))
        #expect(scheduler.values.calls.isEmpty)
        scheduler.configure { $0.alarms = [] }
        let absent = try await orchestrator(repository, scheduler, now: value.scheduledWakeUpDate).startup(context: lifecycleContext())
        #expect(absent.issues.isEmpty)
        #expect(absent.state.sessions[0].session == value)
    }

    @Test func operationCorruptionAndDuplicateOwnershipFailBeforeExternalEffects() async throws {
        let value = try session()
        var operation = LifecycleOperation(id: uuid(77), configuration: value.definitionSnapshot, context: value.context)
        operation.sessionID = uuid(200)
        #expect(throws: DomainError.self) { try RepositoryState(operations: [operation]) }
        operation.sessionID = nil
        #expect(throws: DomainError.self) { try RepositoryState(operations: [operation, operation]) }
        operation.status = .failed
        #expect(throws: DomainError.self) { try RepositoryState(operations: [operation]) }
        let repository = InMemoryRepository()
        let duplicate = try RepositorySnapshot(state: RepositoryState(sessions: [
            PersistedSession(session: value, updatedAt: value.createdAt)
        ]))
        let bytes = try mutatedJSON(duplicate) { root in
            var state = root["state"] as! [String: Any]
            let records = state["sessions"] as! [Any]
            state["sessions"] = records + records
            root["state"] = state
        }
        let broken = InMemoryRepository(storedRepresentation: bytes)
        let scheduler = FakeAlarmScheduler()
        await #expect(throws: PersistenceError.corrupt) {
            try await orchestrator(broken, scheduler).startup(context: lifecycleContext())
        }
        #expect(scheduler.values.calls.isEmpty)
        #expect(try await repository.load() == .missing)
    }

    @Test func degradedDueSessionPreservesAcknowledgmentsAndCannotBypassChallenges() async throws {
        var value = try armedSession()
        try value.recordMissingArmedAlarm(id: value.primaryAlarmID)
        #expect(value.phase == .degraded && value.scheduling.allSatisfy { $0 == .scheduled })
        var operation = LifecycleOperation(id: uuid(70), configuration: value.definitionSnapshot, context: value.context)
        operation.sessionID = value.id; operation.status = .failed; operation.failure = .missingAlarm
        let repository = InMemoryRepository()
        _ = try await repository.commit(RepositoryState(definitions: [value.definitionSnapshot], sessions: [
            PersistedSession(session: value, updatedAt: value.createdAt)
        ], operations: [operation]), expecting: .missing)
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.alarms = value.backupAlarmIDs.map { .init(id: $0, state: .scheduled) } }
        let result = try await orchestrator(repository, scheduler, now: value.scheduledWakeUpDate).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .active)
        #expect(result.state.sessions[0].session.currentChallengeIndex == 0)
        #expect(result.state.sessions[0].session.completedAt == nil)
        #expect(result.state.sessions[0].session.scheduling.allSatisfy { $0 == .scheduled })
        #expect(scheduler.cancellations.isEmpty && scheduler.schedules.isEmpty)
    }

    @Test(arguments: 1...5) func clockCrossingWakeTimeDuringScheduleStopsTheTransaction(_ position: Int) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        scheduler.configure { $0.afterSchedule = { request in
            if request.plannedAlarm.ordinal == position - 1 { clock.set(request.plannedAlarm.date.addingTimeInterval(1)) }
        } }
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let result = try await coordinator.create(definition(), context: lifecycleContext())
        #expect(scheduler.schedules.count == position)
        #expect(result.state.operations[0].failure == .elapsedOccurrence)
        #expect(result.state.sessions[0].session.phase == .cancelled)
        #expect(scheduler.values.alarms.isEmpty)
    }

    @Test func cancellationRefreshesSnapshotAfterDurableIntentAwait() async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let ready = try await coordinator.create(definition(), context: lifecycleContext())
        let primary = ready.state.sessions[0].session.primaryAlarmID
        scheduler.configure { $0.alarms.removeAll { $0.id == primary } }
        await repository.interfereOnce({ _ in
            // A delayed external scheduling result becomes visible during storage IO.
            scheduler.configure { $0.alarms.append(.init(id: primary, state: .scheduled)) }
        }, when: { $0.sessions.first?.session.cancellation[0] == .inFlight })
        let result = try await coordinator.disable(uuid(1), context: lifecycleContext())
        #expect(scheduler.cancellations.contains(primary))
        #expect(scheduler.values.alarms.isEmpty)
        #expect(result.state.sessions[0].session.phase == .cancelled)
    }

    @Test func parentEditDuringScheduleAwaitIsNotOverwrittenByAcknowledgment() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let original = try definition()
        let replacement = try original.replacing(time: AlarmTime(hour: 11, minute: 0), weekdays: [.sunday],
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: .bundled(.siren), at: lifecycleNow())
        scheduler.configure { $0.afterSchedule = { request in
            if request.plannedAlarm.ordinal == 0 {
                guard case let .loaded(snapshot, _) = try await repository.load() else { throw FixtureError.invalidDate }
                var state = snapshot.state
                state.definitions[0] = replacement
                _ = try await repository.commit(state, expecting: snapshot.version)
            }
        } }
        let coordinator = try orchestrator(repository, scheduler)
        await #expect(throws: LifecycleError.superseded) {
            try await coordinator.create(original, context: lifecycleContext())
        }
        #expect(try await repositoryState(repository).definitions[0] == replacement)
        #expect(scheduler.schedules.count == 1)
        scheduler.configure { $0.afterSchedule = nil }
        let recovered = try await coordinator.startup(context: lifecycleContext())
        #expect(recovered.state.sessions.last?.session.definitionSnapshot == replacement)
        #expect(scheduler.values.alarms.count == 5 && scheduler.cancellations.count == 1)
    }

    @Test func newerDefinitionDuringDeleteCannotBeRemovedByOldIntent() async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try definition()
        _ = try await coordinator.create(original, context: lifecycleContext())
        let newer = try original.replacing(time: AlarmTime(hour: 10, minute: 0), weekdays: [.friday],
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: .bundled(.siren), at: lifecycleNow())
        await repository.interfereOnce({ storage in
            guard case let .loaded(snapshot, _) = try await storage.load() else { throw FixtureError.invalidDate }
            var state = snapshot.state
            state.definitions[0] = newer
            _ = try await storage.commit(state, expecting: snapshot.version)
        }, when: { $0.sessions.first?.session.cancellation[0] == .succeeded })
        await #expect(throws: LifecycleError.superseded) {
            try await coordinator.delete(uuid(1), context: lifecycleContext())
        }
        #expect(try await repositoryState(repository).definitions == [newer])
        let result = try await coordinator.startup(context: lifecycleContext())
        #expect(result.state.definitions == [newer])
        #expect(result.state.sessions.last?.session.phase == .armed)
    }

    @Test func deletedIdentityCannotBeRecreatedOrUnknownCommandsReportedSuccessful() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try definition()
        _ = try await coordinator.create(original, context: lifecycleContext())
        _ = try await coordinator.delete(original.id, context: lifecycleContext())
        let saved = try await repository.load()
        await #expect(throws: DomainError.self) { try await coordinator.create(original, context: lifecycleContext()) }
        await #expect(throws: DomainError.unknownAlarm) { try await coordinator.retry(uuid(99), context: lifecycleContext()) }
        await #expect(throws: DomainError.unknownAlarm) { try await coordinator.enable(uuid(99), context: lifecycleContext()) }
        #expect(try await repository.load() == saved)
        #expect(scheduler.schedules.count == 5)
    }

    @Test func weeklyOrdinaryRetryAfterOriginalDateRetainsItsRecurringIdentity() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.failSchedule = 1 }
        let first = try await orchestrator(repository, scheduler).create(lifecycleOrdinary(), context: lifecycleContext())
        let entry = first.state.detachedOwnership[0]
        let later = entry.intendedDate.addingTimeInterval(86400)
        scheduler.configure { $0.failSchedule = nil }
        let result = try await orchestrator(repository, scheduler, now: later).retry(uuid(1), context: lifecycleContext())
        #expect(result.state.operations[0].status == .ready)
        #expect(scheduler.schedules.map(\.plannedAlarm.id) == [entry.alarmKitID, entry.alarmKitID])
        #expect(result.state.sessions.isEmpty && result.state.definitions[0].enabled)
    }

    @Test func observedRingingProtectsSessionEvenBeforeLocalClockReachesWakeDate() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try await coordinator.create(definition(), context: lifecycleContext())
        let value = original.state.sessions[0].session
        scheduler.configure { $0.alarms[0] = .init(id: value.primaryAlarmID, state: .alerting) }
        let result = try await coordinator.delete(uuid(1), context: lifecycleContext())
        #expect(result.issues.contains(.deletionDeferred(uuid(1))))
        #expect(result.state.sessions[0].session == value)
        #expect(scheduler.cancellations.isEmpty && scheduler.values.alarms.count == 5)
    }

    @Test func scheduleAndCancellationAcknowledgmentsRequireTheRightPhaseAndIntent() throws {
        var planned = try session()
        #expect(throws: DomainError.invalidTransition) { try planned.beginScheduleAttempt(id: planned.primaryAlarmID) }
        #expect(throws: DomainError.invalidTransition) { try planned.recordScheduled(id: planned.primaryAlarmID) }
        #expect(throws: DomainError.invalidTransition) { try planned.recordScheduleFailure(id: planned.primaryAlarmID) }
        try planned.beginScheduling()
        #expect(throws: DomainError.invalidTransition) { try planned.recordScheduleFailure(id: planned.primaryAlarmID) }
        try planned.requestRetirement()
        #expect(throws: DomainError.invalidTransition) { try planned.recordCancellation(id: planned.primaryAlarmID, succeeded: true) }
        #expect(planned.completedAt == nil && planned.remainingCancellationIDs.count == 5)
    }

    @Test func newerOperationGenerationDuringOSAwaitStopsOldScheduling() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.afterSchedule = { _ in
            guard case let .loaded(snapshot, _) = try await repository.load() else { throw FixtureError.invalidDate }
            var state = snapshot.state
            let old = state.operations[0]
            var newer = LifecycleOperation(id: uuid(99), configuration: old.configuration, context: old.context)
            newer.sessionID = old.sessionID
            state.operations[0] = newer
            _ = try await repository.commit(state, expecting: snapshot.version)
        } }
        await #expect(throws: LifecycleError.superseded) {
            try await orchestrator(repository, scheduler).create(definition(), context: lifecycleContext())
        }
        #expect(scheduler.schedules.count == 1)
        scheduler.configure { $0.afterSchedule = nil }
        let result = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(result.state.operations[0].id == uuid(99))
        #expect(result.state.sessions[0].session.phase == .armed && scheduler.schedules.count == 5)
    }

    @Test func oldSessionBecomingRingingDuringReplacementIsNotCancelled() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try definition()
        let first = try await coordinator.create(original, context: lifecycleContext())
        let old = first.state.sessions[0].session
        let replacement = try original.replacing(time: AlarmTime(hour: 9, minute: 0), weekdays: original.weekdays,
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: original.selectedSound, at: lifecycleNow())
        scheduler.configure { $0.afterSchedule = { _ in
            scheduler.configure { storage in
                storage.alarms.removeAll { $0.id == old.primaryAlarmID }
                storage.alarms.append(.init(id: old.primaryAlarmID, state: .alerting))
            }
        } }
        let result = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        #expect(result.state.operations[0].failure == .cancellation)
        #expect(result.state.sessions[0].session == old)
        #expect(result.state.sessions[1].session.phase == .armed)
        #expect(scheduler.cancellations.isEmpty)
    }
}
