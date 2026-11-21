import XCTest

class AlarmUITestCase: XCTestCase, @unchecked Sendable {
    var namespace = UUID().uuidString
    var fixture = "empty"
    var alarmID: String?

    override func setUpWithError() throws { continueAfterFailure = false }

    // XCTest reports issues on the test's main thread. Capture before an assertion
    // aborts the flow; the observer enumerates snapshots and makes no assertions.
    override func record(_ issue: XCTIssue) {
        let description = issue.compactDescription
        if Thread.isMainThread {
            MainActor.assumeIsolated { capture("failure-\(description)", in: XCUIApplication()) }
        }
        super.record(issue)
    }

    @MainActor
    func launch(failing: Bool = false, fixture: String = "empty", diagnostics: Bool = false,
                probe: Bool = false, reset: Bool = true, navigationAudit: Bool = false) -> XCUIApplication {
        self.fixture = fixture
        let app = XCUIApplication()
        app.launchEnvironment["PUZZLEALARM_TEST_NAMESPACE"] = namespace
        app.launchEnvironment["PUZZLEALARM_TEST_FIXTURE"] = fixture
        app.launchArguments = ["--ui-testing"] + (reset ? ["--ui-reset"] : [])
            + (diagnostics ? ["--ui-switch-diagnostics"] : [])
            + (probe ? ["--ui-switch-probe"] : [])
            + (navigationAudit ? ["--ui-navigation-audit"] : [])
            + (failing ? ["--ui-schedule-failure"] : [])
        app.launch()
        if !probe {
            _ = ready(app.buttons.matching(identifier: "alarms.add"), in: app)
            if reset && fixture == "empty" {
                XCTAssertTrue(app.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
            }
        }
        return app
    }

    @MainActor
    func relaunch(_ app: XCUIApplication) {
        app.terminate()
        app.launchArguments.removeAll { $0 == "--ui-reset" }
        app.launch()
        _ = ready(app.buttons.matching(identifier: "alarms.add"), in: app)
    }

    @MainActor
    func unique(_ query: XCUIElementQuery, in app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let wait = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 1"), object: query)
        let result = XCTWaiter.wait(for: [wait], timeout: timeout)
        if result != .completed { capture("unique count=\(query.count) query=\(query)", in: app) }
        XCTAssertEqual(result, .completed, "Exactly one intended match required: \(query)")
        XCTAssertEqual(query.count, 1)
        return query.element
    }

    @MainActor
    func ready(_ query: XCUIElementQuery, in app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let element = unique(query, in: app, timeout: timeout)
        let wait = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: element)
        let result = XCTWaiter.wait(for: [wait], timeout: timeout)
        if result != .completed { capture("not ready query=\(query)", in: app) }
        XCTAssertEqual(result, .completed, "Intended control must be enabled and hittable")
        return element
    }

    @MainActor
    func rememberCreatedAlarm(in app: XCUIApplication) {
        // Creation intentionally retains production UUID generation. Resolve the
        // single created identity once, then use that exact ID for every action.
        let query = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit."))
        let element = unique(query, in: app)
        let suffix = String(element.identifier.dropFirst("alarm.edit.".count))
        XCTAssertNotNil(UUID(uuidString: suffix))
        alarmID = suffix
    }

    @MainActor
    func rowButton(_ prefix: String, in app: XCUIApplication) -> XCUIElement {
        guard let alarmID else { XCTFail("Resolve the intended alarm ID before querying a row"); return app.buttons.element }
        let query = app.buttons.matching(identifier: prefix + alarmID)
        reveal(unique(query, in: app), in: app)
        return ready(query, in: app)
    }

    @MainActor
    func rowSwitch(in app: XCUIApplication) -> XCUIElement {
        guard let alarmID else { XCTFail("Missing intended alarm ID"); return app.switches.element }
        return ready(app.switches.matching(identifier: "alarm.enabled." + alarmID), in: app)
    }

    @MainActor
    func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for upward in [true, false] {
            for _ in 0..<12 {
                if element.exists && element.isHittable { return }
                if upward { app.swipeUp() } else { app.swipeDown() }
            }
        }
        capture("Control not reachable: \(element)", in: app)
        XCTFail("Control not reachable: \(element)")
    }

    @MainActor
    func reveal(_ query: XCUIElementQuery, in app: XCUIApplication) {
        // Lazy Form/List content may have no accessibility element until scrolled
        // into view. Never dereference an absent or ambiguous query while finding it.
        for upward in [true, false] {
            for _ in 0..<12 {
                let count = query.count
                guard count <= 1 else {
                    capture("Ambiguous control while revealing query: \(query)", in: app)
                    XCTFail("Exactly one intended match required while revealing")
                    return
                }
                if count == 1 && query.element.isHittable { return }
                if upward { app.swipeUp() } else { app.swipeDown() }
            }
        }
        capture("Query not reachable: \(query)", in: app)
        XCTFail("Control not reachable within the existing scroll bound")
    }

    @MainActor
    func choose(_ id: String, _ title: String, in app: XCUIApplication) {
        let query = app.buttons.matching(identifier: id)
        reveal(query, in: app)
        let picker = ready(query, in: app)
        picker.tap()
        ready(app.buttons.matching(identifier: title), in: app, timeout: 3).tap()
    }

    @MainActor
    func assertSwitch(_ element: XCUIElement, isOn: Bool) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let pending = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@ AND enabled == true", isOn ? "1" : "0"), object: element)
        let result = XCTWaiter.wait(for: [pending], timeout: 10)
        if result != .completed { capture("switch expected=\(isOn)", in: XCUIApplication()) }
        XCTAssertEqual(result, .completed)
    }

    @MainActor
    func tapSwitch(_ element: XCUIElement, to expected: Bool, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(element.isEnabled)
        XCTAssertTrue(element.isHittable)
        let children = element.children(matching: .switch)
        XCTAssertEqual(children.count, 1, "Expected the evidenced single native switch child")
        let child = children.element
        XCTAssertTrue(child.isEnabled && child.isHittable)
        let diagnostic = app.launchArguments.contains("--ui-switch-diagnostics")
        if diagnostic { capture("before-one-native-tap expected=\(expected)", in: app) }
        child.tap()
        if diagnostic { capture("after-one-native-tap expected=\(expected)", in: app) }
    }

    @MainActor
    func capture(_ phase: String, in app: XCUIApplication) {
        // Filter in the accessibility query. Reading every descendant's identifier
        // in Swift repeatedly resolves the entire tree and can consume the run.
        let controls = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ OR identifier BEGINSWITH %@ OR identifier BEGINSWITH %@ OR identifier == %@",
            "alarm.", "editor.", "diagnostic.", "alarms.add")).allElementsBoundByIndex
        let details = controls.enumerated().map { index, element in
            let value = element.value
            let type = value.map { String(reflecting: Swift.type(of: $0)) } ?? "nil"
            return "[\(index)] id=\(element.identifier) label=\(element.label) value=\(String(describing: value)) type=\(type) enabled=\(element.isEnabled) hittable=\(element.isHittable) frame=\(element.frame) children=\(element.children(matching: .switch).count)"
        }.joined(separator: "\n")
        let text = "fixture=\(fixture) namespace=\(namespace) intendedID=\(alarmID ?? "unresolved") phase=\(phase)\n\(details)\n\(app.debugDescription)"
        print(text)
        let hierarchy = XCTAttachment(string: text)
        hierarchy.name = "\(name)-\(phase.prefix(100))-hierarchy"
        hierarchy.lifetime = .keepAlways; add(hierarchy)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(name)-\(phase.prefix(100))-screen"
        screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
