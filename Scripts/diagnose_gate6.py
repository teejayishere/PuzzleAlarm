"""CI-only instrumentation. Apply to an ephemeral checkout, never a product fix."""
from pathlib import Path


def replace(path, old, new):
    file = Path(path)
    text = file.read_text()
    assert text.count(old) == 1, (path, old)
    file.write_text(text.replace(old, new))


replace('PuzzleAlarm/App/UITestEnvironment.swift',
        'environment["PUZZLE_SCENARIO"] == "enableFailure"', 'environment["PUZZLE_INPUT_TRACE"] == "1"')
replace('PuzzleAlarm/App/NativeAlarmSwitch.swift', 'let control = UISwitch()', 'let control = Gate6TraceSwitch()')
replace('PuzzleAlarm/App/NativeAlarmSwitch.swift',
        'control.accessibilityLabel = "Alarm enabled"',
        r'''control.accessibilityLabel = "Alarm enabled"
        UITestEnvironment.traceToggle("control update id=\(ObjectIdentifier(control)) enabled=\(enabled) on=\(control.isOn) window=\(control.window != nil) targets=\(control.allTargets.count)")''')
replace('PuzzleAlarm/App/ContentView.swift', 'Button { draft = AlarmEditorDraft(alarm) } label:',
        r'''Button {
                            UITestEnvironment.traceToggle("row action id=\(alarm.id) busy=\(store.isBusy) exists=\(store.definition(alarm.id) != nil) route=\(store.routeRevision)")
                            draft = AlarmEditorDraft(alarm)
                            UITestEnvironment.traceToggle("row draft assigned=\(draft != nil)")
                        } label:''')
replace('PuzzleAlarm/App/ContentView.swift',
        '.sheet(item: $draft) { value in AlarmEditorView(store: store, initial: value) }',
        r'''.background(Gate6WindowBridge().allowsHitTesting(false))
            .onChange(of: draft?.id) { _, value in
                UITestEnvironment.traceToggle("sheet binding id=\(String(describing: value)) busy=\(store.isBusy)")
            }
            .sheet(item: $draft) { value in
                AlarmEditorView(store: store, initial: value)
                    .onAppear { UITestEnvironment.traceToggle("editor appeared id=\(value.id)") }
                    .onDisappear { UITestEnvironment.traceToggle("editor disappeared id=\(value.id)") }
            }''')
replace('PuzzleAlarm/App/ContentView.swift',
        '.onChange(of: store.routeRevision) { _, _ in',
        r'''.onChange(of: store.routeRevision) { _, _ in
                UITestEnvironment.traceToggle("route revision=\(store.routeRevision) destination=\(String(describing: store.wakeUpSessionID)) draft=\(draft != nil)")''')

test = 'PuzzleAlarmUITests/AlarmManagementUITests.swift'
replace(test, '"PUZZLE_TEST_NAME": name, "PUZZLE_SCENARIO": scenario]',
        '"PUZZLE_TEST_NAME": name, "PUZZLE_SCENARIO": scenario, "PUZZLE_INPUT_TRACE": "1"]')
replace(test, 'XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()\n        tap(app, "editor.preview")',
        '''XCTAssertTrue(row.waitForExistence(timeout: 10))
        traceInput(app, row, "reopen before")
        row.tap()
        traceInput(app, row, "reopen after")
        // Stop at the first missing presentation, before unrelated scroll gestures.
        XCTAssertTrue(app.buttons["editor.save"].waitForExistence(timeout: 10), app.debugDescription)
        tap(app, "editor.preview")''')
replace(test, '            control.tap()',
        '''            traceInput(app, control, "switch before")
            control.tap()
            traceInput(app, control, "switch after")''')
replace(test, '    private func firstRow(', r'''    private func traceInput(_ app: XCUIApplication, _ target: XCUIElement, _ name: String) {
        print("INPUT \(Date().timeIntervalSince1970) \(name) id=\(target.identifier) type=\(target.elementType.rawValue) frame=\(target.frame) enabled=\(target.isEnabled) hittable=\(target.isHittable) value=\(String(describing: target.value)) app=\(app.state.rawValue)")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + " hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    private func firstRow(''')

Path('PuzzleAlarm/App/Gate6InputProbe.swift').write_text(r'''
import SwiftUI
import UIKit

@MainActor
final class Gate6WindowProbe: UIGestureRecognizer {
    override func canPrevent(_ other: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }
    private func record(_ touches: Set<UITouch>, _ phase: String) {
        guard let window = view as? UIWindow else { return }
        for touch in touches {
            var ancestors: [String] = []
            var current = touch.view
            while let item = current {
                let gestures = (item.gestureRecognizers ?? []).map { "\(type(of: $0)):\($0.state.rawValue):enabled=\($0.isEnabled)" }.joined(separator: ",")
                ancestors.append("\(type(of: item)) id=\(item.accessibilityIdentifier ?? "none") gestures=[\(gestures)]")
                current = item.superview
            }
            UITestEnvironment.traceToggle("touch \(phase) timestamp=\(touch.timestamp) point=\(touch.location(in: window)) app=\(UIApplication.shared.applicationState.rawValue) scene=\(window.windowScene?.activationState.rawValue ?? -99) path=\(ancestors.joined(separator: " / "))")
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) { record(touches, "began") }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { record(touches, "ended"); state = .failed }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { record(touches, "cancelled"); state = .failed }
}

@MainActor
struct Gate6WindowBridge: UIViewRepresentable {
    final class Host: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, !(window.gestureRecognizers ?? []).contains(where: { $0 is Gate6WindowProbe }) else { return }
            let probe = Gate6WindowProbe(target: nil, action: nil)
            probe.cancelsTouchesInView = false; probe.delaysTouchesBegan = false; probe.delaysTouchesEnded = false
            window.addGestureRecognizer(probe)
            UITestEnvironment.traceToggle("probe attached window=\(ObjectIdentifier(window)) scene=\(window.windowScene?.activationState.rawValue ?? -99)")
        }
    }
    func makeUIView(context: Context) -> Host { Host() }
    func updateUIView(_ uiView: Host, context: Context) {}
}

@MainActor
final class Gate6TraceSwitch: UISwitch {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        UITestEnvironment.traceToggle("switch attached=\(window != nil) id=\(ObjectIdentifier(self)) targets=\(allTargets.count)")
    }
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let accepted = super.beginTracking(touch, with: event)
        UITestEnvironment.traceToggle("tracking began accepted=\(accepted) on=\(isOn) enabled=\(isEnabled) id=\(ObjectIdentifier(self))")
        return accepted
    }
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        UITestEnvironment.traceToggle("tracking end before on=\(isOn) id=\(ObjectIdentifier(self))")
        super.endTracking(touch, with: event)
        UITestEnvironment.traceToggle("tracking end after on=\(isOn) id=\(ObjectIdentifier(self))")
    }
    override func cancelTracking(with event: UIEvent?) {
        UITestEnvironment.traceToggle("tracking cancel on=\(isOn) id=\(ObjectIdentifier(self))")
        super.cancelTracking(with: event)
    }
}
''')
print('CI-only input instrumentation applied; product assertions and single taps retained.')
