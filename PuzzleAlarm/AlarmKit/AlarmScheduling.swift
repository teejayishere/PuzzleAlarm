import AlarmKit
import Foundation

enum AlarmAuthorization: Equatable, Sendable {
    case notDetermined, authorized, denied, unknown

    init(_ state: AlarmManager.AuthorizationState) {
        switch state {
        case .notDetermined: self = .notDetermined
        case .authorized: self = .authorized
        case .denied: self = .denied
        @unknown default: self = .unknown
        }
    }
}

struct RegisteredAlarm: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case scheduled, alerting, countdown, paused, unknown
    }
    let id: UUID
    let state: State

    init(id: UUID, state: State) {
        self.id = id
        self.state = state
    }

    init(_ alarm: Alarm) {
        id = alarm.id
        switch alarm.state {
        case .scheduled: state = .scheduled
        case .alerting: state = .alerting
        case .countdown: state = .countdown
        case .paused: state = .paused
        @unknown default: state = .unknown
        }
    }
}

// This boundary lives in the iOS layer. Core still has no platform dependencies.
protocol AlarmScheduling: Sendable {
    var authorization: AlarmAuthorization { get }
    func requestAuthorization() async throws -> AlarmAuthorization
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm
    func cancel(id: UUID) throws
    func currentAlarms() throws -> [RegisteredAlarm]
    // Runs in the caller's task; no hidden/unbounded producer Task is created.
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async
}
