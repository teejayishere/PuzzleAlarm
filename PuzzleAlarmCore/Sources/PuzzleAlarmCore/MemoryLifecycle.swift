import Foundation

extension AlarmLifecycleCoordinator {
    public func prepareMemory(for identity: ChallengeIdentity, round: MemoryRound) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let now = clock()
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID }) else { throw DomainError.outOfOrder }
            var engine = try MemoryEngine(restoring: state.sessions[index])
            try engine.prepare(round, for: identity, at: now)
            state.sessions[index] = engine.record
        }
        return LifecycleReport(wasMissing: false, state: state, issues: [])
    }
    public func hideMemory(for identity: ChallengeIdentity, roundID: UUID? = nil) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let now = clock()
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID }) else { throw DomainError.outOfOrder }
            let record = state.sessions[index]
            let items = record.session.definitionSnapshot.challengeSequence.items
            guard items.indices.contains(identity.index), items[identity.index].kind == identity.kind,
                  identity.kind == .memory, identity.index <= record.session.currentChallengeIndex else { throw DomainError.outOfOrder }
            guard identity.index == record.session.currentChallengeIndex else { return }
            var engine = try MemoryEngine(restoring: state.sessions[index])
            guard roundID == nil || engine.round?.id == roundID else { return }
            // Clock rollback must not prevent conservative hiding.
            try engine.hide(for: identity, at: max(now, engine.record.updatedAt))
            state.sessions[index] = engine.record
        }
        return LifecycleReport(wasMissing: false, state: state, issues: [])
    }
    public func submitMemory(_ text: String, roundID: UUID, for identity: ChallengeIdentity,
                             next: MemoryRound?) async throws -> (LifecycleReport, MemorySubmission) {
        try enter(); defer { busy = false }
        let now = clock()
        var outcome = MemorySubmission.stale
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID }) else { throw DomainError.outOfOrder }
            let record = state.sessions[index]
            let items = record.session.definitionSnapshot.challengeSequence.items
            guard items.indices.contains(identity.index), items[identity.index].kind == identity.kind,
                  identity.kind == .memory, identity.index <= record.session.currentChallengeIndex else { throw DomainError.outOfOrder }
            guard identity.index == record.session.currentChallengeIndex else { outcome = .stale; return }
            var engine = try MemoryEngine(restoring: record)
            outcome = try engine.submit(text, roundID: roundID, for: identity, next: next, at: now)
            state.sessions[index] = engine.record
        }
        return (LifecycleReport(wasMissing: false, state: state, issues: []), outcome)
    }
}
