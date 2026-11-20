import XCTest

// Explicitly selected in the 6A profile; excluded from routine full functional CI.
final class HarnessDiagnosticsUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testNativeTargetOnSeparateFreshLaunches() {
        for native in [false, true] {
            let app = launch(diagnostics: true, probe: true)
            let direct = ready(app.switches.matching(identifier: "diagnostic.direct"), in: app)
            capture("direct-before native=\(native)", in: app)
            if native {
                tapSwitch(direct, to: false, in: app)
            } else {
                direct.tap()
            }
            capture("direct-after native=\(native)", in: app)
            // Both launches complete observation before the native result is enforced.
            if native {
                assertSwitch(direct, isOn: false)
                let state = unique(app.staticTexts.matching(identifier: "diagnostic.state.direct"), in: app)
                XCTAssertTrue(String(describing: state.value).contains("direct.enabled=false"))
            }
            app.terminate()
        }
    }

    @MainActor
    func testSwitchBoundaryDiagnostics() {
        let app = launch(diagnostics: true)
        ready(app.buttons.matching(identifier: "alarms.add"), in: app).tap()
        let enabled = ready(app.switches.matching(identifier: "editor.enabled"), in: app)
        tapSwitch(enabled, to: false, in: app)
        let monday = ready(app.switches.matching(identifier: "editor.day.2"), in: app)
        tapSwitch(monday, to: true, in: app)
        capture("editor-after-both-gestures", in: app)
        let draftState = unique(app.staticTexts.matching(identifier: "diagnostic.state.editor"), in: app)
        XCTAssertTrue(String(describing: draftState.value).contains("draft.enabled=false"))
        XCTAssertTrue(String(describing: draftState.value).contains("weekdays=[2]"))
        // Preserve the diagnostic's saved/list/disk observations before enforcing
        // draft outcomes, even if a gesture had no effect.
        ready(app.buttons.matching(identifier: "editor.save"), in: app).tap()
        rememberCreatedAlarm(in: app)
        let list = rowSwitch(in: app)
        let initial = list.value as? String
        tapSwitch(list, to: initial != "1", in: app)
        let wait = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: list)
        let readiness = XCTWaiter.wait(for: [wait], timeout: 10)
        capture("before-disk-relaunch readiness=\(readiness)", in: app)
        relaunch(app)
        capture("after-disk-relaunch", in: app)
        rowButton("alarm.edit.", in: app).tap()
        capture("reopened-draft", in: app)
        assertSwitch(app.switches["editor.enabled"], isOn: initial != "1")
        assertSwitch(app.switches["editor.day.2"], isOn: true)
    }

    @MainActor
    func testFailureCaptureWithoutUniqueTarget() {
        let app = launch(fixture: "ordinary", diagnostics: true)
        alarmID = "6A000000-0000-4000-8000-000000000001"
        rowButton("alarm.edit.", in: app).tap()
        _ = ready(app.buttons.matching(identifier: "editor.cancel"), in: app)
        // Simulate the observer's missing-target path without failing this suite.
        // No .element property is read on the empty query. Enumerate both screens.
        XCTAssertEqual(app.buttons.matching(identifier: "intentionally.absent").count, 0)
        capture("simulated-failed-readiness-with-editor-presented", in: app)
        let editor = unique(app.staticTexts.matching(identifier: "diagnostic.state.editor"), in: app)
        XCTAssertTrue(String(describing: editor.value).contains("draft.id=\(alarmID!)"))
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        let list = unique(app.staticTexts.matching(identifier: "diagnostic.state.list"), in: app)
        XCTAssertTrue(String(describing: list.value).contains("loaded=true"))
        capture("list-context-after-cancel", in: app)
    }
}
