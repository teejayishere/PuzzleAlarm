import Foundation
import PuzzleAlarmCore

extension AlarmStore {
    func operation(_ alarm: AlarmDefinition) -> LifecycleOperation? {
        state?.operations.first { $0.configuration.id == alarm.id }
    }
    func status(_ alarm: AlarmDefinition) -> String {
        guard let state else { return "Status unavailable" }
        let active = state.sessions.contains {
            $0.session.parentAlarmID == alarm.id &&
            [.active, .completing, .cancellationPartiallyFailed].contains($0.session.phase)
        }
        if active { return "Wake-up session unfinished" }
        if let operation = operation(alarm) {
            if operation.action == .delete { return "Cleanup pending" }
            if operation.status == .failed {
                return operation.failure == .cancellation ? "Cleanup pending" : "Needs attention"
            }
            if operation.status == .pending { return isBusy ? "Scheduling" : "Needs attention" }
        }
        if !alarm.enabled { return "Off" }
        if authorization != .authorized { return "Alarm access needed" }
        if !confirmed { return "Status unconfirmed" }
        guard let operation = operation(alarm), operation.status == .ready,
              operation.configuration == alarm else { return "Needs attention" }
        if let id = operation.sessionID {
            guard state.sessions.contains(where: { $0.session.id == id && $0.session.phase == .armed }) else {
                return "Needs attention"
            }
        } else if let id = operation.ordinaryID {
            guard state.detachedOwnership.contains(where: {
                $0.alarmKitID == id && $0.scheduling == .scheduled && $0.cancellation == .notRequested
            }) else { return "Needs attention" }
        } else { return "Needs attention" }
        return "On"
    }
    func needsAttention(_ alarm: AlarmDefinition) -> Bool {
        !["On", "Off"].contains(status(alarm))
    }
    func canRetry(_ alarm: AlarmDefinition) -> Bool {
        guard let operation = operation(alarm) else { return false }
        return operation.status == .failed && !operation.oneTimeConsumed
    }
    func nextOccurrence(_ alarm: AlarmDefinition) -> Date? {
        guard status(alarm) == "On", let operation = operation(alarm), let state else { return nil }
        if let id = operation.sessionID {
            let date = state.sessions.first { $0.session.id == id }?.session.scheduledWakeUpDate
            return date.flatMap { $0 > displayNow() ? $0 : nil }
        }
        if alarm.weekdays.isEmpty, let id = operation.ordinaryID {
            return state.detachedOwnership.first { $0.alarmKitID == id && $0.intendedDate > displayNow() }?.intendedDate
        }
        // Ordinary weekly recurrence is calculated by the existing domain API.
        return try? OccurrenceCalculator.next(for: alarm, after: displayNow(), context: displayContext())
    }
    func displayNow() -> Date { currentDate() }
}
