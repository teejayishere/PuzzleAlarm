#if DEBUG
import UIKit

// Diagnostic only. Never recognizes, delays, cancels or prevents another gesture.
@MainActor
final class AlarmInputWindowProbe: UIGestureRecognizer {
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    private func record(_ touches: Set<UITouch>, phase: String) {
        guard let window = view as? UIWindow else { return }
        for touch in touches {
            let point = touch.location(in: window)
            var ancestor = touch.view
            while let current = ancestor, !(current is UISwitch) { ancestor = current.superview }
            let control = ancestor.flatMap { $0 as? UISwitch }
            let hit = touch.view.map { String(describing: type(of: $0)) } ?? "none"
            UITestEnvironment.traceToggle("window touch=\(phase) timestamp=\(touch.timestamp) point=\(point) app=\(UIApplication.shared.applicationState.rawValue) scene=\(window.windowScene?.activationState.rawValue ?? -99) hit=\(hit) switch=\(control.map { String(describing: ObjectIdentifier($0)) } ?? "none") enabled=\(control?.isEnabled.description ?? "none") on=\(control?.isOn.description ?? "none") tracking=\(control?.isTracking.description ?? "none")")
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { record(touches, phase: "began") }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) { record(touches, phase: "moved") }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        record(touches, phase: "ended"); state = .failed
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        record(touches, phase: "cancelled"); state = .failed
    }
}

@MainActor
final class AlarmInputTraceSwitch: UISwitch {
    private var lastFrame: CGRect?
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window, !(window.gestureRecognizers ?? []).contains(where: { $0 is AlarmInputWindowProbe }) {
            let probe = AlarmInputWindowProbe(target: nil, action: nil)
            probe.cancelsTouchesInView = false
            probe.delaysTouchesBegan = false
            probe.delaysTouchesEnded = false
            window.addGestureRecognizer(probe)
            UITestEnvironment.traceToggle("window probe attached scene=\(window.windowScene?.activationState.rawValue ?? -99)")
        }
        UITestEnvironment.traceToggle("control window id=\(ObjectIdentifier(self)) attached=\(window != nil) targets=\(allTargets.count) enabled=\(isEnabled) on=\(isOn)")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let window else { return }
        let frame = convert(bounds, to: window)
        if frame != lastFrame {
            lastFrame = frame
            UITestEnvironment.traceToggle("control layout id=\(ObjectIdentifier(self)) frame=\(frame) targets=\(allTargets.count) enabled=\(isEnabled) on=\(isOn)")
        }
    }
}
#endif
