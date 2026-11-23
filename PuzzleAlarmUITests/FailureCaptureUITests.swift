import XCTest

// Only these deliberately injected issues are expected, with strict exact matchers.
// Unrelated launch, query, assertion and functional issues remain real failures.
final class FailureCaptureUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testPrimaryIssueIsForwardedBeforeNormalCapture() {
        let app = launch(fixture: "ordinary")
        expectIssue("capture-regression-primary") {
            emitIssue("capture-regression-primary")
        }
        XCTAssertEqual(captureJournal.snapshot.started, 0, "record must not collect accessibility")
        XCTAssertEqual(captureJournal.snapshot.queries, 0)
        XCTAssertEqual(captureJournal.snapshot.issues.count, 1)
        XCTAssertTrue(captureJournal.snapshot.issues[0].contains("capture-regression-primary"))
        XCTAssertTrue(captureJournal.snapshot.issues[0].contains("FailureCaptureUITests.swift"))
        capture("primary-already-forwarded", in: app)
        let state = captureJournal.snapshot
        XCTAssertEqual(state.started, 1)
        XCTAssertEqual(state.completed, 1)
        XCTAssertFalse(state.collecting)
        XCTAssertTrue(state.omissions.isEmpty)
        XCTAssertGreaterThan(state.queries, 0)
        XCTAssertFalse(continueAfterFailure)
    }

    @MainActor
    func testSecondaryCollectorIssueCannotReenterAndGuardResets() {
        let app = launch(fixture: "ordinary")
        expectIssue("capture-regression-primary") { emitIssue("capture-regression-primary") }
        expectIssue("capture-regression-secondary") {
            capture("injected-secondary", in: app, diagnosticProbe: {
                self.emitIssue("capture-regression-secondary")
                self.capture("nested-must-not-query", in: app)
            })
        }
        let failed = captureJournal.snapshot
        XCTAssertEqual(failed.issues.count, 2)
        XCTAssertTrue(failed.issues[0].hasPrefix("capture-regression-primary source="))
        XCTAssertTrue(failed.issues[1].hasPrefix("capture-regression-secondary source="))
        XCTAssertEqual(failed.started, 1)
        XCTAssertEqual(failed.completed, 1)
        XCTAssertEqual(failed.nestedSkipped, 1)
        XCTAssertEqual(failed.queries, 0)
        XCTAssertFalse(failed.collecting)
        XCTAssertEqual(failed.omissions, ["collector reported a secondary issue"])
        capture("independent-capture-after-secondary", in: app)
        let recovered = captureJournal.snapshot
        XCTAssertEqual(recovered.started, 2)
        XCTAssertEqual(recovered.completed, 2)
        XCTAssertEqual(recovered.issues.count, 2)
        XCTAssertGreaterThan(recovered.queries, 0)
        XCTAssertFalse(recovered.collecting)
        XCTAssertFalse(continueAfterFailure)
    }

    @MainActor
    func testUnavailableApplicationRetainsIssueWithoutQueries() {
        let app = launch(fixture: "ordinary")
        applicationTransition("terminate-for-regression", endingAt: "terminated") { app.terminate() }
        expectIssue("capture-regression-unavailable") { emitIssue("capture-regression-unavailable") }
        capture("terminated-application", in: app)
        let state = captureJournal.snapshot
        XCTAssertEqual(state.issues.count, 1)
        XCTAssertTrue(state.issues[0].hasPrefix("capture-regression-unavailable source="))
        XCTAssertEqual(state.started, 1)
        XCTAssertEqual(state.completed, 1)
        XCTAssertEqual(state.queries, 0)
        XCTAssertEqual(state.omissions, ["application unavailable or transitioning: terminated"])
        XCTAssertFalse(state.collecting)
        XCTAssertFalse(continueAfterFailure)
    }

    @MainActor
    func testTransitionIssueWithEditorPresentSkipsQueriesAndRelaunches() {
        alarmID = "6A000000-0000-4000-8000-000000000001"
        let app = launch(fixture: "ordinary", navigationAudit: true)
        let before = auditValue("list", in: app).components(separatedBy: " | ")[1]
        rowButton("alarm.edit.", in: app).tap()
        XCTAssertTrue(app.navigationBars["Edit alarm"].waitForExistence(timeout: 10))
        applicationTransition("controlled-launch-failure") {
            self.expectIssue("capture-regression-transition") { self.emitIssue("capture-regression-transition") }
            self.capture("launch-transition-with-editor", in: app)
            XCTAssertEqual(self.captureJournal.snapshot.queries, 0)
        }
        let state = captureJournal.snapshot
        XCTAssertEqual(state.issues.count, 1)
        XCTAssertEqual(state.started, 1)
        XCTAssertEqual(state.completed, 1)
        XCTAssertEqual(state.omissions, ["application unavailable or transitioning: transition: controlled-launch-failure"])
        XCTAssertFalse(state.collecting)
        relaunch(app)
        _ = rowButton("alarm.edit.", in: app)
        XCTAssertEqual(auditValue("list", in: app).components(separatedBy: " | ")[1], before)
        XCTAssertFalse(auditValue("list", in: app).contains("service.enter edit"))
        XCTAssertFalse(continueAfterFailure)
    }

    @MainActor
    private func expectIssue(_ description: String, _ operation: () -> Void) {
        let options = XCTExpectedFailure.Options()
        options.isStrict = true
        options.issueMatcher = {
            $0.type == .assertionFailure && $0.compactDescription == description &&
                $0.sourceCodeContext.location?.fileURL.lastPathComponent == "FailureCaptureUITests.swift"
        }
        XCTExpectFailure("Deliberate negative diagnostic regression: " + description,
                         options: options, failingBlock: operation)
    }

    private func emitIssue(_ description: String, file: StaticString = #filePath, line: UInt = #line) {
        let location = XCTSourceCodeLocation(filePath: String(describing: file), lineNumber: Int(line))
        record(XCTIssue(type: .assertionFailure, compactDescription: description,
            sourceCodeContext: XCTSourceCodeContext(location: location)))
    }

    @MainActor
    private func auditValue(_ context: String, in app: XCUIApplication) -> String {
        let element = unique(app.staticTexts.matching(identifier: "diagnostic.navigation." + context), in: app)
        guard let value = element.value as? String else { XCTFail("Missing audit"); return "" }
        XCTAssertGreaterThanOrEqual(value.components(separatedBy: " | ").count, 2)
        XCTAssertFalse(value.contains("audit-error:"))
        return value
    }
}
