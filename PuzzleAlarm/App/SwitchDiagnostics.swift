import SwiftUI
import Foundation

// Observation only: opt-in, DEBUG Simulator builds. No alternate bindings or commands.
enum SwitchDiagnostics {
    static var enabled: Bool {
        #if DEBUG && targetEnvironment(simulator)
        ProcessInfo.processInfo.arguments.contains("--ui-switch-diagnostics")
        #else
        false
        #endif
    }

    private static let buffer = SwitchDiagnosticBuffer()
    static func record(_ event: String) {
        if enabled { buffer.append(event) }
    }
    static var events: String { buffer.snapshot }
}

private final class SwitchDiagnosticBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [String] = []
    func append(_ event: String) {
        lock.withLock {
            events.append(event)
            events = Array(events.suffix(12))
        }
    }
    var snapshot: String { lock.withLock { events.joined(separator: " | ") } }
}

extension View {
    func switchDiagnosticState(_ state: String) -> some View {
        overlay(alignment: .bottomLeading) {
            if SwitchDiagnostics.enabled {
                Text("Switch diagnostic state").font(.caption2)
                    .accessibilityIdentifier("diagnostic.state")
                    .accessibilityValue(state + " | " + SwitchDiagnostics.events)
                    .allowsHitTesting(false)
            }
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
struct DirectStateSwitchProbe: View {
    @State private var enabled = true
    var body: some View {
        Form {
            Toggle("Direct state", isOn: $enabled)
                .accessibilityIdentifier("diagnostic.direct")
        }
        .switchDiagnosticState("direct.enabled=\(enabled)")
    }
}
#endif
