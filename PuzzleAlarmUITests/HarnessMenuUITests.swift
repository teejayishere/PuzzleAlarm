import XCTest

final class HarnessMenuUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testMinuteOptionSelectionReportsExactDraftWithoutWriting() {
        alarmID = "6A000000-0000-4000-8000-000000000001"
        let app = launch(fixture: "ordinary", navigationAudit: true)
        rowButton("alarm.edit.", in: app).tap()
        let before = state(in: app)
        for (hour, minute) in [("08", "05"), ("09", "06"), ("08", "05")] {
            choose("editor.hour", hour, in: app)
            choose("editor.minute", minute, in: app)
            let value = state(in: app)
            XCTAssertTrue(value.contains("hour=\(Int(hour)!); minute=\(Int(minute)!)"), value)
            XCTAssertTrue(value.contains("weekdays=[2, 6]; enabled=false; soundIndex=0; canSave=true"), value)
            XCTAssertEqual(value.components(separatedBy: " | ")[1], before.components(separatedBy: " | ")[1])
            XCTAssertFalse(value.contains("service.enter edit"), value)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "minute-option-native-readiness-exact-draft"
        screenshot.lifetime = .keepAlways; add(screenshot)
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertTrue(app.staticTexts["07:00"].exists)
    }

    @MainActor
    func testReadinessRejectsCoveredAndDisabledControls() {
        alarmID = "6A000000-0000-4000-8000-000000000001"
        let app = launch(fixture: "ordinary", navigationAudit: true)
        rowButton("alarm.edit.", in: app).tap()
        let modeQuery = app.buttons.matching(identifier: "editor.mode")
        revealQuery(modeQuery, in: app)
        ready(modeQuery, in: app).tap()
        let covered = unique(modeQuery, in: app, timeout: 3)
        XCTAssertTrue(covered.isEnabled)
        XCTAssertFalse(covered.isHittable)
        XCTAssertFalse(waitUntilReady(covered, timeout: 3), "A covered control must not become ready")
        ready(app.buttons.matching(identifier: "Alarm only"), in: app, timeout: 3).tap()
        XCTAssertTrue(state(in: app).contains("hour=7; minute=0"))
        choose("editor.mode", "Challenges required", in: app)
        let disabled = unique(app.buttons.matching(identifier: "editor.save"), in: app)
        XCTAssertFalse(disabled.isEnabled)
        XCTAssertFalse(waitUntilReady(disabled, timeout: 3), "Disabled Save must not become ready")
        XCTAssertFalse(disabled.isEnabled)
        let value = state(in: app)
        XCTAssertTrue(value.contains("canSave=false"), value)
        XCTAssertTrue(value.contains("scheduler=missing"), value)
        XCTAssertFalse(value.contains("service.enter edit"), value)
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertTrue(app.staticTexts["07:00"].exists)
    }

    @MainActor
    private func state(in app: XCUIApplication) -> String {
        let element = unique(app.staticTexts.matching(identifier: "diagnostic.navigation.editor"), in: app)
        guard let value = element.value as? String else { XCTFail("Missing actual draft audit"); return "" }
        XCTAssertFalse(value.contains("audit-error:"), value)
        XCTAssertGreaterThanOrEqual(value.components(separatedBy: " | ").count, 2)
        return value
    }
}
