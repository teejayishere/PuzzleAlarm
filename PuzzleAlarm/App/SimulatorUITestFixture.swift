#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore

// Test composition only. Never used by device/release or by AlarmDraft identity.
enum SimulatorUITestFixture {
    static let ordinaryID = UUID(uuidString: "6A000000-0000-4000-8000-000000000001")!
    static let challengeID = UUID(uuidString: "6A000000-0000-4000-8000-000000000002")!
    static let qrToken = UUID(uuidString: "6A000000-0000-4000-8000-000000000003")!

    static func prepare(root: URL, arguments: [String], environment: [String: String]) throws -> URL {
        guard let raw = environment["PUZZLEALARM_TEST_NAMESPACE"], let namespace = UUID(uuidString: raw),
              let kind = environment["PUZZLEALARM_TEST_FIXTURE"],
              ["empty", "ordinary", "challenge", "math", "memory", "qr", "playable", "corrupt"].contains(kind) else {
            throw PersistenceError.io("Explicit UI test namespace/fixture required")
        }
        let directory = root.appendingPathComponent("Stage6UITests", isDirectory: true)
            .appendingPathComponent(namespace.uuidString, isDirectory: true)
        let file = directory.appendingPathComponent("state.json")
        if arguments.contains("--ui-reset") {
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if kind == "corrupt" {
                try Data("invalid navigation-test repository".utf8).write(to: file, options: .atomic)
            } else {
                let snapshot = FixtureSnapshot(state: try state(kind))
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys]
                try encoder.encode(snapshot).write(to: file, options: .atomic)
            }
        } else if !FileManager.default.fileExists(atPath: file.path) {
            // A relaunch must not silently create a replacement fixture.
            throw PersistenceError.io("UI test relaunch has no seeded repository")
        }
        return directory
    }

    // Schema-2 fixture document. DiskRepository decodes/validates it normally;
    // test composition does not expose or change the core's internal codec.
    private struct FixtureSnapshot: Encodable {
        let schemaVersion = 2
        let revision = UUID()
        let state: RepositoryState
    }

    static func state(_ kind: String) throws -> RepositoryState {
        if kind == "empty" { return try RepositoryState() }
        if kind == "playable" {
            let date = Date(timeIntervalSince1970: 1_700_000_000)
            let alarm = try AlarmDefinition(id: challengeID,
                time: AlarmTime(hour: 7, minute: 0), weekdays: [], enabled: true,
                dismissalMode: .challengesRequired,
                challengeSequence: ChallengeSequence([
                    .math(try MathConfiguration(difficulty: .easy, requiredCorrect: 1)),
                    .memory(try MemoryConfiguration(sequenceLength: 2, displayDuration: 30, requiredRounds: 1)),
                    .qr(QRConfiguration(token: qrToken))
                ]), selectedSound: .systemDefault, createdAt: date, updatedAt: date)
            return try RepositoryState(definitions: [alarm])
        }
        let challenge = ["challenge", "math", "memory", "qr"].contains(kind)
        let configurations: [ChallengeConfiguration] = [
            .memory(try MemoryConfiguration(difficulty: .hard, sequenceLength: 8,
                displayDuration: 2.5, requiredRounds: 2)),
            .qr(QRConfiguration(token: qrToken)),
            .math(try MathConfiguration(difficulty: .medium, requiredCorrect: 5))
        ]
        let sequence = try ChallengeSequence(challenge ? configurations.filter {
            kind == "challenge" || $0.kind.rawValue == kind
        } : [])
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let alarm = try AlarmDefinition(id: challenge ? challengeID : ordinaryID,
            time: AlarmTime(hour: 7, minute: 0), weekdays: [.monday, .friday], enabled: false,
            dismissalMode: challenge ? .challengesRequired : .annoyingOnly,
            challengeSequence: sequence, selectedSound: .systemDefault,
            createdAt: date, updatedAt: date)
        return try RepositoryState(definitions: [alarm])
    }
}
#endif
