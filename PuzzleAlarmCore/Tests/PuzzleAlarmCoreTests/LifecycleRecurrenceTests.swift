import Foundation
import Testing
@testable import PuzzleAlarmCore

func solveForLifecycle(_ repository: any PuzzleAlarmRepository, at date: Date) async throws {
    guard case let .loaded(snapshot, _) = try await repository.load() else { throw FixtureError.invalidDate }
    var state = snapshot.state
    let id = state.sessions.last!.session.id
    try state.updateSession(id, at: date) {
        if $0.phase == .armed { try $0.activate(at: date) }
        while $0.currentChallenge != nil {
            try $0.recordChallengeSuccess(expectedIndex: $0.currentChallengeIndex, at: date)
        }
    }
    _ = try await repository.commit(state, expecting: snapshot.version)
}

@Suite("Lifecycle recurrence")
struct LifecycleRecurrenceTests {
    @Test(arguments: [true, false])
    func completedChallengeSchedulesOneSuccessorOrConsumesOneTime(_ oneTime: Bool) async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let initial = try await coordinator.create(definition(weekdays: oneTime ? [] : [.thursday]), context: lifecycleContext())
        let wake = initial.state.sessions[0].session.scheduledWakeUpDate
        clock.set(wake)
        try await solveForLifecycle(repository, at: wake)
        let completed = try await coordinator.finishConfirmedChallenges(context: lifecycleContext())
        #expect(completed.state.sessions[0].session.phase == .completed)
        #expect(completed.state.sessions.count == (oneTime ? 1 : 2))
        #expect(completed.state.definitions[0].enabled == !oneTime)
        if !oneTime {
            #expect(completed.state.sessions[1].session.scheduledWakeUpDate == (try instant("2026-10-08T06:30:00Z")))
        }
        let saved = try await repository.load()
        _ = try await coordinator.enable(uuid(1), context: lifecycleContext())
        _ = try await coordinator.scheduleNextOccurrence(uuid(1), context: lifecycleContext())
        _ = try await coordinator.finishConfirmedChallenges(context: lifecycleContext())
        #expect(try await repository.load() == saved)
        #expect(scheduler.schedules.count == (oneTime ? 5 : 10))
    }

    @Test func cleanupFailureCannotCompleteOrCreateNextChallengeOccurrence() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let initial = try await coordinator.create(definition(), context: lifecycleContext())
        let session = initial.state.sessions[0].session
        clock.set(session.scheduledWakeUpDate)
        try await solveForLifecycle(repository, at: clock.now())
        scheduler.configure { $0.failCancellation = [session.primaryAlarmID] }
        let partial = try await coordinator.finishConfirmedChallenges(context: lifecycleContext())
        #expect(partial.state.sessions[0].session.phase == .cancellationPartiallyFailed)
        #expect(partial.state.sessions[0].session.completedAt == nil)
        #expect(partial.state.sessions.count == 1 && scheduler.schedules.count == 5)
        scheduler.configure { $0.failCancellation = [] }
        let result = try await coordinator.finishConfirmedChallenges(context: lifecycleContext())
        #expect(result.state.sessions[0].session.phase == .completed)
        #expect(result.state.sessions.count == 2)
    }

    @Test func ordinaryOneTimeAbsenceAfterDueDisablesInsteadOfRearming() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let initial = try await coordinator.create(lifecycleOrdinary(days: []), context: lifecycleContext())
        clock.set(initial.state.detachedOwnership[0].intendedDate)
        scheduler.configure { $0.alarms = [] }
        let retired = try await coordinator.startup(context: lifecycleContext())
        #expect(!retired.state.definitions[0].enabled && retired.state.operations[0].oneTimeConsumed)
        _ = try await coordinator.enable(uuid(1), context: lifecycleContext())
        _ = try await coordinator.startup(context: lifecycleContext())
        #expect(scheduler.schedules.count == 1 && scheduler.cancellations.isEmpty)
    }

    @Test func disabledOrRetiredOneTimeChallengeCannotRearm() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let coordinator = try orchestrator(repository, scheduler)
        _ = try await coordinator.create(definition(weekdays: []), context: lifecycleContext())
        _ = try await coordinator.disable(uuid(1), context: lifecycleContext())
        _ = try await coordinator.enable(uuid(1), context: lifecycleContext())
        let result = try await coordinator.scheduleNextOccurrence(uuid(1), context: lifecycleContext())
        #expect(!result.state.definitions[0].enabled)
        #expect(result.state.sessions.count == 1 && scheduler.schedules.count == 5)
    }

    @Test func nextOccurrenceUsesNewTimezoneWithoutMutatingCompletedSnapshot() async throws {
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let clock = TestClock(try lifecycleNow())
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock.now)
        let initial = try await coordinator.create(definition(weekdays: Set(Weekday.allCases)), context: lifecycleContext())
        let wake = initial.state.sessions[0].session.scheduledWakeUpDate
        clock.set(wake)
        try await solveForLifecycle(repository, at: wake)
        let changed = try ScheduleContext(timeZoneIdentifier: "Asia/Kathmandu")
        let result = try await coordinator.finishConfirmedChallenges(context: changed)
        #expect(result.state.sessions[0].session.context == (try lifecycleContext()))
        #expect(result.state.sessions[1].session.context == changed)
        #expect(result.state.sessions[1].session.scheduledWakeUpDate == (try instant("2026-10-02T00:45:00Z")))
    }

    struct Boundary: Sendable {
        let zone: String; let after: String; let expected: String
        let hour: Int; let minute: Int; let days: Set<Weekday>
    }
    static let boundaries: [Boundary] = [
        .init(zone: "UTC", after: "2026-10-05T06:29:59Z", expected: "2026-10-05T06:30:00Z", hour: 6, minute: 30, days: [.monday]),
        .init(zone: "UTC", after: "2026-10-05T06:30:00Z", expected: "2026-10-12T06:30:00Z", hour: 6, minute: 30, days: [.monday]),
        .init(zone: "UTC", after: "2026-10-02T07:00:00Z", expected: "2026-10-05T06:30:00Z", hour: 6, minute: 30, days: [.monday]),
        .init(zone: "UTC", after: "2026-12-31T23:59:59Z", expected: "2027-01-01T00:00:00Z", hour: 0, minute: 0, days: [.friday]),
        .init(zone: "America/Chicago", after: "2026-03-08T06:00:00Z", expected: "2026-03-08T08:00:00Z", hour: 2, minute: 30, days: [.sunday]),
        .init(zone: "America/Chicago", after: "2026-11-01T06:45:00Z", expected: "2026-11-08T07:30:00Z", hour: 1, minute: 30, days: [.sunday]),
        .init(zone: "Pacific/Apia", after: "2011-12-23T17:00:00Z", expected: "2012-01-05T16:30:00Z", hour: 6, minute: 30, days: [.friday])
    ]
    @Test(arguments: boundaries)
    func orchestrationUsesEstablishedCalendarContract(_ item: Boundary) async throws {
        let now = try instant(item.after)
        let value = try AlarmDefinition(id: uuid(1), time: AlarmTime(hour: item.hour, minute: item.minute),
            weekdays: item.days, enabled: true, dismissalMode: .challengesRequired,
            challengeSequence: ChallengeSequence(configurations()), selectedSound: .systemDefault,
            createdAt: now.addingTimeInterval(-86400), updatedAt: now.addingTimeInterval(-86400))
        let repository = InMemoryRepository()
        let scheduler = FakeAlarmScheduler()
        let result = try await orchestrator(repository, scheduler, now: now).create(value,
            context: ScheduleContext(timeZoneIdentifier: item.zone))
        #expect(result.state.sessions[0].session.scheduledWakeUpDate == (try instant(item.expected)))
        #expect(scheduler.schedules.count == 5)
    }
}
