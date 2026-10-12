import Foundation

public struct MathProblem: Equatable, Sendable {
    public let id: UUID
    public let prompt: String
    public let expectedAnswer: Int

    public init(id: UUID, prompt: String, expectedAnswer: Int) throws {
        try require(!prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && prompt.count <= 512,
                    "Invalid math prompt")
        self.id = id; self.prompt = prompt; self.expectedAnswer = expectedAnswer
    }

    /// All randomness and identity come from the caller. Hard expressions use
    /// explicit parentheses so the typed answer has one unambiguous meaning.
    public static func generate<R: RandomNumberGenerator>(difficulty: Difficulty, id: UUID,
                                                          using random: inout R) throws -> Self {
        switch difficulty {
        case .easy:
            let a = Int.random(in: 1...99, using: &random)
            let b = Int.random(in: 1...99, using: &random)
            let add = Bool.random(using: &random)
            return try Self(id: id, prompt: "\(a) \(add ? "+" : "−") \(b)", expectedAnswer: add ? a + b : a - b)
        case .medium:
            let operation = Int.random(in: 0...2, using: &random)
            let bound = operation == 2 ? 12 : 99
            let a = Int.random(in: 1...bound, using: &random)
            let b = Int.random(in: 1...bound, using: &random)
            let symbol = ["+", "−", "×"][operation]
            let answer = operation == 0 ? a + b : operation == 1 ? a - b : a * b
            return try Self(id: id, prompt: "\(a) \(symbol) \(b)", expectedAnswer: answer)
        case .hard:
            let a = Int.random(in: 2...12, using: &random)
            let b = Int.random(in: 2...12, using: &random)
            let c = Int.random(in: 1...99, using: &random)
            let add = Bool.random(using: &random)
            return try Self(id: id, prompt: "(\(a) × \(b)) \(add ? "+" : "−") \(c)",
                            expectedAnswer: add ? a * b + c : a * b - c)
        }
    }
}

public enum MathSubmission: Equatable, Sendable { case invalid, wrong, stale, correct, completed }

/// A candidate reducer over the existing durable record. Commit the entire record
/// before exposing it. Problem UUID + challenge identity bind every submission.
public struct MathEngine: Equatable, Sendable {
    public private(set) var coordinator: ChallengeCoordinator
    public var record: PersistedSession { coordinator.record }
    public var problem: MathProblem? {
        guard let checkpoint = record.checkpoint,
              case let .math(id, prompt, answer) = checkpoint.detail else { return nil }
        return try? MathProblem(id: id, prompt: prompt, expectedAnswer: answer)
    }
    public var correctAnswers: Int {
        if case let .math(count) = record.session.progress { return count }
        return 0
    }

    public init(restoring record: PersistedSession) throws {
        coordinator = try ChallengeCoordinator(restoring: record)
        guard case .math = coordinator.currentChallenge else { throw DomainError.outOfOrder }
    }

    public mutating func prepare(_ problem: MathProblem, for identity: ChallengeIdentity, at date: Date) throws {
        guard identity == coordinator.currentIdentity else { throw DomainError.outOfOrder }
        if self.problem != nil { return }
        try coordinator.saveCheckpoint(checkpoint(problem, index: identity.index), for: identity, at: date)
    }

    public mutating func submit(_ text: String, problemID: UUID, for identity: ChallengeIdentity,
                                next: MathProblem?, at date: Date) throws -> MathSubmission {
        guard identity == coordinator.currentIdentity else { throw DomainError.outOfOrder }
        guard let problem, problem.id == problemID else { return .stale }
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = input.first == "-" || input.first == "+" ? input.dropFirst() : input[...]
        guard !digits.isEmpty, digits.utf8.allSatisfy({ (48...57).contains($0) }),
              let answer = Int(input) else { return .invalid }
        guard answer == problem.expectedAnswer else { return .wrong }
        guard case let .math(configuration) = coordinator.currentChallenge else { throw DomainError.outOfOrder }
        var candidate = coordinator
        let count = correctAnswers + 1
        if count == configuration.requiredCorrect {
            try candidate.recordSuccess(for: identity, at: date)
            coordinator = candidate
            return .completed
        }
        guard let next, next.id != problem.id else {
            throw DomainError.invalidConfiguration("Next math problem needs a fresh identity")
        }
        try candidate.recordProgress(.math(correctAnswers: count), for: identity, at: date)
        try candidate.saveCheckpoint(checkpoint(next, index: identity.index), for: identity, at: date)
        coordinator = candidate
        return .correct
    }

    private func checkpoint(_ problem: MathProblem, index: Int) -> ResumeCheckpoint {
        ResumeCheckpoint(challengeIndex: index, detail: .math(problemID: problem.id,
                          prompt: problem.prompt, expectedAnswer: problem.expectedAnswer))
    }
}
