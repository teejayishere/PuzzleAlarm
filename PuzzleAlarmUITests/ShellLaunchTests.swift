import XCTest

final class ShellLaunchTests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testLaunchDisplaysNativeShell() {
        let app = launch()

        let title = app.staticTexts["shell.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "PuzzleAlarm")
    }
}
