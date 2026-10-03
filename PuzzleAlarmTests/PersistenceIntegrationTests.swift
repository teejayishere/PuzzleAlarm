import Foundation
import PuzzleAlarmCore
import XCTest

final class PersistenceIntegrationTests: XCTestCase, @unchecked Sendable {
    func testDiskRepositoryRoundTripInIOSApplicationSupport() async throws {
        let directory = try DiskRepository.applicationSupportDirectory()
            .appendingPathComponent("IntegrationTests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let definition = try AlarmDefinition(
            id: UUID(), time: AlarmTime(hour: 6, minute: 30), weekdays: [.monday, .friday],
            enabled: true, dismissalMode: .annoyingOnly,
            challengeSequence: ChallengeSequence([]), selectedSound: .systemDefault,
            createdAt: date, updatedAt: date
        )
        let state = try RepositoryState(definitions: [definition])
        let saved = try await repository.commit(state, expecting: .missing)
        let restarted = DiskRepository(directory: directory)
        let loaded = try await restarted.load()
        XCTAssertEqual(loaded, .loaded(saved, interruptedWrite: false))
    }
}
