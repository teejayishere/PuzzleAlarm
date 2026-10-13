import XCTest

final class MemoryChallengeUITests: XCTestCase {
    @MainActor func testRecallWrongFreshRoundRelaunchAndCompletion() {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
            "PUZZLE_TEST_NAME": "memory-smoke", "PUZZLE_SCENARIO": "memory"]
        app.launch(); openMemory(app)
        let start = app.buttons["memory.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10)); start.tap()
        XCTAssertTrue(app.textFields["memory.answer"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["memory.sequence"].exists)
        enter("9999", app)
        waitLabel(app.staticTexts["memory.feedback"], "Try a new sequence.")
        XCTAssertEqual(app.staticTexts["memory.progress"].label, "0 of 2 rounds")
        XCTAssertTrue(app.textFields["memory.answer"].waitForExistence(timeout: 10))
        enter("1123", app) // Coincident injected digits get a bounded fresh adjustment.
        waitLabel(app.staticTexts["memory.progress"], "1 of 2 rounds")
        // Relaunch during/after reveal must not reveal saved digits again.
        app.terminate(); app.launchEnvironment["PUZZLE_RESET"] = "0"; app.launch(); openMemory(app)
        XCTAssertTrue(app.textFields["memory.answer"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["memory.sequence"].exists)
        XCTAssertEqual(app.staticTexts["memory.progress"].label, "1 of 2 rounds")
        enter("0123", app)
        waitLabel(app.staticTexts["memory.completed"], "Wake-up complete")
        XCTAssertFalse(app.buttons["memory.submit"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["memory.open"].exists)
    }
    @MainActor private func openMemory(_ app: XCUIApplication) {
        let link = app.buttons["memory.open"]
        XCTAssertTrue(link.waitForExistence(timeout: 15)); link.tap()
        XCTAssertTrue(app.staticTexts["memory.progress"].waitForExistence(timeout: 10))
    }
    @MainActor private func enter(_ value: String, _ app: XCUIApplication) {
        let field = app.textFields["memory.answer"]
        field.tap(); field.typeText(value); app.buttons["memory.submit"].tap()
    }
    @MainActor private func waitLabel(_ element: XCUIElement, _ label: String) {
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label), object: element)], timeout: 15) == .completed)
        XCTAssertEqual(element.label, label)
    }
}
