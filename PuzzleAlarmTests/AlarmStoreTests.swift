import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor
final class AlarmStoreTests: XCTestCase {
    let now = UITestEnvironment.now
    func make(_ repository: any PuzzleAlarmRepository = InMemoryRepository(),
              _ scheduler: TestAlarmScheduler? = nil) throws -> (AlarmStore, TestAlarmScheduler) {
        let effect = try scheduler ?? TestAlarmScheduler()
        let fixed = now
        return (AlarmStore(repository: repository, scheduler: effect, clock: { fixed },
            context: { try ScheduleContext(timeZoneIdentifier: "Pacific/Apia") }), effect)
    }
    func draft(enabled: Bool = true) throws -> AlarmEditorDraft {
        var value = try AlarmEditorDraft(id: UUID(), now: now)
        value.weekdays = [.monday]; value.enabled = enabled
        return value
    }
    func testMissingAndCommittedEmptyStartupDoNotScheduleOrPrompt() async throws {
        for committed in [false, true] {
            let repository = InMemoryRepository()
            if committed { _ = try await repository.commit(RepositoryState(), expecting: .missing) }
            let (store, effect) = try make(repository)
            await store.refresh()
            XCTAssertTrue(store.hasLoaded && store.alarms.isEmpty)
            XCTAssertTrue(effect.values.schedules.isEmpty)
            XCTAssertEqual(effect.values.authorizationRequests, 0)
        }
    }
    func testCreateEditEnableDisableDeleteUseOneCoordinatorAndFixedContext() async throws {
        let (store, effect) = try make()
        let owner = store.coordinator
        let first = try draft()
        _ = await store.save(first)
        let created = try XCTUnwrap(store.definition(first.id))
        XCTAssertEqual(store.status(created), "On")
        var edit = AlarmEditorDraft(created); edit.hour = 8; edit.sound = .siren
        _ = await store.save(edit)
        let changed = try XCTUnwrap(store.definition(first.id))
        XCTAssertEqual(changed.id, first.id)
        XCTAssertEqual(changed.selectedSound, .bundled(.siren))
        XCTAssertEqual(store.state?.operations.first?.context.timeZoneIdentifier, "Pacific/Apia")
        await store.setEnabled(changed, false)
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(first.id))), "Off")
        await store.setEnabled(try XCTUnwrap(store.definition(first.id)), true)
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(first.id))), "On")
        let deleted = await store.delete(first.id)
        XCTAssertTrue(deleted && store.alarms.isEmpty)
        XCTAssertTrue(owner === store.coordinator)
        XCTAssertFalse(effect.values.cancellations.isEmpty)
    }
    func testScheduleFailureIsNotHealthyAndRetryRetainsID() async throws {
        let (store, effect) = try make()
        effect.configure { $0.failSchedules = 1 }
        let value = try draft()
        guard case .attention = await store.save(value) else { return XCTFail("Must retain failed configuration") }
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(value.id))), "Needs attention")
        let firstID = try XCTUnwrap(effect.values.schedules.first?.plannedAlarm.id)
        await store.retry(value.id)
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(value.id))), "On")
        await store.retry(value.id)
        XCTAssertEqual(effect.values.schedules.map(\.plannedAlarm.id), [firstID, firstID])
    }
    func testAuthorizationStatesAndIntentionalRequest() async throws {
        for authorization: AlarmAuthorization in [.notDetermined, .authorized, .denied, .unknown] {
            let (store, effect) = try make()
            effect.configure { $0.authorization = authorization }
            await store.refresh()
            XCTAssertEqual(store.authorization, authorization)
            XCTAssertEqual(effect.values.authorizationRequests, 0)
            XCTAssertFalse(AlarmPresentation.authorization(authorization).isEmpty)
            if authorization == .notDetermined {
                await store.grantAuthorization()
                XCTAssertEqual(store.authorization, .authorized)
                XCTAssertEqual(effect.values.authorizationRequests, 1)
            } else if authorization != .authorized {
                _ = await store.save(draft())
                XCTAssertTrue(store.alarms.isEmpty && effect.values.schedules.isEmpty)
                XCTAssertNotNil(store.errorMessage)
            }
        }
    }
    func testCorruptionAndSnapshotFailureNeverResetOrClaimEmptySuccess() async throws {
        let repository = InMemoryRepository(storedRepresentation: Data("broken".utf8))
        let (store, effect) = try make(repository)
        await store.refresh()
        XCTAssertFalse(store.hasLoaded)
        XCTAssertNil(store.state)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertTrue(effect.values.schedules.isEmpty)
        let bytes = await repository.storedRepresentation()
        XCTAssertEqual(bytes, Data("broken".utf8))
        let (second, effects) = try make()
        let value = try draft()
        _ = await second.save(value)
        effects.configure { $0.failSnapshot = true }
        await second.refresh()
        XCTAssertEqual(second.alarms.count, 1)
        XCTAssertEqual(second.status(try XCTUnwrap(second.definition(value.id))), "Status unconfirmed")
    }
    func testStaleEditorCannotOverwriteNewerConfigurationAndCanReload() async throws {
        let (store, _) = try make()
        let value = try draft()
        _ = await store.save(value)
        let original = try XCTUnwrap(store.definition(value.id))
        var stale = AlarmEditorDraft(original); stale.hour = 10
        var newer = AlarmEditorDraft(original); newer.hour = 9
        _ = await store.save(newer)
        guard case .failed = await store.save(stale) else { return XCTFail("Stale edit accepted") }
        XCTAssertTrue(store.editWasSuperseded)
        XCTAssertEqual(store.definition(value.id)?.time.hour, 9)
        let reload = AlarmEditorDraft(try XCTUnwrap(store.definition(value.id)))
        store.clearError()
        guard case .saved = await store.save(reload) else { return XCTFail("Reload failed") }
    }
    func testFailedDeleteRetainsDefinitionAndOwnership() async throws {
        let (store, effect) = try make()
        let value = try draft()
        _ = await store.save(value)
        effect.configure { $0.failCancellation = true }
        let deleted = await store.delete(value.id)
        XCTAssertFalse(deleted)
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(value.id))), "Cleanup pending")
        XCTAssertFalse(try XCTUnwrap(store.state).ownershipLedger().isEmpty)
        effect.configure { $0.failCancellation = false }
        await store.refresh()
        XCTAssertNil(store.definition(value.id))
    }
    func testReportTranslationPreservesOrphanAndStaleWarnings() async throws {
        let (store, effect) = try make()
        let orphan = UUID()
        effect.configure { $0.alarms = [.init(id: orphan, state: .scheduled)] }
        await store.refresh()
        XCTAssertTrue(store.issues.contains(.orphaned(orphan)))
        XCTAssertTrue(effect.values.cancellations.isEmpty)
        for issue: LifecycleReport.Issue in [.orphaned(orphan), .stalePresent(orphan), .deletionDeferred(orphan),
            .activeAlarmMissing(orphan), .operationFailed(orphan, .scheduling), .operationFailed(orphan, .cancellation)] {
            XCTAssertFalse(AlarmPresentation.issue(issue).contains(orphan.uuidString))
        }
    }
    func testBusySaveAndForegroundRefreshAreCoalescedWithoutDuplicates() async throws {
        let (store, effect) = try make()
        let pause = StoreTestPause()
        effect.configure { $0.afterSchedule = { await pause.wait() } }
        let value = try draft()
        let action = Task { await store.save(value) }
        await pause.started()
        XCTAssertTrue(store.isBusy)
        guard case .failed = await store.save(value) else { return XCTFail("Duplicate save was accepted") }
        await store.refresh(); await store.refresh()
        await pause.release()
        _ = await action.value
        XCTAssertFalse(store.isBusy)
        XCTAssertEqual(effect.values.schedules.count, 1)
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(value.id))), "On")
    }
    func testSortingAndUnconfirmedEnabledState() async throws {
        let repository = InMemoryRepository()
        var a = try draft(); a.hour = 9
        var b = try draft(enabled: false); b.hour = 6
        var c = try draft(); c.hour = 7
        _ = try await repository.commit(RepositoryState(definitions: [
            a.definition(at: now), b.definition(at: now), c.definition(at: now)
        ]), expecting: .missing)
        let (store, effect) = try make(repository)
        effect.configure { $0.authorization = .denied }
        await store.refresh()
        XCTAssertEqual(store.alarms.map(\.id), [c.id, a.id, b.id])
        XCTAssertEqual(store.status(try XCTUnwrap(store.definition(a.id))), "Alarm access needed")
        XCTAssertNil(store.nextOccurrence(try XCTUnwrap(store.definition(a.id))))
    }
    func testErrorMessagesDoNotExposeTechnicalPayloads() {
        for error: any Error in [PersistenceError.unsupportedSchema(999), PersistenceError.io("secret"),
            PersistenceError.conflict, LifecycleError.conflictLimit, LifecycleError.busy,
            LifecycleError.superseded, DomainError.invalidTransition, DomainError.invalidConfiguration("secret")] {
            let message = AlarmPresentation.error(error)
            XCTAssertFalse(message.isEmpty || message.contains("secret") || message.contains("999"))
        }
    }
}

private actor StoreTestPause {
    private var continuation: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?
    private var entered = false
    func wait() async {
        entered = true; observer?.resume(); observer = nil
        await withCheckedContinuation { continuation = $0 }
    }
    func started() async {
        if entered { return }
        await withCheckedContinuation { observer = $0 }
    }
    func release() { continuation?.resume(); continuation = nil }
}
