import AlarmKit
import AppIntents
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class AlarmCapabilityTests: XCTestCase, @unchecked Sendable {
    private enum Failure: Error { case injected }

    private func session() throws -> WakeUpSession {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let definition = try AlarmDefinition(
            id: UUID(), time: AlarmTime(hour: 6, minute: 30), weekdays: [.monday],
            enabled: true, dismissalMode: .challengesRequired,
            challengeSequence: ChallengeSequence([.math(try MathConfiguration())]),
            selectedSound: .systemDefault, createdAt: date, updatedAt: date
        )
        return try WakeUpSession(
            id: UUID(), definition: definition,
            context: ScheduleContext(timeZoneIdentifier: "America/Chicago"),
            plan: BackupPlan(at: date.addingTimeInterval(60), ids: (0..<5).map { _ in UUID() }),
            createdAt: date
        )
    }

    func testMetadataPreservesOccurrenceAndRoleForEveryPlannedID() throws {
        let session = try session()
        for (index, alarm) in session.plan.alarms.enumerated() {
            let request = try AlarmRequest(session: session, alarmID: alarm.id)
            XCTAssertEqual(request.plannedAlarm, alarm)
            XCTAssertEqual(request.metadata.sessionID, session.id)
            XCTAssertEqual(request.metadata.parentAlarmID, session.parentAlarmID)
            XCTAssertEqual(request.metadata.ordinal, index)
            XCTAssertEqual(request.metadata.isPrimary, index == 0)
            let encoded = try JSONEncoder().encode(request.metadata)
            XCTAssertEqual(try JSONDecoder().decode(OccurrenceMetadata.self, from: encoded), request.metadata)
            let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            XCTAssertEqual(Set(fields.keys), ["sessionID", "parentAlarmID", "ordinal"])
        }
        XCTAssertThrowsError(try AlarmRequest(session: session, alarmID: UUID())) {
            XCTAssertEqual($0 as? DomainError, .unknownAlarm)
        }
    }

    func testRelativeTranslationPreservesAllWeekdaySubsetsAndTime() throws {
        let days = Weekday.allCases
        let expected: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        for mask in 0..<128 {
            let selected = Set(days.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element))
            let schedule = AlarmConfigurationFactory.relativeSchedule(
                time: try AlarmTime(hour: 23, minute: 59), weekdays: selected
            )
            guard case let .relative(relative) = schedule else { return XCTFail("Expected relative") }
            XCTAssertEqual(relative.time.hour, 23)
            XCTAssertEqual(relative.time.minute, 59)
            if mask == 0 {
                XCTAssertEqual(relative.repeats, .never)
            } else {
                let expectedDays = expected.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element)
                XCTAssertEqual(relative.repeats, .weekly(expectedDays))
            }
        }
    }

    func testPresentationHasOnlyAlertAndCustomSolveAction() {
        let presentation = AlarmConfigurationFactory.presentation()
        XCTAssertNil(presentation.countdown)
        XCTAssertNil(presentation.paused)
        XCTAssertEqual(presentation.alert.title, "PuzzleAlarm")
        XCTAssertEqual(presentation.alert.secondaryButton?.text, "Solve")
        XCTAssertEqual(presentation.alert.secondaryButtonBehavior, .custom)
    }

    func testIntentCarriesOccurrenceIdentityAndRequestsForeground() throws {
        let session = try session()
        let intent = OpenOccurrenceIntent(occurrenceID: session.id)
        XCTAssertEqual(UUID(uuidString: intent.occurrenceID), session.id)
        XCTAssertEqual(OpenOccurrenceIntent.supportedModes, .foreground)
        XCTAssertFalse(OpenOccurrenceIntent.isDiscoverable)
    }

    func testAuthorizationMapping() {
        XCTAssertEqual(AlarmAuthorization(.notDetermined), .notDetermined)
        XCTAssertEqual(AlarmAuthorization(.authorized), .authorized)
        XCTAssertEqual(AlarmAuthorization(.denied), .denied)
    }

    func testAdapterPreservesStableIDsAndForwardsSnapshotAndUpdates() async throws {
        let session = try session()
        let request = try AlarmRequest(session: session, alarmID: session.backupAlarmIDs[2])
        let expected = RegisteredAlarm(id: request.plannedAlarm.id, state: .scheduled)
        let cancelled = LockedValues<UUID>()
        let observed = LockedValues<[RegisteredAlarm]>()
        let service: any AlarmScheduling = AlarmManagerService(operations: .init(
            authorization: { .notDetermined },
            requestAuthorization: { .denied },
            schedule: { id, _ in
                XCTAssertEqual(id, expected.id)
                return RegisteredAlarm(id: id, state: .scheduled)
            },
            cancel: { cancelled.append($0) },
            currentAlarms: { [expected] },
            observeAlarms: { receive in
                receive([expected])
                receive([])
            }
        ))
        XCTAssertEqual(service.authorization, .notDetermined)
        let authorization = try await service.requestAuthorization()
        XCTAssertEqual(authorization, .denied)
        let scheduled = try await service.schedule(request)
        XCTAssertEqual(scheduled, expected)
        XCTAssertEqual(try service.currentAlarms(), [expected])
        try service.cancel(id: expected.id)
        XCTAssertEqual(cancelled.values, [expected.id])
        await service.observeAlarms { alarms in
            observed.append(alarms)
        }
        XCTAssertEqual(observed.values, [[expected], []])
        XCTAssertEqual(session.phase, .planned)
    }

    func testAdapterDoesNotHidePermissionScheduleCancelOrSnapshotErrors() async throws {
        let session = try session()
        let request = try AlarmRequest(session: session, alarmID: session.primaryAlarmID)
        let service = AlarmManagerService(operations: .init(
            authorization: { .denied },
            requestAuthorization: { throw Failure.injected },
            schedule: { _, _ in throw Failure.injected },
            cancel: { _ in throw Failure.injected },
            currentAlarms: { throw Failure.injected },
            observeAlarms: { _ in }
        ))
        do {
            _ = try await service.requestAuthorization()
            XCTFail("Authorization error swallowed")
        } catch { XCTAssertTrue(error is Failure) }
        do {
            _ = try await service.schedule(request)
            XCTFail("Scheduling error swallowed")
        } catch { XCTAssertTrue(error is Failure) }
        XCTAssertThrowsError(try service.cancel(id: request.plannedAlarm.id)) {
            XCTAssertTrue($0 is Failure)
        }
        XCTAssertThrowsError(try service.currentAlarms()) {
            XCTAssertTrue($0 is Failure)
        }
    }
}

// Test-only synchronized recorder for the adapter's Sendable callbacks.
private final class LockedValues<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Value] = []
    func append(_ value: Value) { lock.withLock { stored.append(value) } }
    var values: [Value] { lock.withLock { stored } }
}
