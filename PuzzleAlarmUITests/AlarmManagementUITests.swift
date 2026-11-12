import XCTest

final class AlarmManagementUITests: XCTestCase, @unchecked Sendable {
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
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Control not reachable: \(element)")
    }

    @MainActor
    private func choose(_ id: String, _ title: String, in app: XCUIApplication) {
        let picker = app.buttons[id]
        reveal(picker, in: app)
        picker.tap()
        let option = app.buttons[title].lastMatch
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        option.tap()
    }

    @MainActor
    private func rowButton(_ prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
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
        choose("editor.sound", "Harsh buzzer", in: app)
        app.buttons["editor.save"].tap()
        let edit = rowButton("alarm.edit.", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["08:05"].exists)
        XCTAssertTrue(app.staticTexts["Harsh buzzer"].exists)
        let toggle = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.tap()
        expectation(for: NSPredicate(format: "value == %@", "0"), evaluatedWith: toggle)
        waitForExpectations(timeout: 5)
        edit.tap()
        choose("editor.minute", "06", in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["08:06"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["08:06"].waitForExistence(timeout: 10))
        let restoredToggle = app.switches.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.enabled.")).firstMatch
        XCTAssertEqual(restoredToggle.value as? String, "0")
        restoredToggle.tap()
        expectation(for: NSPredicate(format: "value == %@", "1"), evaluatedWith: restoredToggle)
        waitForExpectations(timeout: 5)
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
        count.buttons["Increment"].tap()
        let up = app.buttons["challenge.up.qr"]
        reveal(up, in: app); up.tap()
        choose("editor.sound", "Siren", in: app)
        app.buttons["editor.save"].tap()
        XCTAssertTrue(app.staticTexts["Memory → QR Code → Math"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Siren"].exists)
        app.terminate(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.staticTexts["Memory → QR Code → Math"].waitForExistence(timeout: 10))
        rowButton("alarm.edit.", in: app).tap()
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
