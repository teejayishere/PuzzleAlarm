import SwiftUI
import UIKit

/// Public native control with an explicit valueChanged boundary. The coordinator
/// forwards input only; durable state and command completion remain store-owned.
@MainActor
struct NativeAlarmSwitch: UIViewRepresentable {
    let binding: Binding<Bool>
    let enabled: Bool
    let identifier: String

    @MainActor final class Coordinator: NSObject {
        var binding: Binding<Bool>
        init(binding: Binding<Bool>) { self.binding = binding }

        @objc func changed(_ control: UISwitch) {
            #if DEBUG
            UITestEnvironment.traceToggle("native control=\(control.isOn) enabled=\(control.isEnabled)")
            #endif
            guard control.isEnabled else { return }
            binding.wrappedValue = control.isOn
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(binding: binding) }

    static func makeControl(coordinator: Coordinator) -> UISwitch {
        #if DEBUG
        let control: UISwitch = UITestEnvironment.tracingToggle ? AlarmInputTraceSwitch() : UISwitch()
        #else
        let control = UISwitch()
        #endif
        control.addTarget(coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        #if DEBUG
        UITestEnvironment.traceToggle("control make id=\(ObjectIdentifier(control)) target=\(ObjectIdentifier(coordinator)) targets=\(control.allTargets.count)")
        #endif
        return control
    }

    static func update(_ control: UISwitch, coordinator: Coordinator, binding: Binding<Bool>,
                       enabled: Bool, identifier: String) {
        coordinator.binding = binding
        // Programmatic reconciliation must not synthesize a user input event.
        control.setOn(binding.wrappedValue, animated: false)
        control.isEnabled = enabled
        control.accessibilityIdentifier = identifier
        control.accessibilityLabel = "Alarm enabled"
        #if DEBUG
        UITestEnvironment.traceToggle("control update id=\(ObjectIdentifier(control)) target=\(ObjectIdentifier(coordinator)) targets=\(control.allTargets.count) enabled=\(enabled) on=\(control.isOn) window=\(control.window != nil)")
        #endif
    }

    func makeUIView(context: Context) -> UISwitch { Self.makeControl(coordinator: context.coordinator) }

    func updateUIView(_ control: UISwitch, context: Context) {
        Self.update(control, coordinator: context.coordinator, binding: binding,
                    enabled: enabled && context.environment.isEnabled, identifier: identifier)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISwitch, context: Context) -> CGSize? {
        uiView.intrinsicContentSize
    }

    static func dismantleUIView(_ control: UISwitch, coordinator: Coordinator) {
        #if DEBUG
        UITestEnvironment.traceToggle("control dismantle id=\(ObjectIdentifier(control)) target=\(ObjectIdentifier(coordinator)) window=\(control.window != nil)")
        #endif
        control.removeTarget(coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
    }
}
