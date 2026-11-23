import XCTest

final class ChallengeSequenceUITests: ChallengeUITestCase, @unchecked Sendable {
    @MainActor
    func testAddDisablesDuplicateAndCancelDoesNotWrite() {
        let (app, before) = open("ordinary")
        choose("editor.mode", "Challenges required", in: app)
        assertDraft([], in: app, canSave: false)
        button("challenge.add.math", in: app).tap()
        assertDraft([math], in: app)
        let add = unique(app.buttons.matching(identifier: "challenge.add.math"), in: app)
        XCTAssertFalse(add.isEnabled)
        cancel(app, before: before, original: [], mode: "annoying_only")
    }

    @MainActor
    func testMoveUpChangesOnlyIntendedOrder() {
        let (app, before) = open()
        assertDraft([memory, qr, math], in: app)
        button("challenge.up.qr", in: app).tap()
        assertDraft([qr, memory, math], in: app)
        cancel(app, before: before, original: [memory, qr, math])
    }

    @MainActor
    func testMoveDownChangesOnlyIntendedOrder() {
        let (app, before) = open()
        assertDraft([memory, qr, math], in: app)
        button("challenge.down.memory", in: app).tap()
        assertDraft([qr, memory, math], in: app)
        cancel(app, before: before, original: [memory, qr, math])
    }

    @MainActor
    func testFirstUpAndLastDownAreDisabled() {
        let (app, before) = open()
        for id in ["challenge.up.memory", "challenge.down.math"] {
            let query = app.buttons.matching(identifier: id)
            revealQuery(query, in: app)
            XCTAssertFalse(unique(query, in: app).isEnabled)
        }
        assertDraft([memory, qr, math], in: app)
        cancel(app, before: before, original: [memory, qr, math])
    }

    @MainActor
    func testRemovePreservesOtherConfigurationsAndAllowsReaddition() {
        let (app, before) = open()
        assertDraft([memory, qr, math], in: app)
        button("challenge.remove.qr", in: app).tap()
        assertDraft([memory, math], in: app)
        XCTAssertTrue(button("challenge.add.qr", in: app).isEnabled)
        cancel(app, before: before, original: [memory, qr, math])
    }
}
