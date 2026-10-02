import Foundation

public struct ScheduleContext: Codable, Equatable, Sendable {
    public let timeZoneIdentifier: String
    public let calendarIdentifier: String

    public init(timeZoneIdentifier: String, calendarIdentifier: String = "gregorian") throws {
        try require(TimeZone(identifier: timeZoneIdentifier) != nil, "Unknown timezone")
        try require(calendarIdentifier == "gregorian", "Unsupported calendar")
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calendarIdentifier = calendarIdentifier
    }

    public func calendar() throws -> Calendar {
        guard let zone = TimeZone(identifier: timeZoneIdentifier) else {
            throw DomainError.invalidConfiguration("Timezone unavailable")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private enum CodingKeys: String, CodingKey { case timeZoneIdentifier, calendarIdentifier }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(timeZoneIdentifier: c.decode(String.self, forKey: .timeZoneIdentifier),
                      calendarIdentifier: c.decode(String.self, forKey: .calendarIdentifier))
    }
}

public enum OccurrenceCalculator {
    // Strictly after the supplied instant. A skipped DST time moves to the first
    // valid time after the gap; repeated times use only the first occurrence.
    public static func next(
        for alarm: AlarmDefinition, after now: Date, context: ScheduleContext
    ) throws -> Date? {
        try validateDate(now)
        guard alarm.enabled else { return nil }
        let calendar = try context.calendar()
        let today = calendar.startOfDay(for: now)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let weekday = Weekday(rawValue: calendar.component(.weekday, from: day))
            else { throw DomainError.invalidConfiguration("Calendar calculation failed") }
            guard alarm.weekdays.isEmpty || alarm.weekdays.contains(weekday) else { continue }
            let components = DateComponents(hour: alarm.time.hour, minute: alarm.time.minute, second: 0)
            if let candidate = calendar.nextDate(
                after: day.addingTimeInterval(-1), matching: components,
                matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward
            ), calendar.isDate(candidate, inSameDayAs: day), candidate > now {
                return candidate
            }
        }
        throw DomainError.invalidConfiguration("No occurrence found in calendar horizon")
    }
}

public struct PlannedAlarm: Codable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    // 0 is primary; 1...4 are backup ordinals.
    public let ordinal: Int
}

public struct BackupPlan: Codable, Equatable, Sendable {
    public let alarms: [PlannedAlarm]

    public init(at date: Date, ids: [UUID]) throws {
        try validateDate(date)
        try require(ids.count == 5 && Set(ids).count == 5, "Plan needs five unique IDs")
        alarms = ids.enumerated().map { index, id in
            PlannedAlarm(id: id, date: date.addingTimeInterval(Double(index) * 60), ordinal: index)
        }
        try validate()
    }

    func validate() throws {
        try require(alarms.count == 5 && Set(alarms.map(\.id)).count == 5, "Invalid plan IDs")
        guard let primary = alarms.first else { throw DomainError.invalidConfiguration("Missing primary") }
        for (index, alarm) in alarms.enumerated() {
            try validateDate(alarm.date)
            try require(alarm.ordinal == index, "Invalid backup ordinal")
            try require(alarm.date == primary.date.addingTimeInterval(Double(index) * 60), "Invalid backup date")
        }
    }

    private enum CodingKeys: String, CodingKey { case alarms }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        alarms = try c.decode([PlannedAlarm].self, forKey: .alarms)
        try validate()
    }
}
