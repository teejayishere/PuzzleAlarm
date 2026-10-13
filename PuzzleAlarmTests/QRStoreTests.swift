import XCTest
import CoreImage
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor final class QRStoreTests: XCTestCase {
    private let configuration = QRConfiguration(token: UITestEnvironment.alarmID)
    private func seed(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler,
                      followedByMath: Bool = false) async throws -> ChallengeIdentity {
        let now = UITestEnvironment.now
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        try draft.setMode(.challengesRequired)
        draft.sequence = try ChallengeSequence([.qr(configuration)] +
            (followedByMath ? [.math(try MathConfiguration(requiredCorrect: 1))] : []))
        let definition = try draft.definition(at: now), ids = (0..<5).map { _ in UUID() }
        var session = try WakeUpSession(id: UUID(), definition: definition,
            context: ScheduleContext(timeZoneIdentifier: "UTC"), plan: BackupPlan(at: now, ids: ids), createdAt: now)
        try session.beginScheduling()
        for id in ids { try session.beginScheduleAttempt(id: id); try session.recordScheduled(id: id) }
        try session.arm(); try session.activate(at: now)
        _ = try await repository.commit(RepositoryState(definitions: [definition],
            sessions: [PersistedSession(session: session, updatedAt: now)]), expecting: .missing)
        effects.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
        return ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr)
    }
    private func store(_ repository: any PuzzleAlarmRepository, _ effects: TestAlarmScheduler) -> AlarmStore {
        let now = UITestEnvironment.now
        return AlarmStore(repository: repository, scheduler: effects, clock: { now },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
    }
    func testGeneratedExportDecodesExactTokenAndHasWhiteQuietZone() throws {
        let image = try XCTUnwrap(QRCodeImage.generate(configuration))
        let data = try XCTUnwrap(image.pngData())
        let ciImage = try XCTUnwrap(CIImage(data: data))
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(),
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
        let features = detector.features(in: ciImage).compactMap { $0 as? CIQRCodeFeature }
        XCTAssertEqual(features.map(\.messageString), [configuration.expectedPayload])
        XCTAssertGreaterThan(image.size.width, 300)
        let crop = try XCTUnwrap(ciImage.cropped(to: CGRect(x: 0, y: 0, width: 16, height: 16))
            .applyingFilter("CIAreaAverage").outputImageForTest())
        XCTAssertEqual(crop, [255, 255, 255, 255])
    }
    func testWriteFailureRelaunchDuplicateAndPendingCleanup() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects)
        let store = store(repository, effects); await store.refresh()
        let wrong = await store.submitQR("unrelated", identity: identity)
        XCTAssertEqual(wrong, .wrong); XCTAssertTrue(effects.values.cancellations.isEmpty)
        await repository.failNext(.write)
        let failed = await store.submitQR(configuration.expectedPayload, identity: identity)
        XCTAssertNil(failed); XCTAssertEqual(store.session(identity.sessionID)?.session.currentChallengeIndex, 0)
        let restored = self.store(repository, effects); await restored.refresh()
        effects.configure { $0.failCancellation = true }
        let result = await restored.submitQR(configuration.expectedPayload, identity: identity)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(restored.session(identity.sessionID)?.session.phase, .cancellationPartiallyFailed)
        let duplicate = await restored.submitQR(configuration.expectedPayload, identity: identity)
        XCTAssertEqual(duplicate, .stale)
        effects.configure { $0.failCancellation = false }; await restored.refresh()
        XCTAssertEqual(restored.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertTrue(effects.values.alarms.isEmpty)
    }
    func testRevokedAlarmAccessAndNextKindCannotBeSolvedByQR() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects, followedByMath: true)
        effects.configure { $0.authorization = .denied }
        let store = store(repository, effects); await store.refresh()
        let result = await store.submitQR(configuration.expectedPayload, identity: identity)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(store.session(identity.sessionID)?.session.currentChallenge?.kind, .math)
        XCTAssertFalse(store.confirmed); XCTAssertTrue(effects.values.cancellations.isEmpty)
        let duplicate = await store.submitQR(configuration.expectedPayload, identity: identity)
        XCTAssertEqual(duplicate, .stale)
        XCTAssertEqual(store.session(identity.sessionID)?.session.currentChallengeIndex, 1)
    }
    func testScannerPermissionsLateCallbacksRetryAndInterruptionNeverSucceed() async throws {
        let repository = InMemoryRepository(), effects = try TestAlarmScheduler()
        let identity = try await seed(repository, effects)
        let store = store(repository, effects); await store.refresh()
        let fake = FakeQRCodeScanner(), controller = QRScanController(store: store, scanner: fake)
        for permission in [QRScannerStatus.notDetermined, .denied, .restricted, .unavailable, .interrupted] {
            fake.permission = permission; controller.start(identity)
            XCTAssertEqual(controller.status, permission)
            fake.emit(.payload(configuration.expectedPayload))
            await Task.yield()
            XCTAssertEqual(store.session(identity.sessionID)?.session.currentChallengeIndex, 0)
        }
        fake.permission = .authorized; controller.start(identity)
        let old = try XCTUnwrap(fake.receive)
        controller.stop(); old(.payload(configuration.expectedPayload)); await Task.yield()
        XCTAssertEqual(store.session(identity.sessionID)?.session.currentChallengeIndex, 0)
        controller.start(identity); old(.status(.interrupted)); old(.payload(configuration.expectedPayload))
        XCTAssertEqual(controller.status, .authorized)
        fake.emit(.status(.interrupted))
        XCTAssertEqual(controller.status, .interrupted)
        controller.start(identity); fake.emit(.payload("wrong"))
        for _ in 0..<100 where controller.feedback.isEmpty { await Task.yield() }
        XCTAssertEqual(controller.feedback, "This is not the configured QR code.")
        fake.emit(.payload(configuration.expectedPayload)); fake.emit(.payload(configuration.expectedPayload))
        for _ in 0..<1000 where controller.isSubmitting { await Task.yield() }
        XCTAssertEqual(store.session(identity.sessionID)?.session.phase, .completed)
        XCTAssertEqual(controller.status, .idle)
        XCTAssertEqual(effects.values.cancellations.count, 5)
    }
}

private extension CIImage {
    func outputImageForTest() -> [UInt8]? {
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(self, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        return pixel
    }
}
