import XCTest

final class PlayableChallengeUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testRunNowSolvesMathMemoryAndRegisteredQRBeforeReturningToList() throws {
        alarmID = "6A000000-0000-4000-8000-000000000002"
        let app = launch(fixture: "playable")
        rowButton("alarm.try.", in: app).tap()

        let prompt = app.staticTexts["challenge.math.prompt"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["challenge.done"].exists)
        let mathAnswer = try answerForEasyPrompt(prompt.label)
        let mathField = ready(app.textFields.matching(identifier: "challenge.answer"), in: app)
        mathField.tap()
        // Use the native Return action wired to the same Check answer command.
        mathField.typeText(String(mathAnswer) + "\n")

        // Read only the actual displayed digits. The deliberate 30-second fixture
        // reveal accommodates slow native XCTest snapshots without answer leakage.
        let visible = app.staticTexts["challenge.memory.visible"]
        XCTAssertTrue(visible.waitForExistence(timeout: 10))
        let recalledDigits = visible.label.filter(\.isNumber)
        XCTAssertEqual(recalledDigits.count, 2)
        XCTAssertFalse(app.buttons["challenge.done"].exists)
        attachHostScreenshot(app, name: "Memory challenge")
        let memoryField = app.textFields["challenge.answer"]
        // This new wait covers that configured 30-second reveal and its transition.
        XCTAssertTrue(memoryField.waitForExistence(timeout: 35))
        XCTAssertFalse(visible.exists, "Recall must begin after the digits hide")
        XCTAssertTrue(waitUntilReady(memoryField, timeout: 10))
        memoryField.tap()
        memoryField.typeText(recalledDigits + "\n")

        let registeredQR = app.buttons["challenge.qr.correct"]
        XCTAssertTrue(registeredQR.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["challenge.done"].exists)
        let otherQR = app.buttons["Simulate another QR"]
        XCTAssertTrue(otherQR.waitForExistence(timeout: 10))
        XCTAssertTrue(waitUntilReady(otherQR, timeout: 10))
        otherQR.tap()
        XCTAssertTrue(app.staticTexts["That didn’t match. Try again."].waitForExistence(timeout: 10))
        XCTAssertTrue(registeredQR.exists, "An unrelated QR must leave the registered QR challenge active")
        XCTAssertFalse(app.buttons["challenge.done"].exists)
        XCTAssertTrue(waitUntilReady(registeredQR, timeout: 10))
        registeredQR.tap()

        let done = app.buttons["challenge.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["All challenges are complete and this occurrence’s alarms have been cancelled."].exists)
        attachHostScreenshot(app, name: "Completed challenge sequence")
        XCTAssertTrue(waitUntilReady(done, timeout: 10))
        done.tap()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 10))
        XCTAssertTrue(rowButton("alarm.edit.", in: app).exists)
        XCTAssertFalse(app.buttons["challenge.done"].exists)
    }

    private func answerForEasyPrompt(_ prompt: String) throws -> Int {
        let parts = prompt.split(whereSeparator: \.isWhitespace)
        guard parts.count == 3, let lhs = Int(parts[0]), let rhs = Int(parts[2]) else {
            XCTFail("Expected a displayed easy arithmetic problem, received: \(prompt)")
            throw PlayablePromptError.unsupported
        }
        switch parts[1] {
        case "+": return lhs + rhs
        case "−", "-": return lhs - rhs
        default:
            XCTFail("Unexpected easy arithmetic operator in: \(prompt)")
            throw PlayablePromptError.unsupported
        }
    }

    @MainActor
    private func attachHostScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private enum PlayablePromptError: Error { case unsupported }
