import XCTest

final class ListNavigationUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testEmptyAndNewEditorsCancelWithoutWrites() {
        let app = launch(navigationAudit: true)
        let before = diskAudit(in: app)
        for afterRelaunch in [false, true] {
            if afterRelaunch { relaunch(app) }
            XCTAssertTrue(app.staticTexts["alarms.empty"].exists)
            XCTAssertFalse(app.staticTexts["alarms.ready"].exists)
            ready(app.buttons.matching(identifier: "alarms.add"), in: app).tap()
            XCTAssertTrue(app.navigationBars["New alarm"].waitForExistence(timeout: 10))
            let original = navigationState("editor", in: app)
            XCTAssertTrue(original.contains("original=new"))
            assertSwitch(unique(app.switches.matching(identifier: "editor.enabled"), in: app), isOn: true)
            // A new challenge editor is also only a draft; cancel must not save it.
            choose("editor.mode", "Challenges required", in: app)
            XCTAssertFalse(unique(app.buttons.matching(identifier: "editor.save"), in: app).isEnabled)
            ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
            _ = ready(app.buttons.matching(identifier: "alarms.add"), in: app)
            XCTAssertTrue(app.staticTexts["alarms.empty"].exists)
            XCTAssertEqual(diskAudit(in: app), before)
            assertNoMutationCommand(in: app)
        }
    }

    @MainActor
    func testOrdinaryEditorOpensBeforeAndAfterRelaunch() {
        checkExistingEditor(fixture: "ordinary", id: "6A000000-0000-4000-8000-000000000001",
                            mode: "annoying_only")
    }

    @MainActor
    func testChallengeEditorOpensBeforeAndAfterRelaunch() {
        checkExistingEditor(fixture: "challenge", id: "6A000000-0000-4000-8000-000000000002",
                            mode: "challenges_required")
    }

    @MainActor
    private func checkExistingEditor(fixture: String, id: String, mode: String) {
        alarmID = id
        let app = launch(fixture: fixture, navigationAudit: true)
        let before = diskAudit(in: app)
        for afterRelaunch in [false, true] {
            if afterRelaunch { relaunch(app) }
            XCTAssertTrue(app.staticTexts["alarms.ready"].exists)
            XCTAssertFalse(app.staticTexts["alarms.empty"].exists)
            let edit = rowButton("alarm.edit.", in: app)
            XCTAssertEqual(edit.identifier, "alarm.edit." + id)
            edit.tap()
            XCTAssertTrue(app.navigationBars["Edit alarm"].waitForExistence(timeout: 10))
            let state = navigationState("editor", in: app)
            XCTAssertTrue(state.contains("id=\(id); original=\(id); mode=\(mode)"), state)
            let hour = unique(app.buttons.matching(identifier: "editor.hour"), in: app)
            XCTAssertTrue((hour.label + String(describing: hour.value)).contains("07"), hour.debugDescription)
            let minute = unique(app.buttons.matching(identifier: "editor.minute"), in: app)
            XCTAssertTrue((minute.label + String(describing: minute.value)).contains("00"), minute.debugDescription)
            assertSwitch(unique(app.switches.matching(identifier: "editor.enabled"), in: app), isOn: false)
            assertSwitch(unique(app.switches.matching(identifier: "editor.day.2"), in: app), isOn: true)
            ready(app.buttons.matching(identifier: "editor.cancel"), in: app).tap()
            _ = rowButton("alarm.edit.", in: app)
            XCTAssertEqual(diskAudit(in: app), before)
            assertNoMutationCommand(in: app)
        }
    }

    @MainActor
    func testLoadingKeepsEditingUnavailable() {
        let app = XCUIApplication()
        app.launchEnvironment["PUZZLEALARM_TEST_NAMESPACE"] = namespace
        app.launchEnvironment["PUZZLEALARM_TEST_FIXTURE"] = "empty"
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-hold-load"]
        app.launch()
        XCTAssertTrue(app.staticTexts["alarms.loading"].waitForExistence(timeout: 10))
        XCTAssertFalse(unique(app.buttons.matching(identifier: "alarms.add"), in: app).isEnabled)
        XCTAssertFalse(unique(app.buttons.matching(identifier: "alarms.refresh"), in: app).isEnabled)
        XCTAssertFalse(app.staticTexts["alarms.empty"].exists)
        XCTAssertFalse(app.staticTexts["alarms.ready"].exists)
        XCTAssertFalse(app.staticTexts["alarms.error"].exists)
        app.terminate()
    }

    @MainActor
    func testCorruptLoadStaysReadOnlyAcrossRefresh() {
        fixture = "corrupt"
        let app = XCUIApplication()
        app.launchEnvironment["PUZZLEALARM_TEST_NAMESPACE"] = namespace
        app.launchEnvironment["PUZZLEALARM_TEST_FIXTURE"] = "corrupt"
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-navigation-audit"]
        app.launch()
        XCTAssertTrue(app.staticTexts["alarms.error"].waitForExistence(timeout: 10))
        XCTAssertFalse(unique(app.buttons.matching(identifier: "alarms.add"), in: app).isEnabled)
        XCTAssertFalse(app.staticTexts["alarms.empty"].exists)
        XCTAssertFalse(app.staticTexts["alarms.ready"].exists)
        XCTAssertFalse(app.staticTexts["alarms.loading"].exists)
        let before = diskAudit(in: app)
        ready(app.buttons.matching(identifier: "alarms.refresh"), in: app).tap()
        _ = ready(app.buttons.matching(identifier: "alarms.refresh"), in: app)
        XCTAssertTrue(app.staticTexts["alarms.error"].exists)
        XCTAssertFalse(unique(app.buttons.matching(identifier: "alarms.add"), in: app).isEnabled)
        XCTAssertEqual(diskAudit(in: app), before)
        assertNoMutationCommand(in: app)
    }

    @MainActor
    private func navigationState(_ context: String, in app: XCUIApplication) -> String {
        let element = unique(app.staticTexts.matching(identifier: "diagnostic.navigation." + context), in: app)
        guard let value = element.value as? String else { XCTFail("Missing navigation audit"); return "" }
        XCTAssertFalse(value.contains("audit-error:"), value)
        return value
    }

    @MainActor
    private func diskAudit(in app: XCUIApplication) -> String {
        let value = navigationState("list", in: app)
        let parts = value.components(separatedBy: " | ")
        XCTAssertGreaterThanOrEqual(parts.count, 2)
        guard parts.count >= 2 else { return "" }
        XCTAssertTrue(parts[1].hasPrefix("disk="), value)
        XCTAssertTrue(parts[1].hasSuffix("scheduler=missing"), value)
        return parts[1]
    }

    @MainActor
    private func assertNoMutationCommand(in app: XCUIApplication) {
        let value = navigationState("list", in: app)
        XCTAssertTrue(value.contains("service.enter refresh"), value)
        for command in ["create", "edit", "enable", "disable", "delete", "retry"] {
            XCTAssertFalse(value.contains("service.enter " + command), value)
        }
    }
}
