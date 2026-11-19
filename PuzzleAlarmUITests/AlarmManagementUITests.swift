import XCTest

final class AlarmManagementUITests: XCTestCase, @unchecked Sendable {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(failing: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset"] + (failing ? ["--ui-schedule-failure"] : [])
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
        expectation(for: NSPredicate(format: "value == %@ AND enabled == true", isOn ? "1" : "0"),
                    evaluatedWith: element)
        waitForExpectations(timeout: 10)
    }

    @MainActor
    func testCreateEditEnableDisableDeleteAndRelaunch() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
        app.buttons["alarms.add"].tap()
        choose("editor.hour", "08", in: app)
        choose("editor.minute", "05", in: app)
        app.switches["editor.day.2"].tap()
        reveal(app.switches["editor.day.6"], in: app)
        app.switches["editor.day.6"].tap()
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
        toggle.tap()
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
        restoredToggle.tap()
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
        app.switches["editor.enabled"].tap()
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
        app.switches["editor.day.2"].tap()
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["alarms.warning"].waitForExistence(timeout: 10))
        XCTAssertTrue(rowButton("alarm.retry.", in: app).exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.status.")).firstMatch.exists)
    }
}
