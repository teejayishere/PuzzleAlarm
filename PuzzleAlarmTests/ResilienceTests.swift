import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

/// Real filesystem faults at the application boundary. Scheduler fakes record
/// effects; production persistence, reducers and lifecycle decisions still run.
@MainActor final class ResilienceTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let qr = QRConfiguration(token: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!)

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        return url
    }

    private func store(_ directory: URL, _ effects: TestAlarmScheduler) -> AlarmStore {
        let date = now
        return AlarmStore(repository: DiskRepository(directory: directory), scheduler: effects,
            clock: { date }, context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }

    private func seed(_ directory: URL, _ effects: TestAlarmScheduler) async throws -> WakeUpSession {
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        draft.weekdays = []
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence([.qr(qr)])
        let definition = try draft.definition(at: now)
        let ids = (0..<5).map { _ in UUID() }
        var session = try WakeUpSession(id: UUID(), definition: definition,
            context: ScheduleContext(timeZoneIdentifier: "UTC"),
            plan: BackupPlan(at: now, ids: ids), createdAt: now)
        try session.beginScheduling()
        for id in ids { try session.beginScheduleAttempt(id: id); try session.recordScheduled(id: id) }
        try session.arm(); try session.activate(at: now)
        _ = try await DiskRepository(directory: directory).commit(RepositoryState(definitions: [definition],
            sessions: [PersistedSession(session: session, updatedAt: now)]), expecting: .missing)
        effects.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
        return session
    }

    func testColdDiskReadFailureCannotClaimLoadedOrTouchExternalAlarms() async throws {
        let directory = try directory(), effects = try TestAlarmScheduler()
        let session = try await seed(directory, effects)
        let file = directory.appendingPathComponent("state.json")
        let preserved = directory.appendingPathComponent("preserved.json")
        try FileManager.default.moveItem(at: file, to: preserved)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        let owner = store(directory, effects)
        await owner.refresh()
        XCTAssertFalse(owner.hasLoaded || owner.confirmed)
        XCTAssertNil(owner.state)
        XCTAssertNotNil(owner.errorMessage)
        XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.cancellations.isEmpty)
        XCTAssertEqual(Set(effects.values.alarms.map(\.id)), Set(session.plan.alarms.map(\.id)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: preserved.path))
    }

    func testWarmDiskReadFailureRetainsObligationAndRecoversWithoutEffects() async throws {
        let directory = try directory(), effects = try TestAlarmScheduler()
        let session = try await seed(directory, effects)
        let owner = store(directory, effects)
        await owner.refresh()
        let saved = owner.state
        let file = directory.appendingPathComponent("state.json")
        let preserved = directory.appendingPathComponent("preserved.json")
        let bytes = try Data(contentsOf: file)
        try FileManager.default.moveItem(at: file, to: preserved)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: false)
        await owner.refresh()
        XCTAssertFalse(owner.confirmed)
        XCTAssertNotNil(owner.errorMessage)
        XCTAssertEqual(owner.state, saved)
        XCTAssertEqual(owner.wakeUpSessionID, session.id)
        let identity = ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr)
        let result = await owner.submitQR(qr.expectedPayload, identity: identity)
        XCTAssertNil(result)
        XCTAssertEqual(owner.session(session.id)?.session, session)
        XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.cancellations.isEmpty)
        // The test removes its external fault; the application never repairs storage.
        try FileManager.default.removeItem(at: file)
        try FileManager.default.moveItem(at: preserved, to: file)
        await owner.refresh()
        XCTAssertTrue(owner.confirmed)
        XCTAssertNil(owner.errorMessage)
        XCTAssertEqual(owner.wakeUpSessionID, session.id)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.cancellations.isEmpty)
    }

    func testRealDiskWriteFailureCannotCompleteOrCancelAndFreshOwnerCanRetry() async throws {
        let directory = try directory(), effects = try TestAlarmScheduler()
        let session = try await seed(directory, effects)
        let owner = store(directory, effects)
        await owner.refresh()
        let file = directory.appendingPathComponent("state.json")
        let bytes = try Data(contentsOf: file)
        let pending = directory.appendingPathComponent("state.json.pending")
        try FileManager.default.createDirectory(at: pending, withIntermediateDirectories: false)
        let identity = ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr)
        let failed = await owner.submitQR(qr.expectedPayload, identity: identity)
        XCTAssertNil(failed)
        XCTAssertNotNil(owner.errorMessage)
        XCTAssertFalse(owner.confirmed)
        XCTAssertEqual(owner.session(session.id)?.session, session)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        XCTAssertTrue(effects.values.cancellations.isEmpty)
        // Retry is a product recovery action after the injected fault is removed.
        try FileManager.default.removeItem(at: pending)
        let fresh = store(directory, effects)
        await fresh.refresh()
        XCTAssertEqual(fresh.wakeUpSessionID, session.id)
        let completed = await fresh.submitQR(qr.expectedPayload, identity: identity)
        XCTAssertEqual(completed, .completed)
        XCTAssertEqual(fresh.session(session.id)?.session.phase, .completed)
        XCTAssertEqual(Set(effects.values.cancellations), Set(session.plan.alarms.map(\.id)))
        XCTAssertEqual(effects.values.cancellations.count, 5)
        let duplicate = await fresh.submitQR(qr.expectedPayload, identity: identity)
        XCTAssertEqual(duplicate, .stale)
        XCTAssertEqual(effects.values.cancellations.count, 5)
        XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.alarms.isEmpty)
    }

    func testMalformedDiskStateIncludingForgedCompletionCannotBeReplacedBySave() async throws {
        let directory = try directory(), effects = try TestAlarmScheduler()
        let session = try await seed(directory, effects)
        let file = directory.appendingPathComponent("state.json")
        var document = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var state = try XCTUnwrap(document["state"] as? [String: Any])
        var records = try XCTUnwrap(state["sessions"] as? [[String: Any]])
        var forged = try XCTUnwrap(records[0]["session"] as? [String: Any])
        forged["phase"] = "completed"
        records[0]["session"] = forged
        state["sessions"] = records; document["state"] = state
        let forgedBytes = try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
        for bytes in [Data("{\"schemaVersion\":2,".utf8),
                      Data("{\"schemaVersion\":999}".utf8), forgedBytes] {
            try bytes.write(to: file, options: .atomic)
            let owner = store(directory, effects)
            await owner.refresh()
            XCTAssertFalse(owner.hasLoaded || owner.confirmed)
            XCTAssertNil(owner.state)
            XCTAssertNotNil(owner.errorMessage)
            var draft = try AlarmEditorDraft(id: UUID(), now: now)
            draft.enabled = false
            guard case .failed = await owner.save(draft) else { return XCTFail("Malformed state overwritten") }
            XCTAssertEqual(try Data(contentsOf: file), bytes)
            XCTAssertTrue(effects.values.schedules.isEmpty && effects.values.cancellations.isEmpty)
            XCTAssertEqual(Set(effects.values.alarms.map(\.id)), Set(session.plan.alarms.map(\.id)))
        }
    }
}
