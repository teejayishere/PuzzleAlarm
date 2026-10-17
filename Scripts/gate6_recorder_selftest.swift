import Foundation

@main
struct RecorderSelfTest {
    @MainActor static func main() {
        let root = CommandLine.arguments[1]
        let normal = Gate6Recorder(path: root + "/normal.bin", capacity: 4)
        normal.record("probe attached window=selftest")
        normal.record("unicode π ✓")
        let full = Gate6Recorder(path: root + "/overflow.bin", capacity: 2, failStop: false)
        full.record("probe attached window=selftest")
        full.record("must overflow")
        let truncated = Gate6Recorder(path: root + "/truncated.bin", capacity: 4, failStop: false)
        truncated.record("probe attached window=selftest")
        truncated.record(String(repeating: "x", count: 2000))
        precondition(normal.get(48) == 3 && full.get(56) == 1 && truncated.get(64) == 1)
    }
}
