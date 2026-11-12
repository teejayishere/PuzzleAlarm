#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore

// This test adapter stores only observed OS IDs. All lifecycle decisions still
// run through the production coordinator and disk repository. Never on device.
final class SimulatorAlarmScheduler: AlarmScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private let file: URL
    private var ids: Set<UUID>
    private let failScheduling: Bool
    var authorization: AlarmAuthorization { .authorized }

    init(directory: URL, failScheduling: Bool = false) throws {
        file = directory.appendingPathComponent("fake-os-ids.json")
        self.failScheduling = failScheduling
        if FileManager.default.fileExists(atPath: file.path) {
            ids = try JSONDecoder().decode(Set<UUID>.self, from: Data(contentsOf: file))
        } else { ids = [] }
    }

    func requestAuthorization() async throws -> AlarmAuthorization { .authorized }
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        if failScheduling { throw PersistenceError.io("Injected schedule failure") }
        try lock.withLock {
            ids.insert(request.plannedAlarm.id)
            try JSONEncoder().encode(ids).write(to: file, options: .atomic)
        }
        return RegisteredAlarm(id: request.plannedAlarm.id, state: .scheduled)
    }
    func cancel(id: UUID) throws {
        try lock.withLock {
            ids.remove(id)
            try JSONEncoder().encode(ids).write(to: file, options: .atomic)
        }
    }
    func currentAlarms() throws -> [RegisteredAlarm] {
        lock.withLock { ids.map { RegisteredAlarm(id: $0, state: .scheduled) } }
    }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async {
        receive((try? currentAlarms()) ?? [])
    }
}
#endif
