import XCTest

class ChallengeUITestCase: AlarmUITestCase, @unchecked Sendable {
    let math = "math:medium:5"
    let memory = "memory:hard:8:2.5:2"
    let qr = "qr:6A000000-0000-4000-8000-000000000003"

    @MainActor
    func open(_ fixture: String = "challenge") -> (XCUIApplication, String) {
        alarmID = fixture == "ordinary" ? "6A000000-0000-4000-8000-000000000001"
            : "6A000000-0000-4000-8000-000000000002"
        let app = launch(fixture: fixture, navigationAudit: true, challengeAudit: true)
        let before = disk(in: app, context: "list")
        rowButton("alarm.edit.", in: app).tap()
        XCTAssertTrue(app.navigationBars["Edit alarm"].waitForExistence(timeout: 10))
        return (app, before)
    }

    @MainActor
    func audit(in app: XCUIApplication, context: String = "editor") -> String {
        let element = unique(app.staticTexts.matching(identifier: "diagnostic.navigation." + context), in: app)
        guard let value = element.value as? String else { XCTFail("Missing actual draft/disk audit"); return "" }
        XCTAssertFalse(value.contains("audit-error:"), value)
        return value
    }

    @MainActor
    func assertDraft(_ values: [String], in app: XCUIApplication,
                     mode: String = "challenges_required", canSave: Bool = true) {
        let value = audit(in: app).components(separatedBy: " | ")[0]
        XCTAssertEqual(value, "id=\(alarmID!); original=\(alarmID!); mode=\(mode); hour=7; minute=0; weekdays=[2, 6]; enabled=false; soundIndex=0; canSave=\(canSave); challenges=[\(values.joined(separator: ","))]")
        XCTAssertEqual(unique(app.buttons.matching(identifier: "editor.save"), in: app).isEnabled, canSave)
    }

    @MainActor
    func disk(in app: XCUIApplication, context: String = "editor") -> String {
        let parts = audit(in: app, context: context).components(separatedBy: " | ")
        XCTAssertGreaterThanOrEqual(parts.count, 2)
        guard parts.count >= 2 else { return "" }
        XCTAssertTrue(parts[1].hasPrefix("disk="), parts[1])
        XCTAssertTrue(parts[1].hasSuffix("scheduler=missing"), parts[1])
        return parts[1]
    }

    @MainActor
    func noMutation(in app: XCUIApplication, context: String = "editor") {
        let value = audit(in: app, context: context)
        XCTAssertTrue(value.contains("service.enter refresh"), value)
        for command in ["create", "edit", "enable", "disable", "delete", "retry"] {
            XCTAssertFalse(value.contains("service.enter " + command), value)
        }
    }

    @MainActor
    func button(_ id: String, in app: XCUIApplication) -> XCUIElement {
        let query = app.buttons.matching(identifier: id)
        revealQuery(query, in: app)
        return ready(query, in: app)
    }

    @MainActor
    func increment(_ id: String, in app: XCUIApplication) {
        let query = app.steppers.matching(identifier: id)
        revealQuery(query, in: app)
        let control = ready(query, in: app)
        ready(control.buttons.matching(identifier: id + "-Increment"), in: app, timeout: 3).tap()
    }

    @MainActor
    func screenshot(in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name + "-exact-challenge-draft"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor
    func cancel(_ app: XCUIApplication, before: String, original: [String],
                mode: String = "challenges_required") {
        XCTAssertEqual(disk(in: app), before)
        noMutation(in: app); screenshot(in: app)
        button("editor.cancel", in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertEqual(disk(in: app, context: "list"), before)
        noMutation(in: app, context: "list")
        relaunch(app)
        XCTAssertEqual(disk(in: app, context: "list"), before)
        rowButton("alarm.edit.", in: app).tap()
        assertDraft(original, in: app, mode: mode)
        noMutation(in: app)
    }

    @MainActor
    func saveAndReopen(_ app: XCUIApplication, before: String, expected: [String],
                       mode: String = "challenges_required", changesDefinition: Bool = true) {
        XCTAssertEqual(disk(in: app), before); noMutation(in: app); screenshot(in: app)
        button("editor.save", in: app).tap()
        _ = rowButton("alarm.edit.", in: app)
        let saved = disk(in: app, context: "list")
        if changesDefinition { XCTAssertNotEqual(saved, before) }
        XCTAssertTrue(audit(in: app, context: "list").contains("service.enter edit"))
        relaunch(app)
        XCTAssertEqual(disk(in: app, context: "list"), saved)
        noMutation(in: app, context: "list")
        rowButton("alarm.edit.", in: app).tap()
        assertDraft(expected, in: app, mode: mode)
        noMutation(in: app)
        XCTAssertEqual(disk(in: app), saved)
    }
}
