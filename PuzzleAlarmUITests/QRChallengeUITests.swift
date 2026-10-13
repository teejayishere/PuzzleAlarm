import XCTest

final class QRChallengeUITests: XCTestCase {
    @MainActor private func launch(_ name: String, scenario: String = "qr", permission: String = "authorized") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1", "PUZZLE_TEST_NAME": name,
            "PUZZLE_SCENARIO": scenario, "PUZZLE_CAMERA_STATUS": permission]
        app.launch(); openQR(app); return app
    }
    @MainActor private func openQR(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["qr.open"].waitForExistence(timeout: 15)); app.buttons["qr.open"].tap()
        XCTAssertTrue(app.buttons["qr.start"].waitForExistence(timeout: 10))
    }
    @MainActor private func label(_ app: XCUIApplication, _ id: String, _ text: String) {
        let element = app.staticTexts[id]
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text),
            object: element)], timeout: 15) == .completed)
    }
    @MainActor func testWrongInterruptionBackgroundRecreationRelaunchAndCompletion() {
        let app = launch("qr-smoke")
        app.buttons["qr.start"].tap(); label(app, "qr.status", "Authorized")
        app.buttons["qr.fake.wrong"].tap(); label(app, "qr.feedback", "This is not the configured QR code.")
        app.buttons["qr.fake.interrupt"].tap(); label(app, "qr.status", "Interrupted")
        app.buttons["qr.fake.correct"].tap(); XCTAssertFalse(app.staticTexts["qr.completed"].exists)
        app.buttons["qr.start"].tap(); label(app, "qr.status", "Authorized")
        XCUIDevice.shared.press(.home); app.activate(); label(app, "qr.status", "Idle")
        app.buttons["qr.fake.correct"].tap(); XCTAssertFalse(app.staticTexts["qr.completed"].exists)
        app.navigationBars["QR Challenge"].buttons.element(boundBy: 0).tap(); openQR(app)
        label(app, "qr.status", "Idle")
        app.terminate(); app.launchEnvironment["PUZZLE_RESET"] = "0"; app.launch(); openQR(app)
        label(app, "qr.status", "Idle")
        app.buttons["qr.start"].tap(); app.buttons["qr.fake.correct"].tap()
        label(app, "qr.completed", "Wake-up complete")
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["qr.open"].exists)
    }
    @MainActor func testDeniedUnavailableAndOrderedNextChallenge() {
        let app = launch("qr-permission", scenario: "qrThenMath", permission: "denied")
        app.buttons["qr.start"].tap(); label(app, "qr.status", "Denied")
        app.buttons["qr.fake.correct"].tap(); XCTAssertFalse(app.staticTexts["qr.completed"].exists)
        app.terminate(); app.launchEnvironment["PUZZLE_RESET"] = "0"
        app.launchEnvironment["PUZZLE_CAMERA_STATUS"] = "unavailable"; app.launch(); openQR(app)
        app.buttons["qr.start"].tap(); label(app, "qr.status", "Unavailable")
        app.buttons["qr.fake.correct"].tap(); XCTAssertFalse(app.staticTexts["qr.completed"].exists)
        app.terminate(); app.launchEnvironment["PUZZLE_CAMERA_STATUS"] = "authorized"; app.launch(); openQR(app)
        app.buttons["qr.start"].tap(); app.buttons["qr.fake.correct"].tap(); label(app, "qr.completed", "QR complete")
        app.navigationBars["QR Challenge"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["math.open"].waitForExistence(timeout: 10)); app.buttons["math.open"].tap()
        XCTAssertTrue(app.buttons["math.start"].waitForExistence(timeout: 10)); app.buttons["math.start"].tap()
        let field = app.textFields["math.answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 10)); field.tap(); field.typeText("7")
        app.buttons["math.submit"].tap(); label(app, "math.completed", "Wake-up complete")
    }
    @MainActor func testDisplayShareAndPersistedConfiguration() {
        let app = launch("qr-export")
        app.navigationBars["QR Challenge"].buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'alarm.edit.'")).firstMatch.tap()
        let configure = app.buttons["challenge.configure.qr"]
        if !configure.isHittable { app.swipeUp() }
        XCTAssertTrue(configure.waitForExistence(timeout: 10)); configure.tap()
        XCTAssertTrue(app.images["qr.image"].waitForExistence(timeout: 10))
        app.buttons["qr.share"].tap()
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 10))
        app.buttons["Copy"].tap()
        XCTAssertTrue(app.images["qr.image"].waitForExistence(timeout: 10))
        app.terminate(); app.launchEnvironment["PUZZLE_RESET"] = "0"; app.launch()
        XCTAssertTrue(app.buttons["qr.open"].waitForExistence(timeout: 15))
    }
}
