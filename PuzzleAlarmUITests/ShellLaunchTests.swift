import XCTest

final class ShellLaunchTests: XCTestCase {
    @MainActor
    func testLaunchDisplaysNativeShell() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset"]
        app.launch()

        let title = app.staticTexts["shell.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "PuzzleAlarm")
    }
}
