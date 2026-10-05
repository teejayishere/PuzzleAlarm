import XCTest

@MainActor
final class AlarmManagementUITests: XCTestCase {
    private let seededID = "00000000-0000-0000-0000-000000000001"

    private func launch(_ name: String, scenario: String = "empty", largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
                                 "PUZZLE_TEST_NAME": name, "PUZZLE_SCENARIO": scenario]
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 20))
        return app
    }
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
    private func tap(_ app: XCUIApplication, _ id: String) {
        let target = element(app, id)
        if !target.exists || !target.isHittable {
            for _ in 0..<6 {
                if target.exists && target.isHittable { break }
                app.swipeDown()
            }
        }
        for _ in 0..<6 {
            if target.exists && target.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(target.waitForExistence(timeout: 5), id)
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: target)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 10), .completed, id)
        target.tap()
    }
    private func choose(_ app: XCUIApplication, _ id: String, _ title: String) {
        tap(app, id)
        let choice = app.buttons[title].firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), title)
        choice.tap()
    }
    private func expectLabel(_ element: XCUIElement, _ text: String) {
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: 10), .completed)
    }
    private func back(_ app: XCUIApplication) { app.navigationBars.buttons.element(boundBy: 0).tap() }
    private func firstRow(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit.")).firstMatch
    }
    private func relaunch(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment["PUZZLE_RESET"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 20))
    }
    private func time(_ app: XCUIApplication, hour: String, minute: String) {
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.element(boundBy: 0).waitForExistence(timeout: 5))
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: hour)
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: minute)
        if wheels.count > 2 { wheels.element(boundBy: 2).adjust(toPickerWheelValue: "AM") }
    }
    private func increment(_ app: XCUIApplication, _ id: String) {
        let stepper = app.steppers[id]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons.element(boundBy: 1).tap()
    }

    func testEmptyAddPersistsTimeWeekdaysModeAndSoundAcrossRelaunch() {
        let app = launch("add")
        XCTAssertTrue(app.staticTexts["No alarms"].waitForExistence(timeout: 10))
        tap(app, "alarms.add")
        time(app, hour: "8", minute: "30")
        tap(app, "editor.repeat"); tap(app, "repeat.weekdays"); back(app)
        choose(app, "editor.sound", "Siren")
        tap(app, "editor.save")
        let row = firstRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let id = row.identifier
        XCTAssertTrue(row.label.contains("8:30") && row.label.contains("Weekdays"))
        XCTAssertTrue(row.label.contains("Annoying Alarm Only") && row.label.contains("Siren"))
        relaunch(app)
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[id].label.contains("8:30"))
    }

    func testChallengeConfigurationOrderAndSettingsSurviveSaveReloadAndEdit() {
        let app = launch("challenges")
        tap(app, "alarms.add")
        choose(app, "editor.mode", "Challenges Required")
        XCTAssertFalse(app.buttons["editor.save"].isEnabled)
        choose(app, "challenge.add", "Memory")
        choose(app, "challenge.add", "Math")
        choose(app, "challenge.add", "QR Code")
        tap(app, "challenge.configure.memory")
        choose(app, "memory.difficulty", "Hard")
        increment(app, "memory.length"); increment(app, "memory.duration"); increment(app, "memory.rounds")
        back(app)
        tap(app, "challenge.configure.math")
        choose(app, "math.difficulty", "Hard"); increment(app, "math.count")
        back(app)
        tap(app, "challenge.up.math")
        tap(app, "editor.save")
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Math → Memory → QR Code"))
        relaunch(app)
        firstRow(app).tap()
        XCTAssertTrue(element(app, "challenge.order.math").waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "challenge.order.math").label, "1. Math")
        tap(app, "challenge.configure.memory")
        XCTAssertTrue(app.staticTexts["Sequence length: 9"].exists)
        XCTAssertTrue(app.staticTexts["Display seconds: 4"].exists)
        XCTAssertTrue(app.staticTexts["Successful rounds: 2"].exists)
        back(app)
        tap(app, "challenge.configure.math")
        XCTAssertTrue(app.staticTexts["Correct answers: 6"].exists)
    }

    func testEnableDisableAndFailureRetryAreHonest() {
        let app = launch("toggle", scenario: "enableFailure")
        let status = app.staticTexts["alarm.status." + seededID]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        expectLabel(status, "Off")
        tap(app, "alarm.enabled." + seededID)
        XCTAssertTrue(app.buttons["alarm.retry." + seededID].waitForExistence(timeout: 10))
        expectLabel(status, "Needs attention")
        tap(app, "alarm.retry." + seededID)
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        expectLabel(status, "On")
        tap(app, "alarm.enabled." + seededID)
        expectLabel(status, "Off")
        tap(app, "alarm.enabled." + seededID)
        expectLabel(status, "On")
    }

    func testEditChangesConfigurationWithoutChangingIdentity() {
        let app = launch("edit", scenario: "healthy")
        let id = "alarm.edit." + seededID
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        app.buttons[id].tap()
        time(app, hour: "9", minute: "15")
        tap(app, "editor.repeat"); tap(app, "repeat.weekends"); back(app)
        choose(app, "editor.mode", "Challenges Required")
        choose(app, "challenge.add", "Math")
        choose(app, "editor.sound", "Rapid Beeps")
        tap(app, "editor.save")
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[id].label.contains("9:15") && app.buttons[id].label.contains("Weekends"))
        XCTAssertTrue(app.buttons[id].label.contains("Math") && app.buttons[id].label.contains("Rapid Beeps"))
        relaunch(app)
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit.")).count, 1)
    }

    func testDeleteConfirmationCancelAndSuccessfulCleanup() {
        let app = launch("delete", scenario: "healthy")
        let row = app.buttons["alarm.edit." + seededID]
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        tap(app, "editor.delete")
        XCTAssertTrue(app.buttons["Keep Alarm"].waitForExistence(timeout: 5))
        app.buttons["Keep Alarm"].tap()
        XCTAssertTrue(app.buttons["editor.save"].exists)
        tap(app, "editor.delete")
        tap(app, "editor.confirmDelete")
        XCTAssertTrue(app.staticTexts["No alarms"].waitForExistence(timeout: 10))
        XCTAssertFalse(row.exists)
    }

    func testDeleteCleanupFailureKeepsAlarmVisible() {
        let app = launch("deleteFailure", scenario: "deleteFailure")
        let row = app.buttons["alarm.edit." + seededID]
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        tap(app, "editor.delete")
        tap(app, "editor.confirmDelete")
        XCTAssertTrue(app.staticTexts["editor.error"].waitForExistence(timeout: 10))
        tap(app, "editor.cancel")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["alarm.status." + seededID].label, "Cleanup pending")
    }

    func testOneTimeAndCancelDraftRemainDistinctFromDaily() {
        let app = launch("once")
        tap(app, "alarms.add")
        tap(app, "editor.repeat"); tap(app, "repeat.everyday"); back(app)
        tap(app, "editor.cancel")
        XCTAssertTrue(app.staticTexts["No alarms"].exists)
        tap(app, "alarms.add")
        tap(app, "editor.save")
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Once"))
        XCTAssertFalse(firstRow(app).label.contains("Every day"))
        relaunch(app)
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Once"))
    }

    func testAuthorizationAndLargeTextControls() {
        let app = launch("access", scenario: "notDetermined", largeText: true)
        XCTAssertEqual(app.staticTexts["authorization.status"].label, "Not requested")
        tap(app, "authorization.request")
        XCTAssertEqual(app.staticTexts["authorization.status"].label, "Authorized")
        tap(app, "alarms.add")
        XCTAssertTrue(app.buttons["editor.cancel"].isHittable && app.buttons["editor.save"].isHittable)
        app.terminate()
        let denied = launch("denied", scenario: "denied")
        XCTAssertEqual(denied.staticTexts["authorization.status"].label, "Denied")
        XCTAssertTrue(denied.buttons["authorization.settings"].exists)
        XCTAssertFalse(denied.buttons["authorization.request"].exists)
    }
}
