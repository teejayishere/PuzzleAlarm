import ActivityKit
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class LifecyclePlatformTests: XCTestCase, @unchecked Sendable {
    func testOrdinaryTranslationHasNoSolveActionAndPreservesScheduleAndSound() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        for days: Set<Weekday> in [[], [.monday, .friday]] {
            let definition = try AlarmDefinition(id: UUID(), time: AlarmTime(hour: 7, minute: 15),
                weekdays: days, enabled: true, dismissalMode: .annoyingOnly,
                challengeSequence: ChallengeSequence([]), selectedSound: .bundled(.siren),
                createdAt: now, updatedAt: now)
            let request = try AlarmRequest(definition: definition, alarmID: UUID(), date: now.addingTimeInterval(60))
            XCTAssertNil(request.metadata.sessionID)
            XCTAssertNil(AlarmConfigurationFactory.presentation(challenge: false).alert.secondaryButton)
            XCTAssertEqual(AlarmConfigurationFactory.selectedSound(request.selectedSound), .named("siren.caf"))
            XCTAssertEqual(AlarmConfigurationFactory.selectedSound(.systemDefault), .default)
            let schedule = AlarmConfigurationFactory.schedule(for: request)
            if days.isEmpty {
                guard case let .fixed(date) = schedule else { return XCTFail("One-time must be fixed") }
                XCTAssertEqual(date, request.plannedAlarm.date)
            } else {
                guard case let .relative(relative) = schedule else { return XCTFail("Weekly must be relative") }
                XCTAssertEqual(relative.time.hour, 7)
                XCTAssertEqual(relative.repeats, .weekly([.monday, .friday]))
            }
            _ = AlarmConfigurationFactory.configuration(for: request)
        }
    }

    func testProductionDiskAndAdapterComposeWithLifecycleWithoutCallingDaemon() async throws {
        let directory = try DiskRepository.applicationSupportDirectory().appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let values = PlatformAlarmValues()
        let service = AlarmManagerService(operations: .init(
            authorization: { .authorized }, requestAuthorization: { .authorized },
            schedule: { id, _ in values.insert(id); return .init(id: id, state: .scheduled) },
            cancel: { values.remove($0) }, currentAlarms: { values.snapshot },
            observeAlarms: { receive in receive(values.snapshot) }
        ))
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let definition = try AlarmDefinition(id: UUID(), time: AlarmTime(hour: 7, minute: 15),
            weekdays: [.monday], enabled: true, dismissalMode: .annoyingOnly,
            challengeSequence: ChallengeSequence([]), selectedSound: .systemDefault,
            createdAt: now, updatedAt: now)
        let context = try ScheduleContext(timeZoneIdentifier: "UTC")
        let coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: service, clock: { now })
        let created = try await coordinator.create(definition, context: context)
        XCTAssertEqual(values.snapshot.count, 1)
        let replacement = try definition.replacing(time: definition.time, weekdays: definition.weekdays,
            enabled: true, mode: .challengesRequired,
            challenges: ChallengeSequence([.math(MathConfiguration())]), sound: .systemDefault, at: now)
        let edited = try await coordinator.edit(replacement, expecting: definition, context: context)
        XCTAssertEqual(edited.state.sessions[0].session.phase, .armed)
        XCTAssertEqual(values.snapshot.count, 5)
        XCTAssertFalse(values.snapshot.contains { $0.id == created.state.detachedOwnership[0].alarmKitID })
        guard case let .loaded(snapshot, _) = try await DiskRepository(directory: directory).load() else {
            return XCTFail("Missing persisted lifecycle")
        }
        XCTAssertEqual(snapshot.state, edited.state)
    }
}

private final class PlatformAlarmValues: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: Set<UUID> = []
    func insert(_ id: UUID) { lock.withLock { _ = ids.insert(id) } }
    func remove(_ id: UUID) { lock.withLock { _ = ids.remove(id) } }
    var snapshot: [RegisteredAlarm] { lock.withLock { ids.map { .init(id: $0, state: .scheduled) } } }
}
