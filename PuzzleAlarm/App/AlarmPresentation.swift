import Foundation
import PuzzleAlarmCore

enum AlarmPresentation {
    static var wallCalendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    static func time(_ value: AlarmTime) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none; formatter.timeStyle = .short
        formatter.timeZone = wallCalendar.timeZone
        let date = wallCalendar.date(from: DateComponents(year: 2001, month: 1, day: 1,
            hour: value.hour, minute: value.minute))!
        return formatter.string(from: date)
    }
    static let orderedDays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    static func day(_ value: Weekday) -> String {
        switch value {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }
    static func repeatSummary(_ days: Set<Weekday>) -> String {
        if days.isEmpty { return "Once" }
        if days.count == 7 { return "Every day" }
        if days == Set(orderedDays.prefix(5)) { return "Weekdays" }
        if days == [.saturday, .sunday] { return "Weekends" }
        return orderedDays.filter { days.contains($0) }.map { String(day($0).prefix(3)) }.joined(separator: ", ")
    }
    static func challenge(_ kind: ChallengeKind) -> String {
        switch kind { case .math: "Math"; case .memory: "Memory"; case .qr: "QR Code" }
    }
    static func mode(_ mode: DismissalMode) -> String {
        mode == .annoyingOnly ? "Annoying Alarm Only" : "Challenges Required"
    }
    static func challenges(_ definition: AlarmDefinition) -> String {
        definition.dismissalMode == .annoyingOnly ? mode(.annoyingOnly) :
            definition.challengeSequence.items.map { challenge($0.kind) }.joined(separator: " → ")
    }
    static func authorization(_ value: AlarmAuthorization) -> String {
        switch value {
        case .notDetermined: "Not requested"
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .unknown: "Unavailable"
        }
    }
    static func issue(_ value: LifecycleReport.Issue) -> String {
        switch value {
        case .operationFailed(_, .cancellation): "Some alarms still need cleanup. Retry to check them."
        case .operationFailed: "An alarm could not be scheduled. Review it and retry."
        case .activeAlarmMissing: "A wake-up session needs attention. Its challenges remain unfinished."
        case .orphaned: "An alarm was found without its saved details. It has been left unchanged."
        case .stalePresent: "A retired alarm is still reported by the system. Refresh to check its status."
        case .deletionDeferred: "Deletion is waiting for alarm cleanup or an unfinished wake-up session."
        }
    }
    static func error(_ value: any Error) -> String {
        switch value {
        case PersistenceError.corrupt, PersistenceError.duplicateOwnership, PersistenceError.interruptedInitialWrite:
            "Saved alarm data could not be read safely. It has not been reset."
        case PersistenceError.unsupportedSchema:
            "This alarm data needs a newer version of PuzzleAlarm."
        case PersistenceError.io:
            "Alarm storage is unavailable. Try again when storage is accessible."
        case PersistenceError.conflict, LifecycleError.conflictLimit:
            "Alarms changed while saving. Refresh and try again."
        case LifecycleError.superseded:
            "This alarm changed elsewhere. Reload it before saving your changes."
        case LifecycleError.busy:
            "Another alarm update is in progress. Please try again."
        case DomainError.invalidConfiguration:
            "Check the alarm settings and challenge configuration."
        case DomainError.invalidTransition:
            "This alarm cannot be retried in its current state. Refresh and review its settings."
        default:
            "Alarm status could not be confirmed. Your saved data has not been reset. Try refreshing."
        }
    }
}
