import ActivityKit
import AVFoundation
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

@MainActor
final class AudioTests: XCTestCase {
    func testEveryBundledResourceDecodesAndMapsToNamedAlarmSound() throws {
        let catalog = AlarmSoundCatalog()
        for sound in BundledSound.allCases {
            let selection = SoundSelection.bundled(sound)
            let url = try XCTUnwrap(catalog.resource(for: selection), sound.rawValue)
            let file = try AVAudioFile(forReading: url)
            XCTAssertEqual(file.length, 88200)
            XCTAssertEqual(file.processingFormat.sampleRate, 22050)
            XCTAssertEqual(file.processingFormat.channelCount, 1)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 88200))
            try file.read(into: buffer)
            XCTAssertEqual(buffer.frameLength, 88200)
            let samples = try XCTUnwrap(buffer.floatChannelData)[0]
            let peak = (0..<Int(buffer.frameLength)).map { abs(samples[$0]) }.max() ?? 0
            XCTAssertGreaterThan(peak, 0.2)
            XCTAssertLessThan(peak, 0.7)
            XCTAssertEqual(AlarmConfigurationFactory.selectedSound(selection), .named(sound.rawValue + ".caf"))
        }
        XCTAssertNil(catalog.resource(for: .systemDefault))
        XCTAssertEqual(AlarmConfigurationFactory.selectedSound(.systemDefault), .default)
    }

    func testMissingEmptyCorruptAndTooLongFilesFallBackWithoutRewritingSelection() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("bad.caf")
        let catalog = AlarmSoundCatalog(locate: { _ in url })
        let selection = SoundSelection.bundled(.siren)
        XCTAssertEqual(AlarmConfigurationFactory.selectedSound(selection, catalog: catalog), .default)
        try Data().write(to: url)
        XCTAssertNil(catalog.resource(for: selection))
        try Data("not audio".utf8).write(to: url)
        XCTAssertEqual(AlarmConfigurationFactory.selectedSound(selection, catalog: catalog), .default)
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1))
        do { _ = try AVAudioFile(forWriting: url, settings: format.settings) }
        XCTAssertNil(catalog.resource(for: selection), "A valid header with zero frames is not a usable sound")
        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 22050 * 30))
            buffer.frameLength = buffer.frameCapacity
            try file.write(from: buffer)
        }
        XCTAssertNil(catalog.resource(for: selection))
        XCTAssertEqual(selection, .bundled(.siren))
    }

    func testPreviewReplacementStopAndFailuresReleasePreviousPlayback() throws {
        let player = RecordingPreview()
        let preview = SoundPreview(playback: player)
        preview.play(.bundled(.siren))
        XCTAssertTrue(preview.isPlaying)
        XCTAssertEqual(player.current?.lastPathComponent, "siren.caf")
        preview.play(.bundled(.rapidBeeps))
        XCTAssertEqual(player.starts, 2)
        XCTAssertEqual(player.stops, 2)
        XCTAssertEqual(player.current?.lastPathComponent, "rapid_beeps.caf")
        preview.stop(); preview.stop()
        XCTAssertFalse(preview.isPlaying)
        XCTAssertNil(player.current)
        player.fail = true
        preview.play(.bundled(.harshBuzzer))
        XCTAssertFalse(preview.isPlaying)
        XCTAssertNil(player.current)
        XCTAssertNotNil(preview.message)
        preview.play(.systemDefault)
        XCTAssertFalse(preview.isPlaying)
        XCTAssertEqual(player.starts, 3)
        XCTAssertNotNil(preview.message)
        let missing = SoundPreview(playback: player, catalog: .init(locate: { _ in nil }))
        missing.play(.bundled(.escalating))
        XCTAssertFalse(missing.isPlaying)
        XCTAssertNotNil(missing.message)
    }

    func testActualPreviewPlayerStartsReplacesAndStopsIdempotently() throws {
        let player = AudioPreviewPlayback()
        let url = try XCTUnwrap(AlarmSoundCatalog().resource(for: .bundled(.siren)))
        try player.start(url)
        try player.start(url)
        player.stop(); player.stop()
        XCTAssertThrowsError(try player.start(URL(fileURLWithPath: "/missing-preview.caf")))
        player.stop()
        // Simulator execution proves API/resource integration, not audible hardware playback.
    }

    func testQueuedCategoryChangeDoesNotCancelPreviewButExternalAndUnknownRoutesStop() {
        let player = RecordingPreview()
        let preview = SoundPreview(playback: player)
        preview.play(.bundled(.siren))
        preview.routeChanged(reason: AVAudioSession.RouteChangeReason.categoryChange.rawValue)
        XCTAssertTrue(preview.isPlaying)
        XCTAssertNotNil(player.current)
        for reason: UInt? in [AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue,
                             AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue, nil, UInt.max] {
            preview.play(.bundled(.siren))
            preview.routeChanged(reason: reason)
            XCTAssertFalse(preview.isPlaying)
            XCTAssertNil(player.current)
        }
    }

    func testAllSoundSelectionsSurviveDiskReloadAndOccurrenceSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var version = RepositoryRead.missing.version
        for choice in SoundChoice.allCases {
            var draft = try AlarmEditorDraft(id: UUID(), now: now)
            draft.sound = choice
            try draft.setMode(.challengesRequired)
            try draft.add(.math, token: UUID())
            let definition = try draft.definition(at: now)
            XCTAssertEqual(definition.selectedSound, choice.selection)
            let session = try WakeUpSession(id: UUID(), definition: definition,
                context: ScheduleContext(timeZoneIdentifier: "UTC"),
                plan: BackupPlan(at: now.addingTimeInterval(60), ids: (0..<5).map { _ in UUID() }), createdAt: now)
            XCTAssertEqual(session.definitionSnapshot.selectedSound, choice.selection)
            let state = try RepositoryState(definitions: [definition],
                sessions: [PersistedSession(session: session, updatedAt: now)])
            let saved = try await repository.commit(state, expecting: version)
            let read = try await DiskRepository(directory: directory).load()
            XCTAssertEqual(read, .loaded(saved, interruptedWrite: false))
            version = read.version
            guard case let .loaded(snapshot, _) = read else { return XCTFail("Missing saved sound") }
            let loaded = try XCTUnwrap(snapshot.state.definitions.first)
            XCTAssertEqual(AlarmEditorDraft(loaded).sound, choice)
            let restoredSession = try XCTUnwrap(snapshot.state.sessions.first).session
            let edited = try loaded.replacing(time: loaded.time, weekdays: loaded.weekdays,
                enabled: loaded.enabled, mode: loaded.dismissalMode, challenges: loaded.challengeSequence,
                sound: choice == .systemDefault ? .bundled(.siren) : .systemDefault, at: now.addingTimeInterval(1))
            XCTAssertNotEqual(edited.selectedSound, restoredSession.definitionSnapshot.selectedSound)
            for alarm in restoredSession.plan.alarms {
                XCTAssertEqual(try AlarmRequest(session: restoredSession, alarmID: alarm.id).selectedSound, choice.selection)
            }
        }
    }
}

@MainActor
private final class RecordingPreview: PreviewPlayback {
    var starts = 0
    var stops = 0
    var current: URL?
    var fail = false
    func start(_ url: URL) throws {
        starts += 1; current = url
        if fail { throw NSError(domain: "preview-test", code: 1) }
    }
    func stop() { stops += 1; current = nil }
}
