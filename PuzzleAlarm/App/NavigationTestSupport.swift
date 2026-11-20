import SwiftUI

#if DEBUG && targetEnvironment(simulator)
import CryptoKit
import PuzzleAlarmCore

// Opt-in observation of isolated fixtures only. Never prepares or mutates storage.
private enum NavigationTestAudit {
    static func snapshot() -> String {
        do {
            let environment = ProcessInfo.processInfo.environment
            guard let raw = environment["PUZZLEALARM_TEST_NAMESPACE"],
                  let namespace = UUID(uuidString: raw) else { return "audit-error:namespace" }
            let directory = try DiskRepository.applicationSupportDirectory()
                .appendingPathComponent("Stage6UITests", isDirectory: true)
                .appendingPathComponent(namespace.uuidString, isDirectory: true)
            func digest(_ name: String, required: Bool) throws -> String {
                let file = directory.appendingPathComponent(name)
                if !required && !FileManager.default.fileExists(atPath: file.path) { return "missing" }
                return SHA256.hash(data: try Data(contentsOf: file)).map { String(format: "%02x", $0) }.joined()
            }
            return "disk=\(try digest("state.json", required: true)); scheduler=\(try digest("fake-os-ids.json", required: false))"
        } catch { return "audit-error:\(error)" }
    }
}

// Deterministic loading fixture: stays suspended until the test terminates the app.
// No clock delay, repository write, scheduler call or alternate product state.
actor SimulatorHeldLoadService: AlarmManagementService {
    private var pending: CheckedContinuation<LifecycleReport, any Error>?
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport {
        try await withCheckedThrowingContinuation { pending = $0 }
    }
}
#endif

extension View {
    func navigationTestState(_ state: String, context: String) -> some View {
        overlay(alignment: .bottomLeading) {
            #if DEBUG && targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-navigation-audit") {
                Text("Navigation test state").font(.caption2)
                    .accessibilityIdentifier("diagnostic.navigation.\(context)")
                    .accessibilityValue(state + " | " + NavigationTestAudit.snapshot() + " | " + SwitchDiagnostics.events)
                    .allowsHitTesting(false)
            }
            #endif
        }
    }
}
