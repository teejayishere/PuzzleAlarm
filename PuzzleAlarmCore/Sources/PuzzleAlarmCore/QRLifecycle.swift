import Foundation

extension AlarmLifecycleCoordinator {
    public func submitQR(_ payload: String, for identity: ChallengeIdentity) async throws
        -> (LifecycleReport, QRSubmission) {
        try enter(); defer { busy = false }
        let now = clock()
        var outcome = QRSubmission.stale
        let state = try await update { state in
            guard let index = state.sessions.firstIndex(where: { $0.session.id == identity.sessionID })
            else { throw DomainError.outOfOrder }
            var engine = try QREngine(restoring: state.sessions[index])
            outcome = try engine.submit(payload, for: identity, at: now)
            state.sessions[index] = engine.record
        }
        return (LifecycleReport(wasMissing: false, state: state, issues: []), outcome)
    }
}
