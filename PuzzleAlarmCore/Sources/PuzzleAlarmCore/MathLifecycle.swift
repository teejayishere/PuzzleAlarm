import Foundation

extension AlarmLifecycleCoordinator {
    /// Uses the same serialization and bounded CAS replay as lifecycle commands.
    /// No scheduling/cancellation effect occurs until durable sequence success.
    public func prepareMath(for identity: ChallengeIdentity, problem: MathProblem) async throws -> LifecycleReport {
        try enter(); defer { busy = false }
        let now = clock()
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID })
            else { throw DomainError.outOfOrder }
            var engine = try MathEngine(restoring: state.sessions[index])
            try engine.prepare(problem, for: identity, at: now)
            state.sessions[index] = engine.record
        }
        return LifecycleReport(wasMissing: false, state: state, issues: [])
    }

    public func submitMath(_ text: String, problemID: UUID, for identity: ChallengeIdentity,
                           next: MathProblem?) async throws -> (LifecycleReport, MathSubmission) {
        try enter(); defer { busy = false }
        let now = clock()
        var outcome = MathSubmission.stale
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID })
            else { throw DomainError.outOfOrder }
            // A delayed duplicate after the final answer cannot advance the next kind.
            let record = state.sessions[index]
            let items = record.session.definitionSnapshot.challengeSequence.items
            guard items.indices.contains(identity.index), items[identity.index].kind == identity.kind,
                  identity.kind == .math, identity.index <= record.session.currentChallengeIndex else {
                throw DomainError.outOfOrder
            }
            guard identity.index == record.session.currentChallengeIndex else {
                outcome = .stale; return
            }
            var engine = try MathEngine(restoring: record)
            outcome = try engine.submit(text, problemID: problemID, for: identity, next: next, at: now)
            state.sessions[index] = engine.record
        }
        return (LifecycleReport(wasMissing: false, state: state, issues: []), outcome)
    }
}
