import AlarmKit
import Foundation
import PuzzleAlarmCore

extension AlarmAuthorization {
    init(_ state: AlarmManager.AuthorizationState) {
        switch state {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .denied: self = .denied
        @unknown default: self = .unknown
        }
    }
}

extension RegisteredAlarm {
    init(_ alarm: Alarm) {
        let state: State
        switch alarm.state {
        case .scheduled: state = .scheduled
        case .alerting: state = .alerting
        case .countdown: state = .countdown
        case .paused: state = .paused
        @unknown default: state = .unknown
        }
        self.init(id: alarm.id, state: state)
    }
}
