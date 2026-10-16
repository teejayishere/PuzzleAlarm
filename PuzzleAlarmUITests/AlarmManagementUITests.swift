import XCTest

@MainActor
final class AlarmManagementUITests: XCTestCase {
    func testDeniedNativeEnableReconcilesOffAndRemainsUsableAfterRelaunch() {
        let app = launch("toggle-denied", scenario: "disabledDenied")
        let id = "alarm.enabled." + seededID
        let status = app.staticTexts["alarm.status." + seededID]
        expectLabel(status, "Off")
        let row = app.switches.matching(identifier: id).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let inner = row.switches.firstMatch
        let control = inner.exists ? inner : row
        XCTAssertTrue(control.isEnabled && control.isHittable)
        XCTAssertEqual(control.value as? String, "0")
        // This command is rejected, so the exact required result is rollback to
        // Off, rather than the successful transition required by the tap helper.
        control.tap()
        XCTAssertTrue(app.staticTexts["application.error"].waitForExistence(timeout: 10))
        waitForOwner(app)
        XCTAssertEqual(control.value as? String, "0")
        XCTAssertTrue(control.isEnabled, "A rejected command must release pending input")
        expectLabel(status, "Off")
        relaunch(app)
        expectLabel(status, "Off")
        XCTAssertEqual(app.switches.matching(identifier: id).firstMatch.value as? String, "0")
    }

