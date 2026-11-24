#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore

// Only simulator composition exposes time travel. Domain scheduling and challenge
// transitions still use one shared clock and the ordinary lifecycle coordinator.
final class SimulatorClock: @unchecked Sendable {
    private let lock = NSLock()
    private var offset: TimeInterval = 0
    private let file: URL?

    init() { file = nil }

    init(directory: URL) throws {
        let path = directory.appendingPathComponent("simulator-clock.json")
        file = path
        if FileManager.default.fileExists(atPath: path.path) {
            offset = try JSONDecoder().decode(TimeInterval.self, from: Data(contentsOf: path))
            guard offset.isFinite && offset >= 0 && offset < Date.distantFuture.timeIntervalSinceNow else {
                throw PersistenceError.corrupt
            }
        }
    }

    func now() -> Date { lock.withLock { Date().addingTimeInterval(offset) } }
    func advance(to date: Date) throws {
        try lock.withLock {
            let updated = max(offset, date.timeIntervalSinceNow)
            if let file { try JSONEncoder().encode(updated).write(to: file, options: .atomic) }
            offset = updated
        }
    }
}
#endif
