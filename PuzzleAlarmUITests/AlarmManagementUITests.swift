import XCTest

final class AlarmManagementUITests: XCTestCase, @unchecked Sendable {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(failing: Bool = false) -> XCUIApplication {
        verifyNativeTargetOnFreshLaunches()
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-switch-diagnostics"] + (failing ? ["--ui-schedule-failure"] : [])
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        // Editing can revisit controls above the current viewport, too.
        for upward in [true, false] {
            for _ in 0..<12 {
                if element.exists && element.isHittable { return }
                if upward { app.swipeUp() } else { app.swipeDown() }
            }
        }
        XCTFail("Control not reachable: \(element)")
    }

    @MainActor
    private func choose(_ id: String, _ title: String, in app: XCUIApplication) {
        let picker = app.buttons[id]
        reveal(picker, in: app)
        picker.tap()
        let option = app.buttons.matching(identifier: title).element
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        option.tap()
    }

    @MainActor
    private func rowButton(_ prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    @MainActor
    private func assertSwitch(_ element: XCUIElement, isOn: Bool) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        // The requested value alone is insufficient: wait for the command to
        // finish and the control to become usable with its committed value.
        let pending = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@ AND enabled == true", isOn ? "1" : "0"),
            object: element)
        let result = XCTWaiter.wait(for: [pending], timeout: 10)
        // Capture even on failure, before continueAfterFailure ends this flow.
        observeSwitch(element, expected: isOn, phase: "assertion", in: XCUIApplication())
        XCTAssertEqual(result, .completed)
    }

    @MainActor
    private func observeSwitch(_ element: XCUIElement, expected: Bool, phase: String, in app: XCUIApplication) {
        let name = "\(self.name)-\(element.identifier)-\(phase)"
        guard element.exists else { print("SWITCH \(name) missing"); return }
        let value = element.value
        let runtimeType = value.map { String(reflecting: type(of: $0)) } ?? "nil"
        let valueTerm = NSPredicate(format: "value == %@", expected ? "1" : "0").evaluate(with: element)
        let enabledTerm = NSPredicate(format: "enabled == true").evaluate(with: element)
        let states = app.staticTexts.matching(identifier: "diagnostic.state").allElementsBoundByIndex
        let stateDetails = states.enumerated().map { index, state in
            "readout[\(index)] label=\(state.label) frame=\(state.frame) value=\(String(describing: state.value))"
        }.joined(separator: " | ")
        let details = "SWITCH \(name): value=\(String(describing: value)) type=\(runtimeType) enabled=\(element.isEnabled) hittable=\(element.isHittable) frame=\(element.frame) valueTerm=\(valueTerm) enabledTerm=\(enabledTerm) children=\(element.children(matching: .any).allElementsBoundByIndex) appState=\(stateDetails)\n\(app.debugDescription)"
        print(details)
        let hierarchy = XCTAttachment(string: details)
        hierarchy.name = name + "-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        // Preserve screenshots in downloadable Actions logs without changing CI.
        // Bounded chunks avoid the Actions per-line size limit.
        let base64 = Array(screenshot.pngRepresentation.base64EncodedString())
        print("SWITCH_PNG_BEGIN \(name)")
        for offset in stride(from: 0, to: base64.count, by: 12000) {
            print("SWITCH_PNG " + String(base64[offset..<min(offset + 12000, base64.count)]))
        }
        print("SWITCH_PNG_END \(name)")
    }

    @MainActor
    private func tapSwitch(_ element: XCUIElement, to expected: Bool, in app: XCUIApplication) {
        observeSwitch(element, expected: expected, phase: "before-one-tap", in: app)
        let children = element.children(matching: .switch)
        XCTAssertEqual(children.count, 1, "Expected the evidenced single native switch child")
        let child = children.element(boundBy: 0)
        observeSwitch(child, expected: expected, phase: "native-before-one-tap", in: app)
        child.tap()
        observeSwitch(child, expected: expected, phase: "native-after-one-tap", in: app)
        observeSwitch(element, expected: expected, phase: "after-one-tap", in: app)
    }

    @MainActor
    private func verifyNativeTargetOnFreshLaunches() {
        let app = XCUIApplication()
        for native in [false, true] {
            app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-switch-diagnostics", "--ui-switch-probe"]
            app.launch()
            let direct = app.switches["diagnostic.direct"]
            XCTAssertTrue(direct.waitForExistence(timeout: 10))
            if native {
                tapSwitch(direct, to: false, in: app)
                assertSwitch(direct, isOn: false)
                let state = app.staticTexts.matching(identifier: "diagnostic.state").element
                XCTAssertTrue(String(describing: state.value).contains("direct.enabled=false"))
            } else {
                observeSwitch(direct, expected: false, phase: "wrapper-before-one-tap", in: app)
                direct.tap()
                observeSwitch(direct, expected: false, phase: "wrapper-after-one-tap", in: app)
            }
            app.terminate()
        }
    }

    @MainActor
    func testSwitchBoundaryDiagnostics() {
        verifyNativeTargetOnFreshLaunches()
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-switch-diagnostics"]
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 10))
        app.buttons["alarms.add"].tap()
        tapSwitch(app.switches["editor.enabled"], to: false, in: app)
        tapSwitch(app.switches["editor.day.2"], to: true, in: app)
        // Save the observed draft, regardless of whether automation changed it.
        // This lets list/service/persistence evidence survive an editor failure.
        app.buttons["editor.save"].tap()
        let edit = rowButton("alarm.edit.", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        let list = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch
        let initial = list.value as? String
        tapSwitch(list, to: initial != "1", in: app)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: list)
        let readiness = XCTWaiter.wait(for: [ready], timeout: 10)
        print("SWITCH list readiness before relaunch: \(readiness)")
        observeSwitch(list, expected: initial != "1", phase: "before-disk-relaunch", in: app)
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-switch-diagnostics"]
        app.launch()
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        observeSwitch(list, expected: initial != "1", phase: "after-disk-relaunch", in: app)
        edit.tap()
        observeSwitch(app.switches["editor.enabled"], expected: initial != "1", phase: "reopened-draft", in: app)
        observeSwitch(app.switches["editor.day.2"], expected: true, phase: "reopened-draft", in: app)
        // Diagnostic collection is complete before enforcing these outcomes.
        assertSwitch(app.switches["editor.enabled"], isOn: initial != "1")
        assertSwitch(app.switches["editor.day.2"], isOn: true)
    }

    @MainActor
    func testCreateEditEnableDisableDeleteAndRelaunch() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
        app.buttons["alarms.add"].tap()
        choose("editor.hour", "08", in: app)
        choose("editor.minute", "05", in: app)
        tapSwitch(app.switches["editor.day.2"], to: true, in: app)
        reveal(app.switches["editor.day.6"], in: app)
        tapSwitch(app.switches["editor.day.6"], to: true, in: app)
        assertSwitch(app.switches["editor.day.2"], isOn: true)
        assertSwitch(app.switches["editor.day.6"], isOn: true)
        choose("editor.sound", "Harsh buzzer", in: app)
        app.buttons["editor.save"].tap()
        let edit = rowButton("alarm.edit.", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["08:05"].exists)
        XCTAssertTrue(app.staticTexts["Harsh buzzer"].exists)
        let toggle = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch
        assertSwitch(toggle, isOn: true)
        tapSwitch(toggle, to: false, in: app)
        assertSwitch(toggle, isOn: false)
        edit.tap()
        assertSwitch(app.switches["editor.enabled"], isOn: false)
        assertSwitch(app.switches["editor.day.2"], isOn: true)
        assertSwitch(app.switches["editor.day.6"], isOn: true)
        choose("editor.minute", "06", in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["08:06"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["08:06"].waitForExistence(timeout: 10))
        let restoredToggle = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch
        assertSwitch(restoredToggle, isOn: false)
        tapSwitch(restoredToggle, to: true, in: app)
        assertSwitch(restoredToggle, isOn: true)
        // Re-enable must persist too; an already-on control cannot satisfy it.
        app.terminate(); app.launchArguments = ["--ui-testing"]; app.launch()
        assertSwitch(app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch,
                     isOn: true)
        let delete = rowButton("alarm.delete.", in: app)
        reveal(delete, in: app)
        delete.tap()
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(rowButton("alarm.edit.", in: app).exists)
        delete.tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testChallengeConfigurationOrderingSoundAndPersistence() {
        let app = launch()
        app.buttons["alarms.add"].tap()
        // Disabled avoids a one-time occurrence crossing wake time during a UI run.
        tapSwitch(app.switches["editor.enabled"], to: false, in: app)
        assertSwitch(app.switches["editor.enabled"], isOn: false)
        choose("editor.mode", "Challenges required", in: app)
        XCTAssertFalse(app.buttons["editor.save"].isEnabled)
        for kind in ["memory", "math", "qr"] {
            let add = app.buttons["challenge.add.\(kind)"]
            reveal(add, in: app); add.tap()
        }
        XCTAssertFalse(app.buttons["challenge.add.math"].isEnabled)
        choose("challenge.difficulty.memory", "Hard", in: app)
        let count = app.steppers["challenge.memory.rounds"]
        reveal(count, in: app)
        let increment = count.buttons["challenge.memory.rounds-Increment"]
        XCTAssertTrue(increment.waitForExistence(timeout: 3))
        increment.tap()
        XCTAssertTrue(increment.label.contains("Rounds: 2"))
        let up = app.buttons["challenge.up.qr"]
        reveal(up, in: app); up.tap()
        choose("editor.sound", "Siren", in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["Memory → QR Code → Math"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Siren"].exists)
        app.terminate(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.staticTexts["Memory → QR Code → Math"].waitForExistence(timeout: 10))
        rowButton("alarm.edit.", in: app).tap()
        let restoredRounds = app.steppers["challenge.memory.rounds"]
        reveal(restoredRounds, in: app)
        XCTAssertTrue(restoredRounds.buttons["challenge.memory.rounds-Increment"].label.contains("Rounds: 2"))
        let remove = app.buttons["challenge.remove.qr"]
        reveal(remove, in: app); remove.tap()
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["Memory → Math"].waitForExistence(timeout: 10))
        rowButton("alarm.edit.", in: app).tap()
        choose("editor.hour", "10", in: app)
        app.buttons["editor.cancel"].tap()
        XCTAssertTrue(app.staticTexts["07:00"].exists)
        rowButton("alarm.edit.", in: app).tap()
        choose("editor.mode", "Alarm only", in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["Alarm only"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testScheduleFailureIsNotPresentedAsHealthyAlarm() {
        let app = launch(failing: true)
        app.buttons["alarms.add"].tap()
        tapSwitch(app.switches["editor.day.2"], to: true, in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["alarms.warning"].waitForExistence(timeout: 10))
        XCTAssertTrue(rowButton("alarm.retry.", in: app).exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.status.")).firstMatch.exists)
    }
}
