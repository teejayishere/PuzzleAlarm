import XCTest

final class MathChallengeUITests: XCTestCase {
    @MainActor
    func testTypedAnswersRestoreProgressAndComplete() {
        let app = XCUIApplication()
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
                                 "PUZZLE_TEST_NAME": "math-smoke", "PUZZLE_SCENARIO": "math"]
        app.launch()
        openMath(app)
        XCTAssertEqual(app.staticTexts["math.prompt"].label, "2 + 3")
        XCTAssertEqual(app.staticTexts["math.progress"].label, "0 of 2 correct")
        captureDemo("08-math-challenge", app: app)
        app.buttons["math.submit"].tap()
        waitLabel(app.staticTexts["math.feedback"], "Enter a whole number.")
        enter("9", app)
        waitLabel(app.staticTexts["math.feedback"], "Try again.")
        XCTAssertEqual(app.staticTexts["math.progress"].label, "0 of 2 correct")
        // Wrong input remains editable; replace it through the ordinary text field.
        let field = app.textFields["math.answer"]
        field.tap(); field.typeText(XCUIKeyboardKey.delete.rawValue + "5")
        app.buttons["math.submit"].tap()
        waitLabel(app.staticTexts["math.progress"], "1 of 2 correct")
        waitLabel(app.staticTexts["math.prompt"], "3 + 4")
        app.terminate()
        app.launchEnvironment["PUZZLE_RESET"] = "0"
        app.launch()
        openMath(app)
        XCTAssertEqual(app.staticTexts["math.progress"].label, "1 of 2 correct")
        XCTAssertEqual(app.staticTexts["math.prompt"].label, "3 + 4")
        enter("7", app)
        XCTAssertTrue(app.staticTexts["math.completed"].waitForExistence(timeout: 10))
        waitLabel(app.staticTexts["math.completed"], "Wake-up complete")
        XCTAssertFalse(app.buttons["math.submit"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.navigationBars["PuzzleAlarm"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["math.open"].exists)
    }
    @MainActor private func openMath(_ app: XCUIApplication) {
        let link = app.buttons["math.open"]
        XCTAssertTrue(link.waitForExistence(timeout: 15)); link.tap()
        XCTAssertTrue(app.staticTexts["math.prompt"].waitForExistence(timeout: 10))
    }
    @MainActor private func enter(_ value: String, _ app: XCUIApplication) {
        let field = app.textFields["math.answer"]
        field.tap(); field.typeText(value); app.buttons["math.submit"].tap()
    }
    @MainActor private func waitLabel(_ element: XCUIElement, _ value: String) {
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", value), object: element)], timeout: 10) == .completed)
        XCTAssertEqual(element.label, value)
    }
}
