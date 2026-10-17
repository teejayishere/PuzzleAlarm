import XCTest

final class WakeUpRoutingUITests: XCTestCase {
    @MainActor func testForegroundReturnsToDueChallengeWithoutStackingDestinations() {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
            "PUZZLE_TEST_NAME": "routing-foreground", "PUZZLE_SCENARIO": "math"]
        app.launch()
        XCTAssertTrue(app.staticTexts["math.prompt"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["math.prompt"].label, "2 + 3")
        for _ in 0..<2 {
            app.navigationBars["Math Challenge"].buttons.element(boundBy: 0).tap()
            XCTAssertTrue(app.buttons["math.open"].waitForExistence(timeout: 10))
            XCUIDevice.shared.press(.home); app.activate()
            XCTAssertTrue(app.staticTexts["math.prompt"].waitForExistence(timeout: 15))
            XCTAssertEqual(app.staticTexts["math.progress"].label, "0 of 2 correct")
            XCTAssertFalse(app.buttons["alarms.add"].exists)
        }
        app.navigationBars["Math Challenge"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].waitForExistence(timeout: 10))
    }

    @MainActor func testNoSessionOpensNormalUIAcrossForegroundAndRelaunch() {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
            "PUZZLE_TEST_NAME": "routing-empty", "PUZZLE_SCENARIO": "empty"]
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].exists)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 15))
        app.terminate(); app.launchEnvironment["PUZZLE_RESET"] = "0"; app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["math.prompt"].exists)
    }
}
