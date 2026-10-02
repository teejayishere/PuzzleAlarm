import Foundation
import Testing
@testable import PuzzleAlarmCore

private struct ScheduleCase: Sendable {
    let zone: String
    let after: String
    let expected: String
    let hour: Int
    let minute: Int
    let weekdays: Set<Weekday>
}

private let scheduleCases: [ScheduleCase] = [
    .init(zone: "UTC", after: "2026-10-02T07:00:00Z", expected: "2026-10-05T06:30:00Z",
          hour: 6, minute: 30, weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]),
    .init(zone: "UTC", after: "2026-10-02T07:00:00Z", expected: "2026-10-03T06:30:00Z",
          hour: 6, minute: 30, weekdays: [.saturday, .sunday]),
    .init(zone: "UTC", after: "2026-10-05T06:30:00Z", expected: "2026-10-12T06:30:00Z",
          hour: 6, minute: 30, weekdays: [.monday]),
    .init(zone: "UTC", after: "2026-10-05T06:29:59Z", expected: "2026-10-05T06:30:00Z",
          hour: 6, minute: 30, weekdays: [.monday]),
    .init(zone: "UTC", after: "2026-10-05T00:00:00Z", expected: "2026-10-06T00:00:00Z",
          hour: 0, minute: 0, weekdays: []),
    .init(zone: "UTC", after: "2026-10-31T23:59:00Z", expected: "2026-11-01T00:00:00Z",
          hour: 0, minute: 0, weekdays: Set(Weekday.allCases)),
    .init(zone: "UTC", after: "2026-12-31T23:59:59Z", expected: "2027-01-01T00:00:00Z",
          hour: 0, minute: 0, weekdays: []),
    .init(zone: "UTC", after: "2028-02-28T23:59:00Z", expected: "2028-02-29T23:59:00Z",
          hour: 23, minute: 59, weekdays: []),
    .init(zone: "America/Chicago", after: "2026-03-08T06:00:00Z", expected: "2026-03-08T08:00:00Z",
          hour: 2, minute: 30, weekdays: [.sunday]),
    .init(zone: "America/Chicago", after: "2026-11-01T05:00:00Z", expected: "2026-11-01T06:30:00Z",
          hour: 1, minute: 30, weekdays: [.sunday]),
    .init(zone: "America/Chicago", after: "2026-11-01T06:45:00Z", expected: "2026-11-08T07:30:00Z",
          hour: 1, minute: 30, weekdays: [.sunday]),
    .init(zone: "America/Chicago", after: "2026-11-01T06:45:00Z", expected: "2026-11-02T07:30:00Z",
          hour: 1, minute: 30, weekdays: []),
    .init(zone: "Asia/Kathmandu", after: "2026-10-01T00:00:00Z", expected: "2026-10-01T00:45:00Z",
          hour: 6, minute: 30, weekdays: [])
]

@Test(arguments: scheduleCases)
private func nextOccurrenceHonorsCalendarBoundaries(_ item: ScheduleCase) throws {
    let alarm = try definition(hour: item.hour, minute: item.minute, weekdays: item.weekdays)
    let date = try OccurrenceCalculator.next(
        for: alarm, after: instant(item.after), context: ScheduleContext(timeZoneIdentifier: item.zone)
    )
    #expect(date == (try instant(item.expected)))
}

@Test func disabledAlarmHasNoNextOccurrenceAndCalendarIsExplicit() throws {
    let alarm = try definition(enabled: false)
    #expect(try OccurrenceCalculator.next(
        for: alarm, after: instant("2026-10-01T00:00:00Z"),
        context: ScheduleContext(timeZoneIdentifier: "UTC")
    ) == nil)
    #expect(throws: DomainError.self) { try ScheduleContext(timeZoneIdentifier: "Not/AZone") }
    #expect(throws: DomainError.self) {
        try ScheduleContext(timeZoneIdentifier: "UTC", calendarIdentifier: "unsupported")
    }
    let context = try ScheduleContext(timeZoneIdentifier: "America/Chicago")
    #expect(try roundTrip(context) == context)
}

@Test func weeklyScheduleIsStrictlyFutureAcrossManyDays() throws {
    let context = try ScheduleContext(timeZoneIdentifier: "America/Chicago")
    let calendar = try context.calendar()
    let base = try instant("2026-01-01T00:00:00Z")
    for weekday in Weekday.allCases {
        let alarm = try definition(weekdays: [weekday])
        for index in 0..<370 {
            let after = base.addingTimeInterval(Double(index) * 86400)
            let next = try #require(try OccurrenceCalculator.next(for: alarm, after: after, context: context))
            #expect(next > after)
            #expect(next.timeIntervalSince(after) <= 8 * 86400)
            #expect(calendar.component(.weekday, from: next) == weekday.rawValue)
            #expect(calendar.component(.hour, from: next) == 6)
            #expect(calendar.component(.minute, from: next) == 30)
        }
    }
}

@Test func backupPlanHasExactlyFiveIndependentDatesAndStableIDs() throws {
    let ids = (10...14).map { uuid(UInt8($0)) }
    for time in [-1_000_000.0, 0, 1_000_000, 1_796_000_000] {
        let date = Date(timeIntervalSince1970: time)
        let plan = try BackupPlan(at: date, ids: ids)
        #expect(plan.alarms.map(\.date) == [0, 60, 120, 180, 240].map { date.addingTimeInterval(Double($0)) })
        #expect(plan.alarms.map(\.id) == ids)
        #expect(plan.alarms.map(\.ordinal) == [0, 1, 2, 3, 4])
        #expect(try roundTrip(plan) == plan)
    }
    #expect(throws: DomainError.self) { try BackupPlan(at: .distantFuture, ids: [uuid(1)]) }
    #expect(throws: DomainError.self) { try BackupPlan(at: .distantFuture, ids: Array(repeating: uuid(1), count: 5)) }
    #expect(throws: DomainError.self) { try BackupPlan(at: Date(timeIntervalSince1970: .nan), ids: ids) }
    let plan = try BackupPlan(at: instant("2026-01-01T23:59:00Z"), ids: ids)
    #expect(plan.alarms.last?.date == (try instant("2026-01-02T00:03:00Z")))
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(BackupPlan.self, from: mutatedJSON(plan) { $0["alarms"] = [] })
    }
}
