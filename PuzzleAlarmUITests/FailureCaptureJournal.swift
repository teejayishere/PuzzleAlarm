import Foundation

// Local state only. Never queries XCTest or the application from an issue callback.
final class FailureCaptureJournal: @unchecked Sendable {
    struct Snapshot: Sendable {
        var phase = "not-launched"
        var lastCompletedTransition = "none"
        var issues: [String] = []
        var pending: [String] = []
        var collecting = false
        var started = 0
        var completed = 0
        var nestedSkipped = 0
        var queries = 0
        var omissions: [String] = []
    }

    private let lock = NSLock()
    private var value = Snapshot()

    var snapshot: Snapshot { lock.withLock { value } }
    func setPhase(_ phase: String) { lock.withLock { value.phase = phase } }
    func completePhase(_ phase: String) {
        lock.withLock { value.lastCompletedTransition = value.phase; value.phase = phase }
    }
    func noteIssue(_ description: String) {
        lock.withLock { value.issues.append(description); value.pending.append(description) }
    }
    func takePending() -> [String] {
        lock.withLock {
            let pending = value.pending
            value.pending.removeAll()
            return pending
        }
    }
    func begin() -> Bool {
        lock.withLock {
            guard !value.collecting else { value.nestedSkipped += 1; return false }
            value.collecting = true; value.started += 1
            return true
        }
    }
    func finish() { lock.withLock { value.collecting = false; value.completed += 1 } }
    func noteQuery() { lock.withLock { value.queries += 1 } }
    func omit(_ reason: String) { lock.withLock { value.omissions.append(reason) } }
}
