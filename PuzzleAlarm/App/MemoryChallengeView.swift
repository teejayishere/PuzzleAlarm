import SwiftUI
import PuzzleAlarmCore

struct MemoryChallengeView: View {
    @Bindable var store: AlarmStore
    let sessionID: UUID
    @Environment(\.scenePhase) private var scenePhase
    @State private var answer = ""
    @State private var feedback = ""
    @State private var ready = false
    @State private var concealedRoundID: UUID?
    private var engine: MemoryEngine? {
        guard let record = store.session(sessionID) else { return nil }
        return try? MemoryEngine(restoring: record)
    }
    var body: some View {
        Form {
            if let engine, let identity = engine.coordinator.currentIdentity,
               case let .memory(configuration) = engine.coordinator.currentChallenge {
                Section("Memory") {
                    Text("\(engine.successfulRounds) of \(configuration.requiredRounds) rounds")
                        .accessibilityIdentifier("memory.progress")
                    if !ready || scenePhase != .active {
                        Text("Sequence hidden").accessibilityIdentifier("memory.hidden")
                        if scenePhase == .active {
                            Button("Resume safely") { Task { ready = await store.hideMemory(identity) } }
                                .disabled(store.isBusy)
                        }
                    } else if let round = engine.round {
                        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                            if concealedRoundID != round.id, let digits = engine.visibleDigits(at: store.currentDate()) {
                                Text(digits).font(.largeTitle).monospacedDigit()
                                    .accessibilityIdentifier("memory.sequence")
                            } else {
                                Text("Recall the sequence").accessibilityIdentifier("memory.hidden")
                                    .onAppear { concealedRoundID = round.id }
                                TextField("Digits in order", text: $answer).keyboardType(.numberPad)
                                    .accessibilityIdentifier("memory.answer")
                                Button("Submit") {
                                    let submitted = answer
                                    Task {
                                        let outcome = await store.submitMemory(submitted, roundID: round.id, identity: identity)
                                        switch outcome {
                                        case .invalid: feedback = "Enter exactly \(configuration.sequenceLength) digits."
                                        case .notHidden: feedback = "Wait for the sequence to hide."
                                        case .stale: answer = ""; feedback = "This round has changed."
                                        case .wrong: answer = ""; feedback = "Try a new sequence."
                                        case .correct, .completed: answer = ""; feedback = "Correct."
                                        case nil: feedback = "Answer was not saved. Try again."
                                        }
                                    }
                                }.accessibilityIdentifier("memory.submit").disabled(store.isBusy)
                            }
                        }
                        .task(id: engine.deadline) {
                            guard let deadline = engine.deadline else { return }
                            let delay = max(0, deadline.timeIntervalSince(store.currentDate()))
                            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
                            _ = await store.hideMemory(identity, roundID: round.id)
                        }
                    } else {
                        Button("Start Memory") { Task { await store.prepareMemory(identity) } }
                            .accessibilityIdentifier("memory.start").disabled(store.isBusy)
                    }
                }
            } else if let record = store.session(sessionID) {
                Text(record.session.phase == .completed ? "Wake-up complete" : "Memory complete")
                    .accessibilityIdentifier("memory.completed")
                if record.session.phase == .active {
                    Text("Continue with the next challenge from the alarm list.")
                } else if record.session.phase != .completed { Text("Alarm cleanup is pending.") }
            } else { Text("Session unavailable.") }
            if !feedback.isEmpty { Text(feedback).accessibilityIdentifier("memory.feedback") }
            if let error = store.errorMessage { Text(error).accessibilityIdentifier("memory.error") }
        }
        .navigationTitle("Memory Challenge")
        .task {
            if let identity = engine?.coordinator.currentIdentity { ready = await store.hideMemory(identity) }
        }
        .onChange(of: scenePhase) { _, phase in
            ready = false; answer = ""
            if let identity = engine?.coordinator.currentIdentity {
                Task { let saved = await store.hideMemory(identity); if phase == .active { ready = saved } }
            }
        }
        .onDisappear {
            ready = false; answer = ""
            if let identity = engine?.coordinator.currentIdentity { Task { _ = await store.hideMemory(identity) } }
        }
    }
}
