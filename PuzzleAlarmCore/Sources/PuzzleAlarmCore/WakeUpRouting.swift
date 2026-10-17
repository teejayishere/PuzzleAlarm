import Foundation

/// Presentation is selected only from authoritative reconciled sessions. An intent
/// is a request to reconcile, never proof of firing or challenge success.
public enum WakeUpRouting {
    public static func sessionID(in state: RepositoryState, at now: Date) -> UUID? {
        guard now.timeIntervalSince1970.isFinite else { return nil }
        return state.sessions.map(\.session).filter {
            $0.phase == .active && $0.scheduledWakeUpDate <= now && $0.currentChallenge != nil
        }.sorted {
            if $0.scheduledWakeUpDate != $1.scheduledWakeUpDate {
                return $0.scheduledWakeUpDate < $1.scheduledWakeUpDate
            }
            return $0.id.uuidString < $1.id.uuidString
        }.first?.id
    }
}
