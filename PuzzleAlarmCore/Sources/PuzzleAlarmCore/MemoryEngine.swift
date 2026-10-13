import Foundation

public struct MemoryRound: Equatable, Sendable {
    public let id: UUID
    public let digits: [Int]
    public init(id: UUID, digits: [Int]) throws {
        try require((2...12).contains(digits.count) && digits.allSatisfy { (0...9).contains($0) },
                    "Invalid memory digits")
        self.id = id; self.digits = digits
    }
    public static func generate<R: RandomNumberGenerator>(configuration: MemoryConfiguration, id: UUID,
                                                          using random: inout R) throws -> Self {
        try Self(id: id, digits: (0..<configuration.sequenceLength).map { _ in Int.random(in: 0...9, using: &random) })
    }
}

public enum MemorySubmission: Equatable, Sendable { case invalid, notHidden, stale, wrong, correct, completed }

/// Candidate reducer: persist the whole record before presenting a reveal or progress.
/// Reopening/interruption hides the existing round; it never restarts its deadline.
public struct MemoryEngine: Equatable, Sendable {
    public private(set) var coordinator: ChallengeCoordinator
    public var record: PersistedSession { coordinator.record }
    public var round: MemoryRound? {
        guard case let .memory(id, digits, _, _) = record.checkpoint?.detail else { return nil }
        return try? MemoryRound(id: id, digits: digits)
    }
    public var phase: ResumeCheckpoint.MemoryPhase? {
        guard case let .memory(_, _, phase, _) = record.checkpoint?.detail else { return nil }
        return phase
    }
    public var deadline: Date? {
        guard case let .memory(_, _, _, deadline) = record.checkpoint?.detail else { return nil }
        return deadline
    }
    public var successfulRounds: Int {
        if case let .memory(count) = record.session.progress { return count }
        return 0
    }
    public init(restoring record: PersistedSession) throws {
        coordinator = try ChallengeCoordinator(restoring: record)
        guard case .memory = coordinator.currentChallenge else { throw DomainError.outOfOrder }
    }
    /// The only answer-bearing presentation API. Hidden/expired rounds expose no digits.
    public func visibleDigits(at date: Date) -> String? {
        guard date >= record.updatedAt, phase == .visible, let deadline, date < deadline, let round else { return nil }
        return round.digits.map(String.init).joined()
    }
    public mutating func prepare(_ round: MemoryRound, for identity: ChallengeIdentity, at date: Date) throws {
        guard identity == coordinator.currentIdentity else { throw DomainError.outOfOrder }
        if self.round != nil { return }
        try reveal(round, for: identity, at: date)
    }
    public mutating func hide(for identity: ChallengeIdentity, at date: Date) throws {
        guard identity == coordinator.currentIdentity else { throw DomainError.outOfOrder }
        guard let round, phase != .hidden else { return }
        try coordinator.saveCheckpoint(checkpoint(round, index: identity.index, phase: .hidden),
                                       for: identity, at: date)
    }
    public mutating func submit(_ text: String, roundID: UUID, for identity: ChallengeIdentity,
                                next: MemoryRound?, at date: Date) throws -> MemorySubmission {
        guard identity == coordinator.currentIdentity else { throw DomainError.outOfOrder }
        guard let round, round.id == roundID else { return .stale }
        try require(date >= record.updatedAt, "Memory timestamp regressed")
        guard phase == .hidden || (phase == .visible && deadline.map { date >= $0 } == true) else { return .notHidden }
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.utf8.count == round.digits.count, input.utf8.allSatisfy({ (48...57).contains($0) }) else { return .invalid }
        let correct = input == round.digits.map(String.init).joined()
        guard case let .memory(configuration) = coordinator.currentChallenge else { throw DomainError.outOfOrder }
        var candidate = self
        if correct && successfulRounds + 1 == configuration.requiredRounds {
            try candidate.coordinator.recordSuccess(for: identity, at: date)
            self = candidate
            return .completed
        }
        guard let next, next.id != round.id, next.digits != round.digits else {
            throw DomainError.invalidConfiguration("Next memory round needs fresh identity and digits")
        }
        if correct {
            try candidate.coordinator.recordProgress(.memory(successfulRounds: successfulRounds + 1), for: identity, at: date)
        }
        try candidate.reveal(next, for: identity, at: date)
        self = candidate
        return correct ? .correct : .wrong
    }
    private mutating func reveal(_ round: MemoryRound, for identity: ChallengeIdentity, at date: Date) throws {
        guard case let .memory(configuration) = coordinator.currentChallenge else { throw DomainError.outOfOrder }
        try require(round.digits.count == configuration.sequenceLength, "Memory length mismatch")
        try coordinator.saveCheckpoint(checkpoint(round, index: identity.index, phase: .visible,
            deadline: date.addingTimeInterval(configuration.displayDuration)), for: identity, at: date)
    }
    private func checkpoint(_ round: MemoryRound, index: Int, phase: ResumeCheckpoint.MemoryPhase,
                            deadline: Date? = nil) -> ResumeCheckpoint {
        ResumeCheckpoint(challengeIndex: index, detail: .memory(roundID: round.id, digits: round.digits,
                                                               phase: phase, visibleUntil: deadline))
    }
}