    func testEditorEnabledTogglePersistsAfterRepeatedNativeInput() {
        let app = launch("editor-toggle-baseline", scenario: "disabled")
        let rowID = "alarm.edit." + seededID
        let statusID = "alarm.status." + seededID
        expectLabel(app.staticTexts[statusID], "Off")
        tap(app, rowID)
        let control = app.switches.matching(identifier: "editor.enabled").firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        XCTAssertEqual(control.value as? String, "0")
        // Start Off, matching the list regression. Exercise the real local draft
        // binding with the same native input helper, without owner work per tap.
        for _ in 0..<11 { tap(app, "editor.enabled") }
        XCTAssertEqual(control.value as? String, "1")
        tap(app, "editor.save")
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 10))
        expectLabel(app.staticTexts[statusID], "On")
        relaunch(app)
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 10))
        expectLabel(app.staticTexts[statusID], "On")
        tap(app, rowID)
        tap(app, "editor.enabled")
        XCTAssertEqual(control.value as? String, "0")
        tap(app, "editor.save")
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 10))
        expectLabel(app.staticTexts[statusID], "Off")
        relaunch(app)
        XCTAssertTrue(app.buttons[rowID].waitForExistence(timeout: 10))
        expectLabel(app.staticTexts[statusID], "Off")
    }

    func testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch() {
        let app = launch("audio-preview")
        tap(app, "alarms.add")
        choose(app, "editor.sound", "Siren")
        tap(app, "editor.preview")
        expectPreview(app, playing: true)
        tap(app, "editor.preview")
        expectPreview(app, playing: false)
        tap(app, "editor.preview")
        expectPreview(app, playing: true)
        choose(app, "editor.sound", "Rapid Beeps")
        expectPreview(app, playing: false)
        tap(app, "editor.preview")
        expectPreview(app, playing: true)
        tap(app, "editor.repeat")
        back(app, from: "Repeat")
        tap(app, "editor.sound")
        let rapid = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Rapid Beeps")).firstMatch
        XCTAssertTrue(rapid.waitForExistence(timeout: 5)); rapid.tap()
        expectPreview(app, playing: false)
        tap(app, "editor.preview")
        expectPreview(app, playing: true)
        XCUIDevice.shared.press(.home)
        app.activate()
        expectPreview(app, playing: false)
        tap(app, "editor.save")
        let row = firstRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        tap(app, "editor.preview")
        expectPreview(app, playing: true)
        tap(app, "editor.cancel")
        relaunch(app)
        let restored = firstRow(app)
        XCTAssertTrue(restored.waitForExistence(timeout: 10))
        XCTAssertTrue(restored.label.contains("Rapid Beeps"), restored.label)
        restored.tap()
        tap(app, "editor.sound")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Rapid Beeps")).firstMatch.waitForExistence(timeout: 5))
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Rapid Beeps")).firstMatch.tap()
        expectPreview(app, playing: false)
    }
    private func expectPreview(_ app: XCUIApplication, playing: Bool) {
        let button = app.buttons["editor.preview"]
        let state = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", playing ? "Playing" : "Stopped"), object: button)
        XCTAssertEqual(XCTWaiter.wait(for: [state], timeout: 10), .completed, app.debugDescription)
    }
    private let seededID = "00000000-0000-0000-0000-000000000001"

    private func launch(_ name: String, scenario: String = "empty", largeText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchEnvironment = ["PUZZLE_UI_TEST": "1", "PUZZLE_RESET": "1",
                                 "PUZZLE_TEST_NAME": name, "PUZZLE_SCENARIO": scenario]
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 20))
        return app
    }
    private func element(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
    private func scroll(_ app: XCUIApplication, down: Bool) {
        guard let form = app.collectionViews.allElementsBoundByIndex.last(where: { $0.frame.intersects(app.frame) }) else {
            return XCTFail("No visible form to scroll\n" + app.debugDescription)
        }
        // Scroll along the form edge, away from the time wheel and sheet grabber.
        let start = form.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: down ? 0.3 : 0.7))
        let end = form.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: down ? 0.7 : 0.3))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
    private func tap(_ app: XCUIApplication, _ id: String) {
        let popup = app.popUpButtons.matching(identifier: id).firstMatch
        let button = app.buttons.matching(identifier: id).firstMatch
        // Switch roles are known from the product view. A broad Any query can
        // stall exporting the editor's large wheel-picker subtree during toggles.
        let toggle = app.switches.matching(identifier: id).firstMatch
        let isToggle = id == "editor.enabled" || id.hasPrefix("alarm.enabled.")
        func resolvedTarget() -> XCUIElement {
            if isToggle { return toggle }
            return popup.exists ? popup : (button.exists ? button : element(app, id))
        }
        var target = resolvedTarget()
        _ = target.waitForExistence(timeout: 3)
        for _ in 0..<6 {
            if target.exists && target.isHittable { break }
            scroll(app, down: false)
        }
        for _ in 0..<6 {
            if target.exists && target.isHittable { break }
            scroll(app, down: true)
        }
        // Offscreen SwiftUI rows can be absent from the initial snapshot. Resolve
        // their concrete role again after scrolling instead of keeping a broad query.
        target = resolvedTarget()
        XCTAssertTrue(target.waitForExistence(timeout: 5), id + "\n" + app.debugDescription)
        // A fresh positive state needs no polling. Slow accessibility round trips
        // must not turn an already-enabled control into a timed-out expectation.
        if !target.isEnabled {
            let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: target)
            let readiness = XCTWaiter.wait(for: [enabled], timeout: 10)
            if readiness != .completed {
                print("Management readiness failure for \(id):\n" + app.debugDescription)
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Management readiness \(id)"; attachment.lifetime = .keepAlways; add(attachment)
            }
            XCTAssertEqual(readiness, .completed, id)
        }
        XCTAssertTrue(target.isEnabled, id + "\n" + app.debugDescription)
        XCTAssertTrue(target.isHittable, id + "\n" + app.debugDescription)
        if target.elementType == .switch {
            let inner = target.switches.firstMatch
            let control = inner.exists ? inner : target
            XCTAssertTrue(control.isEnabled, id)
            XCTAssertTrue(control.isHittable, id)
            let before = control.value as? String
            XCTAssertTrue(before == "0" || before == "1", "Missing concrete switch value: " + id)
            control.tap()
            if id.hasPrefix("alarm.enabled.") { waitForOwner(app) }
            let expected = before == "0" ? "1" : "0"
            if (control.value as? String) != expected {
                let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: control)
                XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed,
                               "Switch input did not commit: " + id + "\n" + app.debugDescription)
            }
        } else { target.tap() }
        if id.hasPrefix("alarm.retry.") { waitForOwner(app) }
        if id == "alarms.add" {
            XCTAssertTrue(app.buttons["editor.save"].waitForExistence(timeout: 10))
        } else if id == "editor.repeat" {
            XCTAssertTrue(app.navigationBars["Repeat"].waitForExistence(timeout: 10))
        } else if id == "editor.save" {
            let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                     object: app.buttons["editor.save"])
            XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 15), .completed, app.debugDescription)
        }
    }
    private func choose(_ app: XCUIApplication, _ id: String, _ title: String) {
        tap(app, id)
        let choice = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", title)).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), title + "\n" + app.debugDescription)
        choice.tap()
    }
    private func expectLabel(_ element: XCUIElement, _ text: String) {
        // A positive concrete observation needs no polling. A slow AX request can
        // consume the poll budget even when its resulting label already matches.
        if element.label == text { return }
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: 10), .completed, "Expected \(text), found \(element.label)")
    }
    private func waitForOwner(_ app: XCUIApplication) {
        let busy = element(app, "application.busy")
        if busy.exists {
            let finished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: busy)
            XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 30), .completed,
                           "Alarm operation did not finish\n" + app.debugDescription)
        }
        XCTAssertFalse(busy.exists, "Alarm owner is still busy\n" + app.debugDescription)
    }
    private func back(_ app: XCUIApplication, from title: String) {
        app.navigationBars[title].buttons.element(boundBy: 0).tap()
    }
    private func firstRow(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit.")).firstMatch
    }
    private func relaunch(_ app: XCUIApplication) {
        app.terminate()
        app.launchEnvironment["PUZZLE_RESET"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons["alarms.add"].waitForExistence(timeout: 20))
    }
    private func time(_ app: XCUIApplication, hour: String, minute: String) {
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.element(boundBy: 0).waitForExistence(timeout: 5))
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: hour)
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: minute)
        if wheels.count > 2 { wheels.element(boundBy: 2).adjust(toPickerWheelValue: "AM") }
    }
    private func increment(_ app: XCUIApplication, _ id: String) {
        let stepper = app.steppers[id]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons.element(boundBy: 1).tap()
    }

    func testEmptyAddPersistsTimeWeekdaysModeAndSoundAcrossRelaunch() {
        let app = launch("add")
        XCTAssertTrue(app.staticTexts["No alarms"].waitForExistence(timeout: 10))
        tap(app, "alarms.add")
        time(app, hour: "8", minute: "30")
        tap(app, "editor.repeat"); tap(app, "repeat.weekdays"); back(app, from: "Repeat")
        choose(app, "editor.sound", "Siren")
        tap(app, "editor.save")
        let row = firstRow(app)
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        let id = row.identifier
        XCTAssertTrue(row.label.contains("8:30") && row.label.contains("Weekdays"))
        XCTAssertTrue(row.label.contains("Annoying Alarm Only") && row.label.contains("Siren"))
        relaunch(app)
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[id].label.contains("8:30"))
    }

    func testChallengeConfigurationOrderAndSettingsSurviveSaveReloadAndEdit() {
        let app = launch("challenges")
        tap(app, "alarms.add")
        choose(app, "editor.mode", "Challenges Required")
        XCTAssertFalse(app.buttons["editor.save"].isEnabled)
        tap(app, "challenge.add.memory")
        tap(app, "challenge.add.math")
        tap(app, "challenge.add.qr")
        tap(app, "challenge.configure.memory")
        choose(app, "memory.difficulty", "Hard")
        increment(app, "memory.length"); increment(app, "memory.duration"); increment(app, "memory.rounds")
        back(app, from: "Memory")
        tap(app, "challenge.configure.math")
        choose(app, "math.difficulty", "Hard"); increment(app, "math.count")
        back(app, from: "Math")
        tap(app, "challenge.up.math")
        tap(app, "editor.save")
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Math → Memory → QR Code"))
        relaunch(app)
        firstRow(app).tap()
        XCTAssertTrue(element(app, "challenge.order.math").waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "challenge.order.math").label, "1. Math")
        tap(app, "challenge.configure.memory")
        XCTAssertTrue(app.staticTexts["Sequence length: 9"].exists)
        XCTAssertTrue(app.staticTexts["Display seconds: 4"].exists)
        XCTAssertTrue(app.staticTexts["Successful rounds: 2"].exists)
        back(app, from: "Memory")
        tap(app, "challenge.configure.math")
        XCTAssertTrue(app.staticTexts["Correct answers: 6"].exists)
    }

    func testEnableDisableAndFailureRetryAreHonest() {
        let app = launch("toggle", scenario: "enableFailure")
        let status = app.staticTexts["alarm.status." + seededID]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        expectLabel(status, "Off")
        tap(app, "alarm.enabled." + seededID)
        XCTAssertTrue(app.buttons["alarm.retry." + seededID].waitForExistence(timeout: 10))
        expectLabel(status, "Needs attention")
        tap(app, "alarm.retry." + seededID)
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        expectLabel(status, "On")
        tap(app, "alarm.enabled." + seededID)
        expectLabel(status, "Off")
        tap(app, "alarm.enabled." + seededID)
        expectLabel(status, "On")
    }

    func testEditChangesConfigurationWithoutChangingIdentity() {
        let app = launch("edit", scenario: "healthy")
        let id = "alarm.edit." + seededID
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        app.buttons[id].tap()
        time(app, hour: "9", minute: "15")
        tap(app, "editor.repeat"); tap(app, "repeat.weekends"); back(app, from: "Repeat")
        choose(app, "editor.mode", "Challenges Required")
        tap(app, "challenge.add.math")
        choose(app, "editor.sound", "Rapid Beeps")
        tap(app, "editor.save")
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[id].label.contains("9:15") && app.buttons[id].label.contains("Weekends"), app.buttons[id].label)
        XCTAssertTrue(app.buttons[id].label.contains("Math") && app.buttons[id].label.contains("Rapid Beeps"))
        relaunch(app)
        XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit.")).count, 1)
    }

    func testDeleteConfirmationCancelAndSuccessfulCleanup() {
        let app = launch("delete", scenario: "healthy")
        let row = app.buttons["alarm.edit." + seededID]
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        tap(app, "editor.delete")
        XCTAssertTrue(app.buttons["Keep Alarm"].waitForExistence(timeout: 5))
        tap(app, "editor.keep")
        XCTAssertTrue(app.buttons["editor.save"].exists)
        tap(app, "editor.delete")
        tap(app, "editor.confirmDelete")
        XCTAssertTrue(app.staticTexts["No alarms"].waitForExistence(timeout: 10))
        XCTAssertFalse(row.exists)
    }

    func testDeleteCleanupFailureKeepsAlarmVisible() {
        let app = launch("deleteFailure", scenario: "deleteFailure")
        let row = app.buttons["alarm.edit." + seededID]
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.tap()
        tap(app, "editor.delete")
        tap(app, "editor.confirmDelete")
        XCTAssertTrue(app.staticTexts["editor.error"].waitForExistence(timeout: 10))
        tap(app, "editor.cancel")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["alarm.status." + seededID].label, "Cleanup pending")
    }

    func testOneTimeAndCancelDraftRemainDistinctFromDaily() {
        let app = launch("once")
        tap(app, "alarms.add")
        tap(app, "editor.repeat"); tap(app, "repeat.everyday"); back(app, from: "Repeat")
        tap(app, "editor.cancel")
        XCTAssertTrue(app.staticTexts["No alarms"].exists)
        tap(app, "alarms.add")
        tap(app, "editor.save")
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Once"))
        XCTAssertFalse(firstRow(app).label.contains("Every day"))
        relaunch(app)
        XCTAssertTrue(firstRow(app).waitForExistence(timeout: 10))
        XCTAssertTrue(firstRow(app).label.contains("Once"))
    }

    func testAuthorizationAndLargeTextControls() {
        let app = launch("access", scenario: "notDetermined", largeText: true)
        XCTAssertEqual(app.staticTexts["authorization.status"].label, "Not requested")
        tap(app, "authorization.request")
        XCTAssertEqual(app.staticTexts["authorization.status"].label, "Authorized")
        tap(app, "alarms.add")
        XCTAssertTrue(app.buttons["editor.cancel"].isHittable && app.buttons["editor.save"].isHittable)
        app.terminate()
        let denied = launch("denied", scenario: "denied")
        XCTAssertEqual(denied.staticTexts["authorization.status"].label, "Denied")
        XCTAssertTrue(denied.buttons["authorization.settings"].exists)
        XCTAssertFalse(denied.buttons["authorization.request"].exists)
    }
}
