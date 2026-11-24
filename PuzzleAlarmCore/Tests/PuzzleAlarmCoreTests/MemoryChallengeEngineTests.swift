import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func memoryEngineCreatesDeterministicVisibleRoundWithDeadline() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let identifier = UUID()
    let configuration = try MemoryConfiguration(sequenceLength: 4, displayDuration: 7)
    var values = [0, 1, 0, 9][...]
    let detail = try MemoryChallengeEngine.makeRound(configuration: configuration, at: now,
        makeID: { identifier }, randomInteger: { range in
            #expect(range == 0...9)
            return values.removeFirst()
        })
    guard case let .memory(id, digits, phase, deadline) = detail else {
        Issue.record("Memory engine returned a non-memory checkpoint")
        return
    }
    #expect(id == identifier)
    #expect(digits == [0, 1, 0, 9])
    #expect(phase == .visible)
    #expect(deadline == now.addingTimeInterval(7))
    #expect(values.isEmpty)
}

@Test func memoryEngineGuaranteesFreshDigitsAfterRandomCollision() throws {
    for digit in [0, 9] {
        let previous = Array(repeating: digit, count: 4)
        let identifier = UUID()
        let detail = try MemoryChallengeEngine.makeRound(configuration: MemoryConfiguration(sequenceLength: 4),
            at: Date(timeIntervalSince1970: 1_800_000_000), previousDigits: previous,
            makeID: { identifier }, randomInteger: { _ in digit })
        guard case let .memory(id, digits, _, _) = detail else {
            Issue.record("Missing fresh memory round")
            return
        }
        #expect(id == identifier)
        #expect(digits != previous)
        #expect(digits.dropLast() == previous.dropLast())
        #expect(digits.last == (digit + 1) % 10)
    }
}

@Test func memoryEnginePreservesLeadingZerosAndRequiresExactASCIIDigits() {
    let digits = [0, 0, 7, 2]
    #expect(MemoryChallengeEngine.accepts("0072", digits: digits))
    #expect(MemoryChallengeEngine.accepts(" \n0072\t", digits: digits))
    for answer in ["72", "00072", "0073", "00 72", "+0072", "００７２", "٠٠٧٢", "", "0072x"] {
        #expect(!MemoryChallengeEngine.accepts(answer, digits: digits))
    }
    #expect(!MemoryChallengeEngine.accepts("", digits: []))
    #expect(!MemoryChallengeEngine.accepts("07", digits: [0, 10]))
}

@Test func memoryEngineRejectsBadClockAndRandomness() throws {
    let configuration = try MemoryConfiguration()
    for date in [Date(timeIntervalSince1970: .nan), Date(timeIntervalSince1970: .infinity), .distantFuture] {
        #expect(throws: DomainError.self) {
            try MemoryChallengeEngine.makeRound(configuration: configuration, at: date,
                makeID: UUID.init, randomInteger: { _ in 0 })
        }
    }
    for digit in [-1, 10] {
        #expect(throws: DomainError.self) {
            try MemoryChallengeEngine.makeRound(configuration: configuration,
                at: Date(timeIntervalSince1970: 1_800_000_000),
                makeID: UUID.init, randomInteger: { _ in digit })
        }
    }
}
