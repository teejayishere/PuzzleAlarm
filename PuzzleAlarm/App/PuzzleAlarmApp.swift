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
                directory = directory.appendingPathComponent("Stage6UITests", isDirectory: true)
                if ProcessInfo.processInfo.arguments.contains("--ui-reset"),
                   FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                scheduler = try SimulatorAlarmScheduler(directory: directory,
                    failScheduling: ProcessInfo.processInfo.arguments.contains("--ui-schedule-failure"))
            }
            #endif
            let repository = DiskRepository(directory: directory)
            let service = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler)
            _model = StateObject(wrappedValue: AlarmListModel(service: service, repository: repository))
        } catch {
            // Never replace unreadable disk state with a writable empty repository.
            let service = UnavailableAlarmManagementService()
            _model = StateObject(wrappedValue: AlarmListModel(service: service, repository: service))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
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
