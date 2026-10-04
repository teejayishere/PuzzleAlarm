import Foundation
import Testing
@testable import PuzzleAlarmCore

@Suite("Lifecycle")
struct LifecycleTests {
    @Test func fiveSchedulesPersistIntentBeforeEffectsAndArmOnlyAfterAllAcknowledgments() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { storage in
            storage.afterSchedule = { request in
                let state = try await repositoryState(repository)
                let entry = try #require(try state.ownershipLedger().first { $0.alarmKitID == request.plannedAlarm.id })
                #expect(entry.scheduling == .inFlight)
                #expect(state.sessions[0].session.phase == .scheduling)
                #expect(state.sessions[0].session.completedAt == nil)
            }
        }
        let coordinator = try orchestrator(repository, scheduler)
        let result = try await coordinator.create(definition(), context: lifecycleContext())
        let value = try #require(result.state.sessions.first?.session)
        #expect(value.phase == .armed)
        #expect(scheduler.schedules.map(\.plannedAlarm.id) == value.plan.alarms.map(\.id))
        #expect(scheduler.schedules.map(\.plannedAlarm.date) == [0, 60, 120, 180, 240].map {
            value.scheduledWakeUpDate.addingTimeInterval(Double($0))
        })
        #expect(value.scheduling.allSatisfy { $0 == .scheduled })
        #expect(result.issues.isEmpty)
    }

    @Test(arguments: 1...5)
    func eachScheduleFailureRollsBackIncludingUncertainSuccessfulSideEffect(_ position: Int) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure { $0.failSchedule = position; $0.failAfterEffect = true }
        let result = try await orchestrator(repository, scheduler).create(definition(), context: lifecycleContext())
        let session = try #require(result.state.sessions.first?.session)
        #expect(session.phase == .cancelled)
        #expect(session.completedAt == nil && session.currentChallengeIndex == 0)
        #expect(scheduler.schedules.count == position)
        #expect(scheduler.cancellations == Array(session.plan.alarms.prefix(position)).map(\.id))
        #expect(scheduler.values.alarms.isEmpty)
        #expect(result.state.operations[0].status == .failed)
        #expect(try result.state.ownershipLedger().count == 5)
    }

    @Test func rollbackContinuesAfterCancellationFailureAndRetryUsesOriginalIDs() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        scheduler.configure {
            $0.failSchedule = 4; $0.failAfterEffect = true
            $0.afterSchedule = { request in
                if request.plannedAlarm.ordinal == 0 { scheduler.configure { $0.failCancellation = [request.plannedAlarm.id] } }
            }
        }
        let coordinator = try orchestrator(repository, scheduler)
        let failed = try await coordinator.create(definition(), context: lifecycleContext())
        let value = failed.state.sessions[0].session
        #expect(scheduler.cancellations.count == 4)
        #expect(value.remainingCancellationIDs == [value.primaryAlarmID])
        #expect(value.phase == .schedulingFailed)
        scheduler.configure { $0.failCancellation = []; $0.failSchedule = nil; $0.afterSchedule = nil }
        _ = try await coordinator.startup(context: lifecycleContext())
        let retried = try await coordinator.retry(value.parentAlarmID, context: lifecycleContext())
        #expect(retried.state.sessions.count == 1)
        #expect(retried.state.sessions[0].session.plan == value.plan)
        #expect(retried.state.sessions[0].session.phase == .armed)
        let count = scheduler.schedules.count
        _ = try await coordinator.retry(value.parentAlarmID, context: lifecycleContext())
        #expect(scheduler.schedules.count == count)
    }

    @Test func repeatedEnableAndRecoveryDoNotWriteOrScheduleAgain() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        _ = try await coordinator.create(definition(), context: lifecycleContext())
        let before = try await repository.load()
        for _ in 0..<3 {
            _ = try await coordinator.enable(uuid(1), context: lifecycleContext())
            _ = try await coordinator.scheduleNextOccurrence(uuid(1), context: lifecycleContext())
            _ = try await coordinator.startup(context: lifecycleContext())
        }
        #expect(try await repository.load() == before)
        #expect(scheduler.schedules.count == 5 && scheduler.cancellations.isEmpty)
    }

    @Test(arguments: [true, false])
    func ordinaryMappingHasNoSessionAndOnlyOneID(_ weekly: Bool) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let definition = try lifecycleOrdinary(days: weekly ? [.monday, .friday] : [])
        let result = try await orchestrator(repository, scheduler).create(definition, context: lifecycleContext())
        let request = try #require(scheduler.schedules.first)
        #expect(result.state.sessions.isEmpty)
        #expect(result.state.detachedOwnership.count == 1 && scheduler.schedules.count == 1)
        #expect(request.sessionID == nil && request.parentAlarmID == definition.id)
        #expect(request.schedule == (weekly ? .weekly(definition.time, definition.weekdays) : .fixed(request.plannedAlarm.date)))
        #expect(try roundTrip(result.state) == result.state)
    }

    @Test func schemaOneMigratesAndSchemaTwoCannotLoseOperationJournal() async throws {
        let old = try RepositorySnapshot(state: RepositoryState(definitions: [definition()]))
        let bytes = try mutatedJSON(old) { root in
            root["schemaVersion"] = 1
            var state = root["state"] as! [String: Any]
            state.removeValue(forKey: "operations")
            root["state"] = state
        }
        let repository = InMemoryRepository(storedRepresentation: bytes)
        let restored = try await repositoryState(repository)
        #expect(restored.definitions == old.state.definitions && restored.operations.isEmpty)
        let bad = try mutatedJSON(old) { root in
            var state = root["state"] as! [String: Any]
            state.removeValue(forKey: "operations")
            root["state"] = state
        }
        #expect(throws: PersistenceError.corrupt) { try RepositoryCodec.decode(bad) }
    }
}
