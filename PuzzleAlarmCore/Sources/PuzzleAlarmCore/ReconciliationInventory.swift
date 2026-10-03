import Foundation

// Classification only. Input IDs must come from a SUCCESSFUL app-scoped AlarmKit
// snapshot. An unavailable/throwing snapshot is never converted to an empty set.
public struct ReconciliationInventory: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case recognizedPresent, persistedMissing, stalePresent, staleMissing, potentiallyOrphanedOwned
    }
    public struct Entry: Equatable, Sendable {
        public let id: UUID
        public let ownership: AlarmOwnership?
        public let status: Status
    }
    public let entries: [Entry]

    public init(state: RepositoryState, observedOwnedIDs: [UUID]) throws {
        try state.validate()
        try require(Set(observedOwnedIDs).count == observedOwnedIDs.count, "Duplicate observed UUID")
        let observed = Set(observedOwnedIDs)
        let ledger = try state.ownershipLedger()
        let known = Set(ledger.map(\.alarmKitID))
        let parents = Set(state.definitions.map(\.id))
        let sessions = Dictionary(uniqueKeysWithValues: state.sessions.map { ($0.session.id, $0.session) })
        var result = ledger.map { item -> Entry in
            let session = item.sessionID.flatMap { sessions[$0] }
            let stale = !parents.contains(item.parentAlarmID) ||
                (item.sessionID != nil && session == nil) ||
                item.cancellation == .succeeded ||
                session?.phase == .completed || session?.phase == .cancelled
            let present = observed.contains(item.alarmKitID)
            return Entry(id: item.alarmKitID, ownership: item,
                         status: stale ? (present ? .stalePresent : .staleMissing) :
                            (present ? .recognizedPresent : .persistedMissing))
        }
        result += observed.subtracting(known).map {
            Entry(id: $0, ownership: nil, status: .potentiallyOrphanedOwned)
        }
        entries = result.sorted { $0.id.uuidString < $1.id.uuidString }
    }
}
