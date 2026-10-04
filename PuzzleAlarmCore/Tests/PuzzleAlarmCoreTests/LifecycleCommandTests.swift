import Foundation
import Testing
@testable import PuzzleAlarmCore

@Suite("Lifecycle commands")
struct LifecycleCommandTests {
    @Test(arguments: [true, false])
    func enableDisabledDefinitionSchedulesExactlyOneRepresentation(_ challenge: Bool) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let value = try challenge ? definition(enabled: false) : lifecycleOrdinary(enabled: false)
        let coordinator = try orchestrator(repository, scheduler)
        _ = try await coordinator.create(value, context: lifecycleContext())
        #expect(scheduler.schedules.isEmpty)
        let enabled = try await coordinator.enable(value.id, context: lifecycleContext())
        #expect(enabled.state.definitions[0].enabled)
        #expect(scheduler.schedules.count == (challenge ? 5 : 1))
        let saved = try await repository.load()
        _ = try await coordinator.enable(value.id, context: lifecycleContext())
        #expect(try await repository.load() == saved)
    }

    @Test(arguments: [true, false])
    func disableRetainsFailedOwnershipAndNeverTouchesUnrelatedIDs(_ delete: Bool) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let ready = try await coordinator.create(definition(), context: lifecycleContext())
        let ids = ready.state.sessions[0].session.plan.alarms.map(\.id)
        scheduler.configure {
            $0.failCancellation = [ids[1]]
            $0.alarms += [.init(id: uuid(90), state: .scheduled, scope: .foreign),
                          .init(id: uuid(91), state: .scheduled)]
        }
        let partial = try await delete ? coordinator.delete(uuid(1), context: lifecycleContext()) :
            coordinator.disable(uuid(1), context: lifecycleContext())
        #expect(!partial.state.definitions[0].enabled)
        #expect(partial.state.sessions[0].session.remainingCancellationIDs == [ids[1]])
        #expect(scheduler.cancellations == ids)
        #expect(partial.state.operations[0].status == .failed)
        scheduler.configure { $0.failCancellation = [] }
        let recovered = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(recovered.state.definitions.isEmpty == delete)
        #expect(recovered.state.sessions[0].session.phase == .cancelled)
        #expect(scheduler.values.alarms.map(\.id) == [uuid(90), uuid(91)])
        let calls = scheduler.values.calls
        _ = try await delete ? coordinator.delete(uuid(1), context: lifecycleContext()) :
            coordinator.disable(uuid(1), context: lifecycleContext())
        #expect(scheduler.values.calls == calls)
    }

    @Test(arguments: [true, false])
    func cancellationAcknowledgmentFailureRecoversMidDisableOrDelete(_ delete: Bool) async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let ready = try await coordinator.create(definition(), context: lifecycleContext())
        let id = ready.state.sessions[0].session.primaryAlarmID
        await repository.rejectOnce { state in state.sessions.first?.session.cancellation[0] == .succeeded }
        await #expect(throws: PersistenceError.self) {
            if delete { _ = try await coordinator.delete(uuid(1), context: lifecycleContext()) }
            else { _ = try await coordinator.disable(uuid(1), context: lifecycleContext()) }
        }
        let interrupted = try await repositoryState(repository)
        #expect(interrupted.sessions[0].session.cancellation[0] == .inFlight)
        #expect(!interrupted.definitions.isEmpty)
        #expect(!scheduler.values.alarms.contains { $0.id == id })
        let result = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .cancelled)
        #expect(scheduler.cancellations.filter { $0 == id }.count == 1)
        #expect(result.state.definitions.isEmpty == delete)
    }

    @Test func persistedDisableIntentSurvivesFailureBeforeFirstCancellation() async throws {
        let repository = FaultRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        _ = try await coordinator.create(definition(), context: lifecycleContext())
        await repository.rejectOnce { state in state.sessions.first?.session.cancellation.contains(.inFlight) == true }
        await #expect(throws: PersistenceError.self) {
            try await coordinator.disable(uuid(1), context: lifecycleContext())
        }
        #expect(scheduler.cancellations.isEmpty)
        #expect(!(try await repositoryState(repository).definitions[0].enabled))
        let result = try await orchestrator(repository, scheduler).startup(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .cancelled)
        #expect(scheduler.cancellations.count == 5 && scheduler.schedules.count == 5)
    }

    @Test func activeSnapshotSurvivesEditDisableAndDeferredDelete() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let initial = try await coordinator.create(definition(), context: lifecycleContext())
        let wake = initial.state.sessions[0].session.scheduledWakeUpDate
        clock.set(wake)
        let active = try await coordinator.startup(context: lifecycleContext())
        let original = active.state.definitions[0]
        let snapshot = active.state.sessions[0]
        let replacement = try original.replacing(time: AlarmTime(hour: 9, minute: 30), weekdays: [.friday],
            enabled: true, mode: .annoyingOnly, challenges: ChallengeSequence([]), sound: .bundled(.siren), at: wake)
        let edited = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        #expect(edited.state.sessions[0] == snapshot)
        #expect(edited.state.detachedOwnership.count == 1)
        #expect(scheduler.cancellations.isEmpty)
        _ = try await coordinator.disable(uuid(1), context: lifecycleContext())
        let deleted = try await coordinator.delete(uuid(1), context: lifecycleContext())
        #expect(deleted.state.sessions[0] == snapshot)
        #expect(!deleted.state.definitions.isEmpty)
        #expect(deleted.issues.contains(.deletionDeferred(uuid(1))))
        #expect(scheduler.cancellations.count == 1)
        #expect(scheduler.values.alarms.count == 5)
    }

    enum EditCase: CaseIterable, Sendable { case time, weekdays, sound, settings, order, toOrdinary, toChallenge }
    @Test(arguments: EditCase.allCases)
    func schedulingEditsAndModeChangesReplaceOnlyAfterHealthyTarget(_ change: EditCase) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try change == .toChallenge ? lifecycleOrdinary() : definition()
        let initial = try await coordinator.create(original, context: lifecycleContext())
        let oldIDs = Set(try initial.state.ownershipLedger().map(\.alarmKitID))
        let ordinary = change == .toOrdinary
        let replacement = try original.replacing(
            time: AlarmTime(hour: change == .time ? 9 : 6, minute: 30),
            weekdays: change == .weekdays ? [.sunday] : original.weekdays, enabled: true,
            mode: ordinary ? .annoyingOnly : .challengesRequired,
            challenges: ChallengeSequence(ordinary ? [] : change == .settings ?
                [.math(MathConfiguration(requiredCorrect: 2))] : change == .order ?
                Array(configurations().reversed()) : configurations()),
            sound: change == .sound ? .bundled(.siren) : .systemDefault, at: lifecycleNow())
        let result = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        #expect(result.state.definitions == [replacement])
        #expect(result.state.operations[0].status == .ready)
        #expect(Set(scheduler.cancellations) == oldIDs)
        #expect(scheduler.values.alarms.count == (ordinary ? 1 : 5))
        let newRequests = scheduler.schedules.filter { !oldIDs.contains($0.plannedAlarm.id) }
        #expect(newRequests.allSatisfy { $0.selectedSound == replacement.selectedSound })
        if !ordinary {
            #expect(result.state.sessions.last?.session.definitionSnapshot == replacement)
        }
        let calls = scheduler.values.calls
        let firstCancel = try #require(calls.firstIndex { if case .cancel = $0 { true } else { false } })
        #expect(calls[..<firstCancel].count == oldIDs.count + newRequests.count)
        _ = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        #expect(scheduler.values.calls == calls)
    }

    @Test func replacementFailureKeepsOldScheduleAndExplicitRetryRetiresIt() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try definition()
        let initial = try await coordinator.create(original, context: lifecycleContext())
        let oldIDs = Set(initial.state.sessions[0].session.plan.alarms.map(\.id))
        let replacement = try original.replacing(time: AlarmTime(hour: 8, minute: 0), weekdays: original.weekdays,
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: .bundled(.rapidBeeps), at: lifecycleNow())
        scheduler.configure { $0.failSchedule = 7; $0.failAfterEffect = true }
        let failed = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        #expect(failed.state.operations[0].status == .failed)
        #expect(Set(scheduler.values.alarms.map(\.id)) == oldIDs)
        #expect(Set(scheduler.cancellations).isDisjoint(with: oldIDs))
        scheduler.configure { $0.failSchedule = nil }
        let result = try await coordinator.retry(uuid(1), context: lifecycleContext())
        #expect(result.state.operations[0].status == .ready)
        #expect(result.state.sessions.count == 2)
        #expect(Set(scheduler.values.alarms.map(\.id)).isDisjoint(with: oldIDs))
    }

    @Test func oldCleanupFailureDoesNotCancelHealthyReplacementDuringRecovery() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        let original = try lifecycleOrdinary()
        let first = try await coordinator.create(original, context: lifecycleContext())
        let oldID = first.state.detachedOwnership[0].alarmKitID
        let replacement = try original.replacing(time: AlarmTime(hour: 8, minute: 0), weekdays: original.weekdays,
            enabled: true, mode: original.dismissalMode, challenges: original.challengeSequence,
            sound: original.selectedSound, at: lifecycleNow())
        scheduler.configure { $0.failCancellation = [oldID] }
        let failed = try await coordinator.edit(replacement, expecting: original, context: lifecycleContext())
        let newID = try #require(failed.state.operations[0].ordinaryID)
        #expect(failed.state.operations[0].failure == .cancellation)
        scheduler.configure { $0.failCancellation = [] }
        let result = try await coordinator.startup(context: lifecycleContext())
        #expect(result.state.operations[0].status == .ready)
        #expect(scheduler.values.alarms.map(\.id) == [newID])
        #expect(!scheduler.cancellations.contains(newID))
    }
}
