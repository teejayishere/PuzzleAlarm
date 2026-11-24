import XCTest

class AlarmUITestCase: XCTestCase, @unchecked Sendable {
    var namespace = UUID().uuidString
    var fixture = "empty"
    var alarmID: String?
    let captureJournal = FailureCaptureJournal()

    override func setUpWithError() throws { continueAfterFailure = false }

    // Forward the original issue before optional diagnostics. Accessibility queries
    // can themselves report issues, so this callback must never collect snapshots.
    override func record(_ issue: XCTIssue) {
        let location = issue.sourceCodeContext.location
        let description = "\(issue.compactDescription) source=\(location?.fileURL.path ?? "unknown"):\(location?.lineNumber ?? 0)"
        captureJournal.noteIssue(description)
        print("Forwarding original XCTest issue: \(description); phase=\(captureJournal.snapshot.phase)")
        super.record(issue)
    }

    override func tearDownWithError() throws {
        let pending = captureJournal.takePending()
        if !pending.isEmpty {
            if Thread.isMainThread {
                MainActor.assumeIsolated { capture("recorded-issues: " + pending.joined(separator: " | "), in: XCUIApplication()) }
            } else {
                let text = "Diagnostic collection omitted: teardown is not on main thread. Recorded issues: \(pending)"
                print(text)
                let attachment = XCTAttachment(string: text)
                attachment.name = name + "-diagnostic-omission"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
        try super.tearDownWithError()
    }

    @MainActor
    func applicationTransition(_ phase: String, endingAt finalPhase: String = "ready", _ operation: () -> Void) {
        captureJournal.setPhase("transition: " + phase)
        operation()
        // If XCTest aborts the operation, do not claim that transition completed.
        captureJournal.completePhase(finalPhase)
    }

    @MainActor
    func launch(failing: Bool = false, fixture: String = "empty", diagnostics: Bool = false,
                probe: Bool = false, reset: Bool = true, navigationAudit: Bool = false,
                challengeAudit: Bool = false) -> XCUIApplication {
        self.fixture = fixture
        let app = XCUIApplication()
        app.launchEnvironment["PUZZLEALARM_TEST_NAMESPACE"] = namespace
        app.launchEnvironment["PUZZLEALARM_TEST_FIXTURE"] = fixture
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"] + (reset ? ["--ui-reset"] : [])
            + (diagnostics ? ["--ui-switch-diagnostics"] : [])
            + (probe ? ["--ui-switch-probe"] : [])
            + (navigationAudit ? ["--ui-navigation-audit"] : [])
            + (challengeAudit ? ["--ui-challenge-audit"] : [])
            + (failing ? ["--ui-schedule-failure"] : [])
        applicationTransition("launch fixture=\(fixture)") { app.launch() }
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
        applicationTransition("terminate/relaunch fixture=\(fixture)") {
            app.terminate()
            app.launchArguments.removeAll { $0 == "--ui-reset" }
            app.launch()
        }
        _ = ready(app.buttons.matching(identifier: "alarms.add"), in: app)
    }

    @MainActor
    func unique(_ query: XCUIElementQuery, in app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        // Use XCTest's element wait instead of repeatedly evaluating a remote
        // query count inside a predicate expectation. .element retains XCTest's
        // ambiguity check; cardinality is also asserted explicitly before use.
        let started = Date.timeIntervalSinceReferenceDate
        let element = query.element
        let exists = element.waitForExistence(timeout: timeout)
        let waited = Date.timeIntervalSinceReferenceDate - started
        let countStarted = Date.timeIntervalSinceReferenceDate
        let count = query.count
        let counted = Date.timeIntervalSinceReferenceDate - countStarted
        print("Exact lookup fixture=\(fixture) intendedID=\(alarmID ?? "new") timeout=\(timeout) exists=\(exists) nativeSeconds=\(waited) count=\(count) countSeconds=\(counted) query=\(query)")
        if !exists || count != 1 { capture("unique exists=\(exists) count=\(count) query=\(query)", in: app) }
        XCTAssertTrue(exists, "Intended element must exist within the unchanged wait: \(query)")
        XCTAssertEqual(count, 1, "Exactly one intended match required: \(query)")
        return element
    }

    @MainActor
    func ready(_ query: XCUIElementQuery, in app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let element = unique(query, in: app, timeout: timeout)
        let result = waitUntilReady(element, timeout: timeout)
        if !result { capture("not ready query=\(query)", in: app) }
        XCTAssertTrue(result, "Intended control must be enabled and hittable")
        return element
    }

    @MainActor
    func waitUntilReady(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        // Native waits avoid evaluating two remote properties in an NSPredicate
        // callback. Both waits share the original single readiness deadline.
        let started = ProcessInfo.processInfo.systemUptime
        let deadline = started + timeout
        let enabled = element.wait(for: \.isEnabled, toEqual: true, timeout: timeout)
        let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime)
        let hittable = enabled && element.wait(for: \.isHittable, toEqual: true, timeout: remaining)
        let stillEnabled = enabled && hittable && element.isEnabled
        let stillHittable = stillEnabled && element.isHittable
        print("Native readiness id=\(element.identifier) timeout=\(timeout) enabled=\(enabled) hittable=\(hittable) finalEnabled=\(stillEnabled) finalHittable=\(stillHittable) seconds=\(ProcessInfo.processInfo.systemUptime - started)")
        return enabled && hittable && stillEnabled && stillHittable
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
    func revealQuery(_ query: XCUIElementQuery, in app: XCUIApplication) {
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
        if id == "editor.hour" || id == "editor.minute" {
            let picker = unique(app.datePickers.matching(identifier: "editor.time"), in: app)
            let wheels = picker.pickerWheels
            XCTAssertEqual(wheels.count, 2, "en_GB time picker must have hour and minute wheels")
            let wheel = wheels.element(boundBy: id == "editor.hour" ? 0 : 1)
            XCTAssertTrue(wheel.isEnabled && wheel.isHittable)
            guard let number = Int(title) else { XCTFail("Invalid time selection"); return }
            wheel.adjust(toPickerWheelValue: String(format: "%02d", number))
            return
        }
        let query = app.buttons.matching(identifier: id)
        revealQuery(query, in: app)
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
    func capture(_ phase: String, in app: XCUIApplication, diagnosticProbe: (() -> Void)? = nil) {
        guard captureJournal.begin() else {
            print("Nested diagnostic collection omitted: \(phase)")
            return
        }
        let priorContinue = continueAfterFailure
        // This applies only inside optional diagnostics. All issues still go to
        // super.record; functional test execution keeps its original fail-fast rule.
        continueAfterFailure = true
        defer { continueAfterFailure = priorContinue; captureJournal.finish() }
        let initial = captureJournal.snapshot
        let context = "fixture=\(fixture) namespace=\(namespace) intendedID=\(alarmID ?? "unresolved") phase=\(phase) applicationPhase=\(initial.phase) lastCompletedTransition=\(initial.lastCompletedTransition) recordedIssues=\(initial.issues)"
        func attach(_ text: String, suffix: String) {
            print(text)
            let attachment = XCTAttachment(string: text)
            attachment.name = "\(name)-\(phase.prefix(100))-\(suffix)"
            attachment.lifetime = .keepAlways; add(attachment)
        }
        func omit(_ reason: String) {
            captureJournal.omit(reason)
            attach(context + "\nDiagnostic collection omitted: " + reason, suffix: "omission")
        }
        func hasSecondaryIssue() -> Bool { captureJournal.snapshot.issues.count != initial.issues.count }
        // Local metadata survives even if a later optional operation reports an issue.
        attach(context, suffix: "context")
        diagnosticProbe?()
        if hasSecondaryIssue() { omit("collector reported a secondary issue"); return }
        guard initial.phase == "ready" else { omit("application unavailable or transitioning: " + initial.phase); return }
        captureJournal.noteQuery()
        let state = app.state
        if hasSecondaryIssue() { omit("application-state lookup reported a secondary issue"); return }
        guard state == .runningForeground else { omit("application is not running in foreground: \(state.rawValue)"); return }
        // Filter in the accessibility query. Reading every descendant's identifier
        // in Swift repeatedly resolves the entire tree and can consume the run.
        captureJournal.noteQuery()
        let controls = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@ OR identifier BEGINSWITH %@ OR identifier BEGINSWITH %@ OR identifier == %@",
            "alarm.", "editor.", "diagnostic.", "alarms.add")).allElementsBoundByIndex
        if hasSecondaryIssue() { omit("control enumeration reported a secondary issue"); return }
        var details: [String] = []
        for (index, element) in controls.enumerated() {
            captureJournal.noteQuery()
            let value = element.value
            let type = value.map { String(reflecting: Swift.type(of: $0)) } ?? "nil"
            details.append("[\(index)] id=\(element.identifier) label=\(element.label) value=\(String(describing: value)) type=\(type) enabled=\(element.isEnabled) hittable=\(element.isHittable) frame=\(element.frame) children=\(element.children(matching: .switch).count)")
            if hasSecondaryIssue() { omit("control details reported a secondary issue"); return }
        }
        captureJournal.noteQuery()
        let hierarchy = app.debugDescription
        attach(context + "\n" + details.joined(separator: "\n") + "\n" + hierarchy, suffix: "hierarchy")
        if hasSecondaryIssue() { omit("hierarchy lookup reported a secondary issue"); return }
        captureJournal.noteQuery()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        if hasSecondaryIssue() { omit("screenshot reported a secondary issue"); return }
        screenshot.name = "\(name)-\(phase.prefix(100))-screen"
        screenshot.lifetime = .keepAlways; add(screenshot)
    }
}
