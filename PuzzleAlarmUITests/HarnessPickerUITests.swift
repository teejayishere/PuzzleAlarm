import XCTest

final class HarnessPickerUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testOffscreenPickerIsRevealedBeforeUniqueInteraction() {
        let app = launch(navigationAudit: true)
        ready(app.buttons.matching(identifier: "alarms.add"), in: app).tap()
        XCTAssertTrue(app.navigationBars["New alarm"].waitForExistence(timeout: 10))
        let query = app.buttons.matching(identifier: "editor.mode")
        let initialCount = query.count
        XCTAssertLessThanOrEqual(initialCount, 1)
        let initiallyHittable = initialCount == 1 && query.element.isHittable
        XCTAssertFalse(initiallyHittable, "Regression must start with Mode outside the usable viewport")
        print("Offscreen picker precondition: count=\(initialCount), hittable=\(initiallyHittable)")
        capture("offscreen-picker-before-reveal count=\(initialCount)", in: app)

        choose("editor.mode", "Challenges required", in: app)
        XCTAssertEqual(query.count, 1)
        XCTAssertTrue(query.element.isEnabled && query.element.isHittable)
        let state = unique(app.staticTexts.matching(identifier: "diagnostic.navigation.editor"), in: app)
        let value = state.value as? String ?? ""
        XCTAssertTrue(value.contains("original=new; mode=challenges_required"), value)
        XCTAssertFalse(value.contains("audit-error:"), value)
        XCTAssertFalse(unique(app.buttons.matching(identifier: "editor.save"), in: app).isEnabled)
        print("Offscreen picker selected: \(value)")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "offscreen-picker-after-selection"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = ready(app.buttons.matching(identifier: "alarms.add"), in: app)
        XCTAssertTrue(app.staticTexts["alarms.empty"].exists)
    }
}
