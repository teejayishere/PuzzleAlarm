import Foundation
import PuzzleAlarmCore

enum AlarmManagementCommand: Sendable {
    case refresh
    case create(AlarmDefinition)
    case edit(AlarmDefinition, original: AlarmDefinition)
    case enable(UUID), disable(UUID), delete(UUID), retry(UUID)
}

protocol AlarmManagementService: Sendable {
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport
}

enum ManagementError: Error { case authorizationDenied }

actor LifecycleAlarmManagementService: AlarmManagementService {
    private let coordinator: AlarmLifecycleCoordinator
    private let scheduler: any AlarmScheduling
    private let context: @Sendable () throws -> ScheduleContext

    init(repository: any PuzzleAlarmRepository, scheduler: any AlarmScheduling,
         clock: @escaping @Sendable () -> Date = { Date() },
         context: @escaping @Sendable () throws -> ScheduleContext = {
             try ScheduleContext(timeZoneIdentifier: TimeZone.current.identifier)
         }) {
        coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock)
        self.scheduler = scheduler
        self.context = context
    }

    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport {
        SwitchDiagnostics.record("service.enter \(command)")
        // Only explicit user commands can prompt. Refresh never requests permission.
        let needsAuthorization: Bool
        switch command {
        case let .create(value), let .edit(value, _): needsAuthorization = value.enabled
        case .enable, .retry: needsAuthorization = true
        default: needsAuthorization = false
        }
        if needsAuthorization {
            var authorization = scheduler.authorization
            if authorization == .notDetermined { authorization = try await scheduler.requestAuthorization() }
            guard authorization == .authorized else { throw ManagementError.authorizationDenied }
        }
        let context = try context()
        switch command {
        case .refresh: return try await coordinator.startup(context: context)
        case let .create(value): return try await coordinator.create(value, context: context)
        case let .edit(value, original):
            return try await coordinator.edit(value, expecting: original, context: context)
        case let .enable(id): return try await coordinator.enable(id, context: context)
        case let .disable(id): return try await coordinator.disable(id, context: context)
        case let .delete(id): return try await coordinator.delete(id, context: context)
        case let .retry(id): return try await coordinator.retry(id, context: context)
        }
    }
}
