#if DEBUG
import Foundation
import PuzzleAlarmCore

// DEBUG only. All business behavior still runs through the production coordinator.
// Persist simulated OS IDs separately so a UI-test process relaunch models both
// durable application state and surviving external alarms.
final class TestAlarmScheduler: AlarmScheduling, @unchecked Sendable {
    struct Values {
        var authorization: AlarmAuthorization = .authorized
        var alarms: [RegisteredAlarm] = []
        var schedules: [AlarmRequest] = []
        var cancellations: [UUID] = []
        var failSchedules = 0
        var failCancellation = false
        var failSnapshot = false
        var authorizationRequests = 0
        var afterSchedule: (@Sendable () async -> Void)?
    }
    private let lock = NSLock()
    private var storage = Values()
    private let file: URL?
    init(file: URL? = nil) throws {
        self.file = file
        if let file, FileManager.default.fileExists(atPath: file.path) {
            let ids = try JSONDecoder().decode([UUID].self, from: Data(contentsOf: file))
            storage.alarms = ids.map { .init(id: $0, state: .scheduled) }
        }
    }
    func configure(_ action: (inout Values) -> Void) { lock.withLock { action(&storage) } }
    var values: Values { lock.withLock { storage } }
    var authorization: AlarmAuthorization { values.authorization }
    func requestAuthorization() async throws -> AlarmAuthorization {
        lock.withLock {
            storage.authorizationRequests += 1
            if storage.authorization == .notDetermined { storage.authorization = .authorized }
            return storage.authorization
        }
    }
    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        let hook = try lock.withLock {
            storage.schedules.append(request)
            if storage.failSchedules > 0 { storage.failSchedules -= 1; throw TestEffectError.failed }
            storage.alarms.removeAll { $0.id == request.plannedAlarm.id }
            storage.alarms.append(.init(id: request.plannedAlarm.id, state: .scheduled))
            try persist()
            return storage.afterSchedule
        }
        await hook?()
        return .init(id: request.plannedAlarm.id, state: .scheduled)
    }
    func cancel(id: UUID) throws {
        try lock.withLock {
            storage.cancellations.append(id)
            if storage.failCancellation { throw TestEffectError.failed }
            storage.alarms.removeAll { $0.id == id }
            try persist()
        }
    }
    func currentAlarms() throws -> [RegisteredAlarm] {
        try lock.withLock {
            if storage.failSnapshot { throw TestEffectError.failed }
            return storage.alarms
        }
    }
    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async {
        if let snapshot = try? currentAlarms() { receive(snapshot) }
    }
    private func persist() throws {
        if let file { try JSONEncoder().encode(storage.alarms.map(\.id)).write(to: file, options: .atomic) }
    }
    enum TestEffectError: Error { case failed }
}

@MainActor
enum UITestEnvironment {
    static let now = Date(timeIntervalSince1970: 1_790_812_800)
    static let alarmID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static func make(_ environment: [String: String]) throws -> AppEnvironment {
        // Test-run names are reduced to safe path characters, never accepted as paths.
        let name = (environment["PUZZLE_TEST_NAME"] ?? "unit-host").filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PuzzleAlarmUITests", isDirectory: true)
        let directory = root.appendingPathComponent(name.isEmpty ? "default" : name, isDirectory: true)
        if environment["PUZZLE_RESET"] == "1", FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = DiskRepository(directory: directory)
        let scheduler = try TestAlarmScheduler(file: directory.appendingPathComponent("simulated-system.json"))
        let scenario = environment["PUZZLE_SCENARIO"] ?? "empty"
        scheduler.configure {
            if scenario == "notDetermined" { $0.authorization = .notDetermined }
            if scenario == "denied" { $0.authorization = .denied }
            if ["failed", "enableFailure"].contains(scenario) { $0.failSchedules = 1 }
            if scenario == "deleteFailure" { $0.failCancellation = true }
        }
        let fixedDate = now
        let store = AlarmStore(repository: repository, scheduler: scheduler, clock: { fixedDate },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        return AppEnvironment(store: store) {
            guard try await repository.load() == .missing else { return }
            if ["healthy", "disabled", "challenge", "failed", "enableFailure", "deleteFailure"].contains(scenario) {
                var draft = try AlarmEditorDraft(id: alarmID, now: now)
                draft.weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                draft.enabled = !["disabled", "enableFailure"].contains(scenario)
                if scenario == "challenge" {
                    try draft.setMode(.challengesRequired)
                    try draft.add(.math, token: alarmID)
                }
                _ = await store.save(draft)
            }
        }
    }
}
#endif
