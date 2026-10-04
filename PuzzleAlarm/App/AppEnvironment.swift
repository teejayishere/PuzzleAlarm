import Foundation
import Observation
import PuzzleAlarmCore

@MainActor @Observable
final class AppEnvironment {
    let store: AlarmStore?
    private(set) var failure: String?
    private(set) var ready = false
    private var started = false
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
        guard !started else { return }
        started = true
        do {
            try await prepare()
            await store?.refresh()
            ready = true
        } catch { failure = AlarmFormatting.error(error) }
    }
}
