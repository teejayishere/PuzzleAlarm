import Foundation
import Testing
@testable import PuzzleAlarmCore

// Stage 0 only: verifies the runner executes Swift Testing and Foundation Codable.
// This provides no evidence for alarm behavior or domain correctness.
@Test func foundationCodableAvailableInPackageTests() throws {
    struct Fixture: Codable, Equatable {
        let id: UUID
        let timestamp: Date
    }
    let original = Fixture(
        id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)),
        timestamp: Date(timeIntervalSince1970: 1_000)
    )
    let data = try JSONEncoder().encode(original)
    #expect(try JSONDecoder().decode(Fixture.self, from: data) == original)
}
