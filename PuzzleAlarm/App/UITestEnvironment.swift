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
    static func traceToggle(_ message: String) {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PUZZLE_UI_TEST"] == "1", environment["PUZZLE_SCENARIO"] == "enableFailure" else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("toggle-input-diagnostic.log")
        let line = "\(Date().timeIntervalSince1970) pid=\(ProcessInfo.processInfo.processIdentifier) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if !FileManager.default.fileExists(atPath: url.path) { _ = FileManager.default.createFile(atPath: url.path, contents: nil) }
        guard let file = try? FileHandle(forWritingTo: url) else { return }
        defer { try? file.close() }
        _ = try? file.seekToEnd()
        try? file.write(contentsOf: data)
    }
    static let now = Date(timeIntervalSince1970: 1_790_812_800)
    static let alarmID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static func make(_ environment: [String: String]) throws -> AppEnvironment {
        traceToggle("fixture launch")
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
        let store = AlarmStore(repository: repository, scheduler: scheduler, clock: { scenario == "memory" ? Date() : fixedDate },
            makeMathProblem: { _ in try MathProblem(id: UUID(), prompt: "3 + 4", expectedAnswer: 7) },
            makeMemoryRound: { _ in try MemoryRound(id: UUID(), digits: [0, 1, 2, 3]) },
            context: { try ScheduleContext(timeZoneIdentifier: "UTC") })
        return AppEnvironment(store: store) {
            guard try await repository.load() == .missing else { return }
            if scenario == "memory" {
                let date = Date()
                var draft = try AlarmEditorDraft(id: alarmID, now: date)
                try draft.setMode(.challengesRequired)
                draft.sequence = try ChallengeSequence([.memory(try MemoryConfiguration(sequenceLength: 4,
                    displayDuration: 3, requiredRounds: 2))])
                let definition = try draft.definition(at: date)
                let ids = (0..<5).map { _ in UUID() }
                var session = try WakeUpSession(id: UUID(), definition: definition,
                    context: ScheduleContext(timeZoneIdentifier: "UTC"),
                    plan: BackupPlan(at: date, ids: ids), createdAt: date)
                try session.beginScheduling()
                for id in ids { try session.beginScheduleAttempt(id: id); try session.recordScheduled(id: id) }
                try session.arm(); try session.activate(at: date)
                _ = try await repository.commit(RepositoryState(definitions: [definition],
                    sessions: [PersistedSession(session: session, updatedAt: date)]), expecting: .missing)
                scheduler.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
                return
            }
            if ["math", "qr", "qrThenMath"].contains(scenario) {
                var draft = try AlarmEditorDraft(id: alarmID, now: now)
                try draft.setMode(.challengesRequired)
                try draft.add(.math, token: alarmID)
                draft.sequence = try ChallengeSequence(scenario == "math" ? [.math(try MathConfiguration(requiredCorrect: 2))] :
                    scenario == "qr" ? [.qr(QRConfiguration(token: alarmID))] :
                    [.qr(QRConfiguration(token: alarmID)), .math(try MathConfiguration(requiredCorrect: 1))])
                let definition = try draft.definition(at: now)
                let ids = (0..<5).map { _ in UUID() }
                var session = try WakeUpSession(id: UUID(), definition: definition,
                    context: ScheduleContext(timeZoneIdentifier: "UTC"),
                    plan: BackupPlan(at: now, ids: ids), createdAt: now)
                try session.beginScheduling()
                for id in ids { try session.beginScheduleAttempt(id: id); try session.recordScheduled(id: id) }
                try session.arm(); try session.activate(at: now)
                var record = try PersistedSession(session: session, updatedAt: now)
                if scenario == "math" {
                    var engine = try MathEngine(restoring: record)
                    try engine.prepare(MathProblem(id: UUID(), prompt: "2 + 3", expectedAnswer: 5),
                                       for: engine.coordinator.currentIdentity!, at: now)
                    record = engine.record
                }
                _ = try await repository.commit(RepositoryState(definitions: [definition], sessions: [record]),
                                                expecting: .missing)
                scheduler.configure { $0.alarms = ids.map { .init(id: $0, state: .scheduled) } }
                return
            }
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
