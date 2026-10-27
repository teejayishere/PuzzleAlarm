import SwiftUI
import XCTest
import PuzzleAlarmCore
@testable import PuzzleAlarm

@MainActor
final class AlarmEnabledInputTests: XCTestCase {
    private func fixture() throws -> (AlarmStore, TestAlarmScheduler, AlarmEditorDraft) {
        let effect = try TestAlarmScheduler()
        let now = UITestEnvironment.now
        let store = AlarmStore(repository: InMemoryRepository(), scheduler: effect, clock: { now },
            context: { try ScheduleContext(timeZoneIdentifier: "Pacific/Apia") })
        var draft = try AlarmEditorDraft(id: UUID(), now: now)
        draft.weekdays = [.monday]; draft.enabled = false
        return (store, effect, draft)
    }

    func testRetainedInputFollowsOwnerAndRejectsRemovedRow() async throws {
        let (store, effect, draft) = try fixture()
        _ = await store.save(draft)
        let original = try XCTUnwrap(store.definition(draft.id))
        let input = AlarmEnabledInput(alarm: original, store: store)
        let binding = input.binding
        XCTAssertFalse(binding.wrappedValue)
        await store.setEnabled(original, true)
        XCTAssertTrue(binding.wrappedValue)
        XCTAssertFalse(input.isSubmitting, "Owner updates are not user commands")
        await store.setEnabled(original, false)
        XCTAssertFalse(binding.wrappedValue)
        let deleted = await store.delete(original.id)
        XCTAssertTrue(deleted)
        let schedules = effect.values.schedules.count
        XCTAssertFalse(input.isEnabled)
        binding.wrappedValue = true
        XCTAssertFalse(binding.wrappedValue)
        XCTAssertFalse(input.isSubmitting)
        XCTAssertEqual(effect.values.schedules.count, schedules)
    }

    func testBusyOwnerRejectsInputWithoutLeavingPendingRequest() async throws {
        let (store, effect, draft) = try fixture()
        _ = await store.save(draft)
        let original = try XCTUnwrap(store.definition(draft.id))
        let input = AlarmEnabledInput(alarm: original, store: store)
        let pause = InputTestPause()
        effect.configure { $0.afterSchedule = { await pause.wait() } }
        let action = Task { await store.setEnabled(original, true) }
        await pause.started()
        XCTAssertFalse(input.isEnabled)
        let before = input.value
        input.binding.wrappedValue = !before
        XCTAssertFalse(input.isSubmitting)
        XCTAssertEqual(input.value, before)
        await pause.release()
        await action.value
        XCTAssertTrue(input.isEnabled)
        XCTAssertTrue(input.value)
        XCTAssertEqual(effect.values.schedules.count, 1)
    }
}

private actor InputTestPause {
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
