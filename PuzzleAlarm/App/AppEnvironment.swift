import Foundation
import Observation
import PuzzleAlarmCore

@MainActor @Observable
final class AppEnvironment {
    // App Intents and SwiftUI use the same process-local lifecycle owner, including
    // when perform() arrives before the first scene is constructed.
    static let live = make()
    let store: AlarmStore?
    private(set) var failure: String?
    private(set) var ready = false
    @ObservationIgnored private var startup: Task<Void, Never>?
    @ObservationIgnored private let prepare: () async throws -> Void

    init(store: AlarmStore?, failure: String? = nil, prepare: @escaping () async throws -> Void = {}) {
        self.store = store; self.failure = failure; self.prepare = prepare
    }
    static func make() -> AppEnvironment {
        do {
            #if DEBUG
            let environment = ProcessInfo.processInfo.environment
            if environment["PUZZLE_UI_TEST"] == "1" || environment["XCTestConfigurationFilePath"] != nil {
                return try UITestEnvironment.make(environment)
            }
            #endif
            let repository = DiskRepository(directory: try DiskRepository.applicationSupportDirectory())
            let scheduler = AlarmManagerService()
            return AppEnvironment(store: AlarmStore(repository: repository, scheduler: scheduler))
        } catch { return AppEnvironment(store: nil, failure: AlarmFormatting.error(error)) }
    }
    func start() async {
        if let startup { await startup.value; return }
        let task = Task { @MainActor in
            do {
                try await prepare()
                await store?.refresh()
                ready = true
            } catch { failure = AlarmFormatting.error(error) }
        }
        startup = task
        await task.value
    }
    func foreground() async {
        await start()
        if ready { await store?.refresh() }
    }
    func openOccurrence(_ value: String) async {
        guard UUID(uuidString: value) != nil else { return }
        // Stale/unknown/completed IDs cannot activate a session. The durable due
        // obligation wins even if the system action refers to another occurrence.
        await foreground()
    }
}
