import SwiftUI
import PuzzleAlarmCore

@main
struct PuzzleAlarmApp: App {
    @StateObject private var model: AlarmListModel
    @StateObject private var challenges: ChallengeModel

    init() {
        do {
            var directory = try DiskRepository.applicationSupportDirectory()
            #if APPETIZE_PREVIEW && DEBUG && targetEnvironment(simulator)
            directory = directory.appendingPathComponent("AppetizePreview", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var scheduler: any AlarmScheduling = try SimulatorAlarmScheduler(directory: directory)
            #else
            var scheduler: any AlarmScheduling = AlarmManagerService()
            #endif
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
            let clock: @Sendable () -> Date
            let advance: (@Sendable (Date) throws -> Void)?
            #if DEBUG && targetEnvironment(simulator)
            let simulatorClock = try SimulatorClock(directory: directory)
            clock = { simulatorClock.now() }
            #if APPETIZE_PREVIEW
            advance = { try simulatorClock.advance(to: $0) }
            #else
            advance = ProcessInfo.processInfo.arguments.contains("--ui-testing")
                ? { try simulatorClock.advance(to: $0) } : nil
            #endif
            #else
            clock = { Date() }; advance = nil
            #endif
            let base = LifecycleAlarmManagementService(repository: repository, scheduler: scheduler, clock: clock)
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
            _challenges = StateObject(wrappedValue: ChallengeModel(repository: repository,
                service: service, clock: clock, advancePreviewClock: advance))
        } catch {
            // Never replace unreadable disk state with a writable empty repository.
            let service = UnavailableAlarmManagementService()
            _model = StateObject(wrappedValue: AlarmListModel(service: service, repository: service))
            _challenges = StateObject(wrappedValue: ChallengeModel(repository: service, service: service))
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-switch-probe") {
                DirectStateSwitchProbe()
            } else {
                ContentView(model: model, challenges: challenges)
            }
            #else
            ContentView(model: model, challenges: challenges)
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
