import SwiftUI
import PuzzleAlarmCore

struct ChallengeConfigurationEditor: View {
    @State var configuration: ChallengeConfiguration
    let onChange: (ChallengeConfiguration) -> Void
    @State private var error: String?
    var body: some View {
        Form {
            if let error { Text(error) }
            switch configuration {
            case let .math(value):
                Picker("Difficulty", selection: Binding(get: { value.difficulty }, set: { difficulty in
                    update { .math(try MathConfiguration(difficulty: difficulty, requiredCorrect: value.requiredCorrect)) }
                })) { difficulties }.accessibilityIdentifier("math.difficulty")
                Stepper("Correct answers: \(value.requiredCorrect)", value: Binding(get: { value.requiredCorrect }, set: { count in
                    update { .math(try MathConfiguration(difficulty: value.difficulty, requiredCorrect: count)) }
                }), in: 1...20).accessibilityIdentifier("math.count")
            case let .memory(value):
                Picker("Difficulty", selection: Binding(get: { value.difficulty }, set: { difficulty in
                    update { .memory(try MemoryConfiguration(difficulty: difficulty,
                        displayDuration: value.displayDuration, requiredRounds: value.requiredRounds)) }
                })) { difficulties }.accessibilityIdentifier("memory.difficulty")
                Stepper("Sequence length: \(value.sequenceLength)", value: Binding(get: { value.sequenceLength }, set: { count in
                    update { .memory(try MemoryConfiguration(difficulty: value.difficulty, sequenceLength: count,
                        displayDuration: value.displayDuration, requiredRounds: value.requiredRounds)) }
                }), in: 2...12).accessibilityIdentifier("memory.length")
                Stepper("Display seconds: \(Int(value.displayDuration))", value: Binding(get: { Int(value.displayDuration) }, set: { count in
                    update { .memory(try MemoryConfiguration(difficulty: value.difficulty, sequenceLength: value.sequenceLength,
                        displayDuration: Double(count), requiredRounds: value.requiredRounds)) }
                }), in: 1...30).accessibilityIdentifier("memory.duration")
                Stepper("Successful rounds: \(value.requiredRounds)", value: Binding(get: { value.requiredRounds }, set: { count in
                    update { .memory(try MemoryConfiguration(difficulty: value.difficulty, sequenceLength: value.sequenceLength,
                        displayDuration: value.displayDuration, requiredRounds: count)) }
                }), in: 1...20).accessibilityIdentifier("memory.rounds")
            case .qr: Text("QR Code")
            }
        }.navigationTitle(AlarmPresentation.challenge(configuration.kind))
    }
    private var difficulties: some View {
        ForEach(Difficulty.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
    }
    private func update(_ action: () throws -> ChallengeConfiguration) {
        do { let value = try action(); configuration = value; onChange(value); error = nil }
        catch { self.error = AlarmPresentation.error(error) }
    }
}
