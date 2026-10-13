import Foundation

public enum QRSubmission: Equatable, Sendable { case wrong, stale, completed }

/// Matches bytes, not URL equivalence: no trimming, case folding or decoding.
public struct QREngine: Equatable, Sendable {
    public private(set) var coordinator: ChallengeCoordinator
    public var record: PersistedSession { coordinator.record }
    public init(restoring record: PersistedSession) throws {
        coordinator = try ChallengeCoordinator(restoring: record)
    }
    public mutating func submit(_ payload: String, for identity: ChallengeIdentity,
                                at date: Date) throws -> QRSubmission {
        let items = record.session.definitionSnapshot.challengeSequence.items
        guard identity.sessionID == record.session.id, items.indices.contains(identity.index),
              identity.kind == .qr, case let .qr(configuration) = items[identity.index],
              identity.index <= record.session.currentChallengeIndex else { throw DomainError.outOfOrder }
        guard identity.index == record.session.currentChallengeIndex else { return .stale }
        guard coordinator.currentIdentity == identity else { throw DomainError.outOfOrder }
        guard payload.utf8.elementsEqual(configuration.expectedPayload.utf8) else { return .wrong }
        try coordinator.recordSuccess(for: identity, at: date)
        return .completed
    }
}
