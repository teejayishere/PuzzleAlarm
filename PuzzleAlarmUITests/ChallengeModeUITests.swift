import XCTest

final class ChallengeModeUITests: ChallengeUITestCase, @unchecked Sendable {
    @MainActor
    func testUnsavedModeChangesRetainExactSequenceAndCancel() {
        let (app, before) = open()
        assertDraft([memory, qr, math], in: app)
        choose("editor.mode", "Alarm only", in: app)
        assertDraft([memory, qr, math], in: app, mode: "annoying_only")
        choose("editor.mode", "Challenges required", in: app)
        assertDraft([memory, qr, math], in: app)
        cancel(app, before: before, original: [memory, qr, math])
    }

    @MainActor
    func testSaveOrdinaryModeClearsSequenceAfterRelaunch() {
        let (app, before) = open()
        assertDraft([memory, qr, math], in: app)
        choose("editor.mode", "Alarm only", in: app)
        assertDraft([memory, qr, math], in: app, mode: "annoying_only")
        saveAndReopen(app, before: before, expected: [], mode: "annoying_only")
        choose("editor.mode", "Challenges required", in: app)
        assertDraft([], in: app, canSave: false)
    }

    @MainActor
    func testSaveChallengeModeRequiresNonemptySequenceAndReopens() {
        let (app, before) = open("ordinary")
        assertDraft([], in: app, mode: "annoying_only")
        choose("editor.mode", "Challenges required", in: app)
        assertDraft([], in: app, canSave: false)
        XCTAssertEqual(disk(in: app), before); noMutation(in: app)
        button("challenge.add.math", in: app).tap()
        assertDraft([math], in: app)
        saveAndReopen(app, before: before, expected: [math])
    }
}
