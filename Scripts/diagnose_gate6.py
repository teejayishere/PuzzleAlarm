"""CI-only instrumentation. Apply to an ephemeral checkout, never a product fix."""
from pathlib import Path


def replace(path, old, new):
    file = Path(path)
    text = file.read_text()
    assert text.count(old) == 1, (path, old)
    file.write_text(text.replace(old, new))


fixture = Path('PuzzleAlarm/App/UITestEnvironment.swift')
source = fixture.read_text()
start = source.index('        let environment = ProcessInfo.processInfo.environment', source.index('static func traceToggle'))
end = source.index('    static let now', start)
source = source[:start] + '        Gate6Recorder.shared.record(message)\n    }\n' + source[end:]
fixture.write_text(source)
Path('PuzzleAlarm/App/Gate6Recorder.swift').write_text(Path('Scripts/Gate6Recorder.swift').read_text())
replace('PuzzleAlarm/App/NativeAlarmSwitch.swift', 'let control = UISwitch()', 'let control = Gate6TraceSwitch()')
replace('PuzzleAlarm/App/NativeAlarmSwitch.swift', r'native control=\(control.isOn)',
        r'native id=\(ObjectIdentifier(control)) target=\(ObjectIdentifier(self)) action=valueChanged control=\(control.isOn)')
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
        row.tap()
        // Stop at the first missing presentation, before unrelated scroll gestures.
        XCTAssertTrue(app.buttons["editor.save"].waitForExistence(timeout: 10), app.debugDescription)
        tap(app, "editor.preview")''')
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
            var current = touch.view
            UITestEnvironment.traceToggle("touch \(phase) timestamp=\(touch.timestamp) point=\(touch.location(in: window)) window=\(ObjectIdentifier(window)) app=\(UIApplication.shared.applicationState.rawValue) scene=\(window.windowScene?.activationState.rawValue ?? -99)")
            var depth = 0
            while let item = current, depth < 24 {
                UITestEnvironment.traceToggle("ancestor phase=\(phase) depth=\(depth) object=\(ObjectIdentifier(item)) type=\(type(of: item)) id=\(item.accessibilityIdentifier ?? "none")")
                let gestures = item.gestureRecognizers ?? []
                for gesture in gestures.prefix(16) {
                    UITestEnvironment.traceToggle("gesture depth=\(depth) object=\(ObjectIdentifier(gesture)) type=\(type(of: gesture)) state=\(gesture.state.rawValue) enabled=\(gesture.isEnabled)")
                }
                if gestures.count > 16 { UITestEnvironment.traceToggle("capture limited gestures") }
                current = item.superview
                depth += 1
            }
            if current != nil { UITestEnvironment.traceToggle("capture limited ancestors") }
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
}
''')
print('CI-only buffered passive capture applied; original selectors/readiness/taps/assertions retained.')
