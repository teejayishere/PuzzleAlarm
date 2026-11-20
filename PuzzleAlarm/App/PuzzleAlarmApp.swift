import SwiftUI
import PuzzleAlarmCore

@main
struct PuzzleAlarmApp: App {
    @StateObject private var model: AlarmListModel

    init() {
        do {
            var directory = try DiskRepository.applicationSupportDirectory()
            var scheduler: any AlarmScheduling = AlarmManagerService()
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                directory = try SimulatorUITestFixture.prepare(root: directory,
                    arguments: ProcessInfo.processInfo.arguments,
                    environment: ProcessInfo.processInfo.environment)
                scheduler = try SimulatorAlarmScheduler(directory: directory,
                    failScheduling: ProcessInfo.processInfo.arguments.contains("--ui-schedule-failure"))
            }
            #endif
            let repository = DiskRepository(directory: directory)
            let base = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler)
            let service: any AlarmManagementService
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") &&
                ProcessInfo.processInfo.arguments.contains("--ui-hold-load") {
                service = SimulatorHeldLoadService()
            } else { service = base }
            #else
            service = base
            #endif
            _model = StateObject(wrappedValue: AlarmListModel(service: service, repository: repository))
        } catch {
            // Never replace unreadable disk state with a writable empty repository.
            let service = UnavailableAlarmManagementService()
            _model = StateObject(wrappedValue: AlarmListModel(service: service, repository: service))
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-switch-probe") {
                DirectStateSwitchProbe()
            } else {
                ContentView(model: model)
            }
            #else
            ContentView(model: model)
            #endif
        }
    }
}

private struct UnavailableAlarmManagementService: AlarmManagementService, PuzzleAlarmRepository {
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport { throw PersistenceError.io("Storage unavailable") }
    func load() async throws -> RepositoryRead { throw PersistenceError.io("Storage unavailable") }
    func commit(_ state: RepositoryState, expecting: RepositoryVersion) async throws -> RepositorySnapshot {
        throw PersistenceError.io("Storage unavailable")
    }
}
