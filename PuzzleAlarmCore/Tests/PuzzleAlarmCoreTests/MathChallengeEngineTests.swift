import Foundation
import Testing
@testable import PuzzleAlarmCore

private func mathProblem(_ difficulty: Difficulty, draws: [Int]) throws -> (String, Int) {
    let identifier = UUID()
    var remaining = draws[...]
    let detail = try MathChallengeEngine.makeProblem(difficulty: difficulty, makeID: { identifier }) { range in
        let value = remaining.removeFirst()
        #expect(range.contains(value))
        return value
    }
    guard case let .math(id, prompt, answer) = detail else {
        Issue.record("Math engine returned a non-math checkpoint")
        return ("", 0)
    }
    #expect(id == identifier)
    #expect(remaining.isEmpty)
    return (prompt, answer)
}

@Test func mathEngineGeneratesEveryOperationWithMatchingAnswer() throws {
    let cases: [(Difficulty, [Int], String, Int)] = [
        (.easy, [0, 1, 99], "1 + 99", 100),
        (.easy, [1, 1, 99], "1 − 99", -98),
        (.medium, [0, 99, 99], "99 + 99", 198),
        (.medium, [1, 10, 99], "10 − 99", -89),
        (.medium, [2, 12, 12], "12 × 12", 144),
        (.hard, [0, 12, 12, 99], "(12 × 12) + 99", 243),
        (.hard, [1, 2, 2, 99], "(2 × 2) − 99", -95)
    ]
    for (difficulty, draws, expectedPrompt, expectedAnswer) in cases {
        let (prompt, answer) = try mathProblem(difficulty, draws: draws)
        #expect(prompt == expectedPrompt)
        #expect(answer == expectedAnswer)
    }
}

@Test func mathEngineRejectsOutOfRangeInjectedRandomness() {
    for difficulty in Difficulty.allCases {
        #expect(throws: DomainError.self) {
            try MathChallengeEngine.makeProblem(difficulty: difficulty, makeID: UUID.init) { _ in -1 }
        }
        #expect(throws: DomainError.self) {
            try MathChallengeEngine.makeProblem(difficulty: difficulty, makeID: UUID.init) { $0.upperBound + 1 }
        }
        var calls = 0
        #expect(throws: DomainError.self) {
            try MathChallengeEngine.makeProblem(difficulty: difficulty, makeID: UUID.init) { range in
                calls += 1
                return calls == 1 ? range.lowerBound : range.upperBound + 1
            }
        }
    }
}

@Test func mathEngineRequiresAWholeASCIIInteger() {
    #expect(MathChallengeEngine.accepts(" \n-98\t", expectedAnswer: -98))
    #expect(MathChallengeEngine.accepts("+007", expectedAnswer: 7))
    #expect(MathChallengeEngine.accepts(String(Int.min), expectedAnswer: Int.min))
    #expect(MathChallengeEngine.accepts(String(Int.max), expectedAnswer: Int.max))
    for answer in ["", " ", "+", "-", "--7", "7.0", "7e0", "7 0", "７", "٧", "7x",
                   "999999999999999999999999999999999999999999999999999999999999999999999"] {
        #expect(!MathChallengeEngine.accepts(answer, expectedAnswer: 7))
    }
    #expect(!MathChallengeEngine.accepts("8", expectedAnswer: 7))
    #expect(!MathChallengeEngine.accepts("98", expectedAnswer: -98))
}
