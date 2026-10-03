import Foundation

// Durable engine input, not an engine or UI state machine. Progress counters live
// only in WakeUpSession; the checkpoint is bound to its current challenge index.
public struct ResumeCheckpoint: Codable, Equatable, Sendable {
    public enum MemoryPhase: String, Codable, CaseIterable, Sendable {
        case generated, visible, hidden, failed, completed
    }
    public enum Detail: Codable, Equatable, Sendable {
        case math(problemID: UUID, prompt: String, expectedAnswer: Int)
        case memory(roundID: UUID, digits: [Int], phase: MemoryPhase, visibleUntil: Date?)
    }
    public let challengeIndex: Int
    public let detail: Detail

    public init(challengeIndex: Int, detail: Detail) {
        self.challengeIndex = challengeIndex
        self.detail = detail
    }

    func validate(for session: WakeUpSession, updatedAt: Date) throws {
        try require(session.phase == .active && challengeIndex == session.currentChallengeIndex,
                    "Checkpoint does not belong to active challenge")
        switch (detail, session.currentChallenge) {
        case let (.math(_, prompt, _), .math):
            try require(!prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && prompt.count <= 512,
                        "Invalid saved math problem")
        case let (.memory(_, digits, phase, deadline), .memory(configuration)):
            try require(digits.count == configuration.sequenceLength && digits.allSatisfy { (0...9).contains($0) },
                        "Invalid saved memory sequence")
            if phase == .visible {
                guard let deadline else { throw DomainError.invalidConfiguration("Missing reveal deadline") }
                try validateDate(deadline)
                try require(deadline >= session.scheduledWakeUpDate &&
                            deadline <= updatedAt.addingTimeInterval(configuration.displayDuration),
                            "Invalid reveal deadline")
            } else {
                try require(deadline == nil, "Reveal deadline outside visible phase")
            }
        default: throw DomainError.invalidConfiguration("Checkpoint/configuration mismatch")
        }
    }
}

public struct PersistedSession: Codable, Equatable, Sendable {
    public let session: WakeUpSession
    public let updatedAt: Date
    public let checkpoint: ResumeCheckpoint?

    public init(session: WakeUpSession, updatedAt: Date, checkpoint: ResumeCheckpoint? = nil) throws {
        self.session = session
        self.updatedAt = updatedAt
        self.checkpoint = checkpoint
        try validate()
    }

    func validate() throws {
        try validateDate(updatedAt)
        let latest = session.completedAt ?? session.challengeCompletedAt.last ?? session.createdAt
        try require(updatedAt >= latest, "Persisted timestamp precedes session progress")
        if session.phase == .active { try require(updatedAt >= session.scheduledWakeUpDate, "Update precedes activation") }
        if let checkpoint { try checkpoint.validate(for: session, updatedAt: updatedAt) }
    }

    private enum CodingKeys: String, CodingKey { case session, updatedAt, checkpoint }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(session: c.decode(WakeUpSession.self, forKey: .session),
                      updatedAt: c.decode(Date.self, forKey: .updatedAt),
                      checkpoint: c.decodeIfPresent(ResumeCheckpoint.self, forKey: .checkpoint))
    }
}
