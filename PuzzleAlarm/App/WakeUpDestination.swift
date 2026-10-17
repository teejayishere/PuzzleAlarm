import SwiftUI
import PuzzleAlarmCore

/// Follow the saved sequence, not the view or intent that originally opened it.
struct WakeUpDestination: View {
    @Bindable var store: AlarmStore
    let sessionID: UUID

    var body: some View {
        if let record = store.session(sessionID) {
            if record.session.phase == .active {
                switch record.session.currentChallenge?.kind {
                case .math: MathChallengeView(store: store, sessionID: sessionID)
                case .memory: MemoryChallengeView(store: store, sessionID: sessionID)
                case .qr: QRChallengeView(store: store, sessionID: sessionID)
                case nil: Text("Session unavailable.")
                }
            } else {
                let kind = record.session.definitionSnapshot.challengeSequence.items.last?.kind.rawValue ?? "wake"
                VStack {
                    Text(record.session.phase == .completed ? "Wake-up complete" : "Alarm cleanup is pending.")
                        .accessibilityIdentifier(kind + ".completed")
                    if record.session.phase != .completed {
                        Button("Retry cleanup") { Task { await store.refresh() } }
                    }
                    if let error = store.errorMessage { Text(error) }
                }.navigationTitle("Wake-up")
            }
        } else { Text("Session unavailable.") }
    }
}
