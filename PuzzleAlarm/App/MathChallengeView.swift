import SwiftUI
import PuzzleAlarmCore

struct MathChallengeView: View {
    @Bindable var store: AlarmStore
    let sessionID: UUID
    @State private var answer = ""
    @State private var feedback = ""

    private var engine: MathEngine? {
        guard let record = store.session(sessionID) else { return nil }
        return try? MathEngine(restoring: record)
    }
    var body: some View {
        Form {
            if let engine, let identity = engine.coordinator.currentIdentity,
               case let .math(configuration) = engine.coordinator.currentChallenge {
                Section("Math") {
                    Text("\(engine.correctAnswers) of \(configuration.requiredCorrect) correct")
                        .accessibilityIdentifier("math.progress")
                    if let problem = engine.problem {
                        Text(problem.prompt).font(.title).accessibilityIdentifier("math.prompt")
                        TextField("Numeric answer", text: $answer)
                            .keyboardType(.numbersAndPunctuation)
                            .accessibilityIdentifier("math.answer")
                        Button("Submit") {
                            let submitted = answer
                            Task {
                                let outcome = await store.submitMath(submitted, problemID: problem.id, identity: identity)
                                switch outcome {
                                case .invalid: feedback = "Enter a whole number."
                                case .wrong: feedback = "Try again."
                                case .correct, .completed: answer = ""; feedback = "Correct."
                                case .stale: answer = ""; feedback = "This problem has already changed."
                                case nil: feedback = "Answer was not saved. Try again."
                                }
                            }
                        }.accessibilityIdentifier("math.submit").disabled(store.isBusy)
                    } else {
                        Button("Start Math") { Task { await store.prepareMath(identity) } }
                            .accessibilityIdentifier("math.start").disabled(store.isBusy)
                    }
                }
            } else if let record = store.session(sessionID) {
                if record.session.phase == .completed {
                    Text("Wake-up complete").accessibilityIdentifier("math.completed")
                } else if record.session.currentChallengeIndex > 0 {
                    Text("Math complete").accessibilityIdentifier("math.completed")
                    Text(record.session.phase == .active ? "Continue with the next challenge when available." :
                         "Alarm cleanup is pending.")
                } else { Text("This challenge is not active.") }
            } else { Text("Session unavailable.") }
            if !feedback.isEmpty { Text(feedback).accessibilityIdentifier("math.feedback") }
            if let error = store.errorMessage {
                Text(error).accessibilityIdentifier("math.error")
                Button("Refresh") { Task { await store.refresh() } }
            }
        }
        .navigationTitle("Math Challenge")
    }
}
