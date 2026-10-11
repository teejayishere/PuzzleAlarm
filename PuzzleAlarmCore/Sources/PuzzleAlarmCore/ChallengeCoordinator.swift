import Foundation

/// Identity captured when presenting a challenge. Late callbacks cannot solve a
/// different occurrence or the next challenge. Engines verify success themselves.
public struct ChallengeIdentity: Equatable, Sendable {
    public let sessionID: UUID
    public let index: Int
    public let kind: ChallengeKind

    public init(sessionID: UUID, index: Int, kind: ChallengeKind) {
        self.sessionID = sessionID
        self.index = index
        self.kind = kind
    }
}

/// Pure session reducer. The caller persists `record` through the session layer
/// before presenting the next challenge or requesting lifecycle cleanup. A failed
/// commit must discard this candidate and restore the authoritative record.
/// No engine, navigation, storage, or external-effect implementation lives here.
public struct ChallengeCoordinator: Equatable, Sendable {
    public private(set) var record: PersistedSession

    public init(restoring record: PersistedSession) throws {
        try record.validate()
        self.record = record
    }

    public var currentChallenge: ChallengeConfiguration? {
        record.session.phase == .active ? record.session.currentChallenge : nil
    }

    public var currentIdentity: ChallengeIdentity? {
        guard let currentChallenge else { return nil }
        return ChallengeIdentity(sessionID: record.session.id,
                                 index: record.session.currentChallengeIndex,
                                 kind: currentChallenge.kind)
    }

    /// Sequence success is distinct from completed alarm cleanup.
    public var sequenceSucceeded: Bool {
        record.session.currentChallengeIndex == record.session.definitionSnapshot.challengeSequence.items.count
    }

    @discardableResult
    public mutating func recordSuccess(for identity: ChallengeIdentity, at date: Date) throws -> Bool {
        try validate(identity)
        var session = record.session
        guard try session.recordChallengeSuccess(expectedIndex: identity.index, at: date) else { return false }
        try replace(session: session, checkpoint: nil, at: date)
        return true
    }

    @discardableResult
    public mutating func recordProgress(_ progress: ChallengeProgress, for identity: ChallengeIdentity,
                                        at date: Date) throws -> Bool {
        try validateCurrent(identity)
        var session = record.session
        try session.recordProgress(progress)
        try validateDate(date)
        if session == record.session { return false }
        try replace(session: session, checkpoint: record.checkpoint, at: date)
        return true
    }

    @discardableResult
    public mutating func saveCheckpoint(_ checkpoint: ResumeCheckpoint, for identity: ChallengeIdentity,
                                        at date: Date) throws -> Bool {
        try validateCurrent(identity)
        try checkpoint.validate(for: record.session, updatedAt: date)
        try validateDate(date)
        if checkpoint == record.checkpoint { return false }
        try replace(session: record.session, checkpoint: checkpoint, at: date)
        return true
    }

    private func validate(_ identity: ChallengeIdentity) throws {
        let items = record.session.definitionSnapshot.challengeSequence.items
        guard identity.sessionID == record.session.id, items.indices.contains(identity.index),
              items[identity.index].kind == identity.kind else { throw DomainError.outOfOrder }
    }

    private func validateCurrent(_ identity: ChallengeIdentity) throws {
        try validate(identity)
        guard identity == currentIdentity else { throw DomainError.outOfOrder }
    }

    private mutating func replace(session: WakeUpSession, checkpoint: ResumeCheckpoint?, at date: Date) throws {
        try require(date >= record.updatedAt, "Coordinator timestamp regressed")
        record = try PersistedSession(session: session, updatedAt: date, checkpoint: checkpoint)
    }
}
