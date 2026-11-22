import XCTest

final class DraftEditingUITests: AlarmUITestCase, @unchecked Sendable {
    private let ordinaryID = "6A000000-0000-4000-8000-000000000001"

    @MainActor
    func testTimeEditsStayInDraftAndCancel() {
        let (app, before) = openOrdinary()
        choose("editor.hour", "08", in: app)
        choose("editor.minute", "05", in: app)
        assertDraft(in: app, hour: 8, minute: 5)
        cancelAndCheck(app, before: before)
    }

    @MainActor
    func testWeekdayEditsStayInDraftAndCancel() {
        let (app, before) = openOrdinary()
        changeSwitch("editor.day.2", to: false, in: app)
        changeSwitch("editor.day.4", to: true, in: app)
        assertDraft(in: app, weekdays: "[4, 6]")
        cancelAndCheck(app, before: before)
    }

    @MainActor
    func testEnabledEditStaysInDraftAndCancel() {
        let (app, before) = openOrdinary()
        changeSwitch("editor.enabled", to: true, in: app)
        assertDraft(in: app, enabled: true)
        cancelAndCheck(app, before: before)
    }

    @MainActor
    func testSoundSelectionStaysInDraftAndCancel() {
        let (app, before) = openOrdinary()
        choose("editor.sound", "Siren", in: app)
        assertDraft(in: app, sound: 3)
        cancelAndCheck(app, before: before)
    }

    @MainActor
    func testInvalidChallengeDraftDisablesSaveWithoutWrites() {
        let (app, before) = openOrdinary()
        choose("editor.mode", "Challenges required", in: app)
        assertDraft(in: app, mode: "challenges_required", canSave: false)
        XCTAssertFalse(unique(app.buttons.matching(identifier: "editor.save"), in: app).isEnabled)
        cancelAndCheck(app, before: before)
    }

    @MainActor
    func testSavedTimeAndSoundReopenFromDisk() {
        let (app, before) = openOrdinary()
        choose("editor.hour", "08", in: app)
        choose("editor.minute", "05", in: app)
        choose("editor.sound", "Siren", in: app)
        assertDraft(in: app, hour: 8, minute: 5, sound: 3)
        XCTAssertEqual(diskAudit("editor", in: app), before)
        assertNoMutation("editor", in: app)
        ready(app.buttons.matching(identifier: "editor.save"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        let saved = diskAudit("list", in: app)
        XCTAssertNotEqual(saved, before)
        XCTAssertTrue(audit("list", in: app).contains("service.enter edit"))
        XCTAssertTrue(app.staticTexts["08:05"].exists)
        XCTAssertTrue(app.staticTexts["Siren"].exists)
        relaunch(app)
        XCTAssertEqual(diskAudit("list", in: app), saved)
        assertSwitch(rowSwitch(in: app), isOn: false)
        rowButton("alarm.edit.", in: app).tap()
        assertDraft(in: app, hour: 8, minute: 5, sound: 3)
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertEqual(diskAudit("list", in: app), saved)
        assertNoMutation("list", in: app)
    }

    @MainActor
    private func openOrdinary() -> (XCUIApplication, String) {
        alarmID = ordinaryID
        let app = launch(fixture: "ordinary", navigationAudit: true)
        let before = diskAudit("list", in: app)
        rowButton("alarm.edit.", in: app).tap()
        XCTAssertTrue(app.navigationBars["Edit alarm"].waitForExistence(timeout: 10))
        assertDraft(in: app)
        return (app, before)
    }

    @MainActor
    private func changeSwitch(_ id: String, to value: Bool, in app: XCUIApplication) {
        let query = app.switches.matching(identifier: id)
        revealQuery(query, in: app)
        let control = ready(query, in: app)
        assertSwitch(control, isOn: !value)
        tapSwitch(control, to: value, in: app)
        assertSwitch(control, isOn: value)
    }

    @MainActor
    private func assertDraft(in app: XCUIApplication, hour: Int = 7, minute: Int = 0,
                             weekdays: String = "[2, 6]", enabled: Bool = false,
                             sound: Int = 0, mode: String = "annoying_only", canSave: Bool = true) {
        let state = audit("editor", in: app).components(separatedBy: " | ")[0]
        XCTAssertEqual(state, "id=\(ordinaryID); original=\(ordinaryID); mode=\(mode); hour=\(hour); minute=\(minute); weekdays=\(weekdays); enabled=\(enabled); soundIndex=\(sound); canSave=\(canSave)")
        XCTAssertEqual(unique(app.buttons.matching(identifier: "editor.save"), in: app).isEnabled, canSave)
    }

    @MainActor
    private func cancelAndCheck(_ app: XCUIApplication, before: String) {
        XCTAssertEqual(diskAudit("editor", in: app), before)
        assertNoMutation("editor", in: app)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name + "-edited-draft"; screenshot.lifetime = .keepAlways; add(screenshot)
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertEqual(diskAudit("list", in: app), before)
        assertNoMutation("list", in: app)
        relaunch(app)
        XCTAssertEqual(diskAudit("list", in: app), before)
        assertNoMutation("list", in: app)
        rowButton("alarm.edit.", in: app).tap()
        assertDraft(in: app)
        ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertEqual(diskAudit("list", in: app), before)
        assertNoMutation("list", in: app)
    }

    @MainActor
    private func audit(_ context: String, in app: XCUIApplication) -> String {
        let element = unique(app.staticTexts.matching(identifier: "diagnostic.navigation." + context), in: app)
        guard let value = element.value as? String else { XCTFail("Missing audit"); return "" }
        XCTAssertFalse(value.contains("audit-error:"), value)
        return value
    }

    @MainActor
    private func diskAudit(_ context: String, in app: XCUIApplication) -> String {
        let parts = audit(context, in: app).components(separatedBy: " | ")
        XCTAssertGreaterThanOrEqual(parts.count, 2)
        guard parts.count >= 2 else { return "" }
        XCTAssertTrue(parts[1].hasPrefix("disk="))
        XCTAssertTrue(parts[1].hasSuffix("scheduler=missing"))
        return parts[1]
    }

    @MainActor
    private func assertNoMutation(_ context: String, in app: XCUIApplication) {
        let value = audit(context, in: app)
        XCTAssertTrue(value.contains("service.enter refresh"), value)
        for command in ["create", "edit", "enable", "disable", "delete", "retry"] {
            XCTAssertFalse(value.contains("service.enter " + command), value)
        }
    }
}
