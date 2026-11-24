import Foundation

public enum MathChallengeEngine {
    public static func makeProblem(
        difficulty: Difficulty, makeID: () -> UUID,
        randomInteger: (ClosedRange<Int>) -> Int
    ) throws -> ResumeCheckpoint.Detail {
        func draw(_ range: ClosedRange<Int>) throws -> Int {
            let value = randomInteger(range)
            try require(range.contains(value), "Random math value outside requested range")
            return value
        }

        let prompt: String
        let answer: Int
        switch difficulty {
        case .easy:
            let operation = try draw(0...1)
            let first = try draw(1...99)
            let second = try draw(1...99)
            prompt = "\(first) \(operation == 0 ? "+" : "−") \(second)"
            answer = operation == 0 ? first + second : first - second
        case .medium:
            let operation = try draw(0...2)
            let range = operation == 2 ? 2...12 : 10...99
            let first = try draw(range)
            let second = try draw(range)
            let symbol = operation == 0 ? "+" : operation == 1 ? "−" : "×"
            prompt = "\(first) \(symbol) \(second)"
            answer = operation == 0 ? first + second : operation == 1 ? first - second : first * second
        case .hard:
            let operation = try draw(0...1)
            let first = try draw(2...12)
            let second = try draw(2...12)
            let third = try draw(10...99)
            prompt = "(\(first) × \(second)) \(operation == 0 ? "+" : "−") \(third)"
            answer = operation == 0 ? first * second + third : first * second - third
        }
        return .math(problemID: makeID(), prompt: prompt, expectedAnswer: answer)
    }

    public static func accepts(_ answer: String, expectedAnswer: Int) -> Bool {
        let text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.utf8.count <= 64 else { return false }
        let bytes = Array(text.utf8)
        let digits = (bytes.first == 45 || bytes.first == 43) ? bytes.dropFirst() : bytes[...]
        guard !digits.isEmpty, digits.allSatisfy({ (48...57).contains($0) }) else { return false }
        return Int(text) == expectedAnswer
    }
}
