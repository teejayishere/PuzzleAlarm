import XCTest

final class ChallengeSettingsUITests: ChallengeUITestCase, @unchecked Sendable {
    @MainActor
    func testMathSettingsSaveAndReopen() {
        let (app, before) = open("math")
        assertDraft([math], in: app)
        choose("challenge.difficulty.math", "Hard", in: app)
        increment("challenge.math.count", in: app)
        assertDraft(["math:hard:6"], in: app)
        saveAndReopen(app, before: before, expected: ["math:hard:6"])
    }

    @MainActor
    func testMemorySettingsSaveAndReopen() {
        let (app, before) = open("memory")
        assertDraft([memory], in: app)
        choose("challenge.difficulty.memory", "Easy", in: app)
        increment("challenge.memory.length", in: app)
        increment("challenge.memory.seconds", in: app)
        increment("challenge.memory.rounds", in: app)
        assertDraft(["memory:easy:9:3.5:3"], in: app)
        saveAndReopen(app, before: before, expected: ["memory:easy:9:3.5:3"])
    }

    @MainActor
    func testQRTargetRetainsExactTokenThroughSaveAndReopen() {
        let (app, before) = open("qr")
        assertDraft([qr], in: app)
        let query = app.staticTexts.matching(identifier: "challenge.qr.target")
        revealQuery(query, in: app)
        XCTAssertEqual(unique(query, in: app).label,
            "Target: puzzlealarm://challenge/6a000000-0000-4000-8000-000000000003")
        // Reordering or another setting is not needed to change this immutable target.
        saveAndReopen(app, before: before, expected: [qr], changesDefinition: false)
        revealQuery(query, in: app)
        XCTAssertEqual(unique(query, in: app).label,
            "Target: puzzlealarm://challenge/6a000000-0000-4000-8000-000000000003")
    }
}
