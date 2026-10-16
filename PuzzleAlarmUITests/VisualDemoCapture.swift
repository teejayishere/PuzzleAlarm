import XCTest

extension XCTestCase {
    @MainActor
    func captureDemo(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "PuzzleAlarm-demo-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
