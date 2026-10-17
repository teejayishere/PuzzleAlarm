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
        let control = UISwitch()
        control.addTarget(coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
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
        control.removeTarget(coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
    }
}
