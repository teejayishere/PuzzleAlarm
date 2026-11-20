#if DEBUG && targetEnvironment(simulator)
import Foundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class SimulatorUITestFixtureTests: XCTestCase, @unchecked Sendable {
    func testNamespacesResetAndRelaunchUseExactDiskState() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let first = UUID().uuidString, second = UUID().uuidString
        func environment(_ namespace: String, _ fixture: String) -> [String: String] {
            ["PUZZLEALARM_TEST_NAMESPACE": namespace, "PUZZLEALARM_TEST_FIXTURE": fixture]
        }
        let ordinary = try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"],
            environment: environment(first, "ordinary"))
        let challenge = try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"],
            environment: environment(second, "challenge"))
        let file = ordinary.appendingPathComponent("state.json")
        let originalBytes = try Data(contentsOf: file)
        let challengeBytes = try Data(contentsOf: challenge.appendingPathComponent("state.json"))
        let repository = DiskRepository(directory: ordinary)
        guard case let .loaded(snapshot, _) = try await repository.load() else { return XCTFail("No fixture") }
        XCTAssertEqual(snapshot.state, try SimulatorUITestFixture.state("ordinary"))
        var changed = snapshot.state
        changed.definitions = []
        _ = try await repository.commit(changed, expecting: .revision(snapshot.revision))
        let editedBytes = try Data(contentsOf: file)
        XCTAssertNotEqual(editedBytes, originalBytes)
        let relaunched = try SimulatorUITestFixture.prepare(root: root, arguments: [],
            environment: environment(first, "ordinary"))
        XCTAssertEqual(relaunched, ordinary)
        XCTAssertEqual(try Data(contentsOf: file), editedBytes, "Relaunch must not seed or write")
        _ = try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"],
            environment: environment(first, "empty"))
        guard case let .loaded(empty, _) = try await DiskRepository(directory: ordinary).load() else { return XCTFail("No empty fixture") }
        XCTAssertTrue(empty.state.definitions.isEmpty)
        XCTAssertEqual(try Data(contentsOf: challenge.appendingPathComponent("state.json")), challengeBytes)
        guard case let .loaded(other, _) = try await DiskRepository(directory: challenge).load() else { return XCTFail("No challenge fixture") }
        XCTAssertEqual(other.state, try SimulatorUITestFixture.state("challenge"))
        XCTAssertEqual(other.state.definitions.map(\.id), [SimulatorUITestFixture.challengeID])
        let scheduler = try SimulatorAlarmScheduler(directory: challenge)
        XCTAssertTrue(try scheduler.currentAlarms().isEmpty, "Seeding disabled fixtures has no scheduler effects")
    }

    func testInvalidOrUnseededNamespaceFailsClosed() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertThrowsError(try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"], environment: [:]))
        XCTAssertThrowsError(try SimulatorUITestFixture.prepare(root: root, arguments: ["--ui-reset"], environment: [
            "PUZZLEALARM_TEST_NAMESPACE": "../escape", "PUZZLEALARM_TEST_FIXTURE": "ordinary"]))
        XCTAssertThrowsError(try SimulatorUITestFixture.prepare(root: root, arguments: [], environment: [
            "PUZZLEALARM_TEST_NAMESPACE": UUID().uuidString, "PUZZLEALARM_TEST_FIXTURE": "ordinary"]))
    }
}
#endif
