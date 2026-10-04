import XCTest

final class ShellLaunchTests: XCTestCase {
    @MainActor
    func testLaunchDisplaysNativeShell() {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1", "PUZZLE_TEST_NAME": "shell"]
        app.launch()
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["alarms.empty"].exists || app.staticTexts["No alarms"].exists)
        XCTAssertTrue(app.buttons["alarms.add"].exists)
    }
}
