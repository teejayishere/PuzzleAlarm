import XCTest

final class HarnessIdentityUITests: AlarmUITestCase, @unchecked Sendable {
    @MainActor
    func testResetAndRelaunchPreserveKnownFixtureIdentity() {
        for (kind, id) in [("ordinary", "6A000000-0000-4000-8000-000000000001"),
                           ("challenge", "6A000000-0000-4000-8000-000000000002")] {
            namespace = UUID().uuidString
            alarmID = id
            let app = launch(fixture: kind)
            _ = rowButton("alarm.edit.", in: app)
            assertSwitch(rowSwitch(in: app), isOn: false)
            relaunch(app)
            _ = rowButton("alarm.edit.", in: app)
            assertSwitch(rowSwitch(in: app), isOn: false)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.edit.")).count, 1)
            // Reset in this namespace to empty; another namespace's disk is untouched.
            app.terminate()
            let empty = launch(fixture: "empty")
            XCTAssertTrue(empty.staticTexts["alarms.empty"].waitForExistence(timeout: 10))
            XCTAssertEqual(empty.buttons.matching(identifier: "alarm.edit." + id).count, 0)
            empty.terminate()
        }
    }
}
