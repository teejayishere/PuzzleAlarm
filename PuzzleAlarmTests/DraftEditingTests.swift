#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class DraftEditingTests: XCTestCase, @unchecked Sendable {
    @MainActor
    func testWheelTimeSelectionPreservesBoundariesAndOtherDraftFields() throws {
        let original = try fixture()
        for (hour, minute) in [(0, 0), (23, 59), (2, 30), (12, 5)] {
            var draft = AlarmDraft(original)
            let selected = try XCTUnwrap(AlarmDraft.timePickerCalendar.date(from:
                DateComponents(year: 2026, month: 3, day: 8, hour: hour, minute: minute)))
            draft.timeSelection = selected
            XCTAssertEqual(draft.hour, hour)
            XCTAssertEqual(draft.minute, minute)
            let components = AlarmDraft.timePickerCalendar.dateComponents([.hour, .minute], from: draft.timeSelection)
            XCTAssertEqual(components.hour, hour)
            XCTAssertEqual(components.minute, minute)
            let converted = try draft.definition(at: original.updatedAt)
            XCTAssertEqual(converted.time, try AlarmTime(hour: hour, minute: minute))
            XCTAssertEqual(converted.weekdays, original.weekdays)
            XCTAssertEqual(converted.enabled, original.enabled)
            XCTAssertEqual(converted.challengeSequence, original.challengeSequence)
        }
    }

    @MainActor
    func testTimeRoundTripsIndependentlyIncludingBoundaries() throws {
        let original = try fixture()
        for (hour, minute) in [(0, 0), (23, 59), (8, 0), (7, 35)] {
            var draft = AlarmDraft(original)
            draft.hour = hour; draft.minute = minute
            let expected = try original.replacing(time: AlarmTime(hour: hour, minute: minute),
                weekdays: original.weekdays, enabled: original.enabled, mode: original.dismissalMode,
                challenges: original.challengeSequence, sound: original.selectedSound, at: original.updatedAt)
            XCTAssertEqual(try draft.definition(at: original.updatedAt), expected)
            XCTAssertEqual(try AlarmDraft(expected).definition(at: original.updatedAt), expected)
        }
    }

    @MainActor
    func testWeekdaysRoundTripIncludingOneTimeAndAllDays() throws {
        let original = try fixture()
        let selections: [Set<Weekday>] = [[], [.wednesday, .friday], Set(Weekday.allCases)]
        for days in selections {
            var draft = AlarmDraft(original); draft.weekdays = days
            let expected = try original.replacing(time: original.time, weekdays: days,
                enabled: original.enabled, mode: original.dismissalMode,
                challenges: original.challengeSequence, sound: original.selectedSound, at: original.updatedAt)
            XCTAssertEqual(try draft.definition(at: original.updatedAt), expected)
            XCTAssertEqual(AlarmDraft(expected).weekdays, days)
        }
    }

    @MainActor
    func testBothEnabledStatesRoundTripWithoutOtherChanges() throws {
        let original = try fixture()
        for enabled in [true, false] {
            var draft = AlarmDraft(original); draft.enabled = enabled
            let expected = try original.settingEnabled(enabled, at: original.updatedAt)
            XCTAssertEqual(try draft.definition(at: original.updatedAt), expected)
            XCTAssertEqual(try AlarmDraft(expected).definition(at: original.updatedAt), expected)
        }
    }

    @MainActor
    func testEverySoundIdentifierRoundTripsWithoutOtherChanges() throws {
        let original = try fixture()
        let expectedSounds: [SoundSelection] = [.systemDefault, .bundled(.harshBuzzer),
            .bundled(.rapidBeeps), .bundled(.siren), .bundled(.escalating)]
        for (index, sound) in expectedSounds.enumerated() {
            var draft = AlarmDraft(original); draft.soundIndex = index
            let expected = try original.replacing(time: original.time, weekdays: original.weekdays,
                enabled: original.enabled, mode: original.dismissalMode,
                challenges: original.challengeSequence, sound: sound, at: original.updatedAt)
            XCTAssertEqual(try draft.definition(at: original.updatedAt), expected)
            XCTAssertEqual(AlarmDraft(expected).soundIndex, index)
        }
    }

    @MainActor
    func testSaveForwardsExactEditedDefinitionAndPersistsIt() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"],
            environment: ["PUZZLEALARM_TEST_NAMESPACE": UUID().uuidString,
                          "PUZZLEALARM_TEST_FIXTURE": "ordinary"])
        let repository = DiskRepository(directory: directory)
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let recorder = DraftCommandRecorder(base: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler))
        let model = AlarmListModel(service: recorder, repository: repository)
        await model.refresh()
        let original = try XCTUnwrap(model.definitions.first)
        let before = try Data(contentsOf: directory.appendingPathComponent("state.json"))
        var draft = AlarmDraft(original)
        draft.hour = 8; draft.minute = 35; draft.weekdays = [.wednesday, .friday]
        draft.soundIndex = 3; draft.enabled = false
        let converted = try draft.definition(at: original.updatedAt)
        XCTAssertEqual(converted.time, try AlarmTime(hour: 8, minute: 35))
        XCTAssertEqual(converted.weekdays, [.wednesday, .friday])
        XCTAssertEqual(converted.selectedSound, .bundled(.siren))
        XCTAssertEqual(try Data(contentsOf: directory.appendingPathComponent("state.json")), before)
        let priorCommands = await recorder.commands
        XCTAssertEqual(priorCommands.count, 1, "Draft selection/conversion cannot call the service")
        let saved = await model.save(draft)
        XCTAssertTrue(saved)
        let commands = await recorder.commands
        XCTAssertEqual(commands.count, 2)
        guard let last = commands.last, case let .edit(forwarded, expectedOriginal) = last else {
            return XCTFail("Expected exactly one edit command")
        }
        XCTAssertEqual(expectedOriginal, original)
        XCTAssertEqual(forwarded, try draft.definition(at: forwarded.updatedAt))
        XCTAssertEqual(forwarded.id, original.id)
        XCTAssertEqual(forwarded.createdAt, original.createdAt)
        guard case let .loaded(snapshot, _) = try await DiskRepository(directory: directory).load() else {
            return XCTFail("Missing saved definition")
        }
        XCTAssertEqual(snapshot.state.definitions, [forwarded])
        XCTAssertEqual(try AlarmDraft(forwarded).definition(at: forwarded.updatedAt), forwarded)
        XCTAssertTrue(try scheduler.currentAlarms().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("fake-os-ids.json").path))
    }

    @MainActor
    func testInvalidDraftSaveStopsBeforeServiceAndStorage() async throws {
        let repository = InMemoryRepository()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let scheduler = try SimulatorAlarmScheduler(directory: directory)
        let recorder = DraftCommandRecorder(base: LifecycleAlarmManagementService(
            repository: repository, scheduler: scheduler))
        let model = AlarmListModel(service: recorder, repository: repository)
        var draft = AlarmDraft(); draft.enabled = false; draft.mode = .challengesRequired
        XCTAssertFalse(draft.canSave)
        XCTAssertThrowsError(try draft.definition(at: Date()))
        let saved = await model.save(draft)
        XCTAssertFalse(saved)
        XCTAssertNotNil(model.errorMessage)
        let commands = await recorder.commands
        XCTAssertTrue(commands.isEmpty)
        guard case .missing = try await repository.load() else { return XCTFail("Invalid draft wrote storage") }
        XCTAssertTrue(try scheduler.currentAlarms().isEmpty)
    }

    private func fixture() throws -> AlarmDefinition {
        try XCTUnwrap(SimulatorUITestFixture.state("ordinary").definitions.first)
    }
}

private actor DraftCommandRecorder: AlarmManagementService {
    let base: LifecycleAlarmManagementService
    private(set) var commands: [AlarmManagementCommand] = []
    init(base: LifecycleAlarmManagementService) { self.base = base }
    func perform(_ command: AlarmManagementCommand) async throws -> LifecycleReport {
        commands.append(command)
        return try await base.perform(command)
    }
}
#endif
