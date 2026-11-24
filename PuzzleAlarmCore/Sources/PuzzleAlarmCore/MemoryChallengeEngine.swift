import Foundation

public enum MemoryChallengeEngine {
    public static func makeRound(
        configuration: MemoryConfiguration, at date: Date, previousDigits: [Int]? = nil,
        makeID: () -> UUID, randomInteger: (ClosedRange<Int>) -> Int
    ) throws -> ResumeCheckpoint.Detail {
        try validateDate(date)
        let deadline = date.addingTimeInterval(configuration.displayDuration)
        try validateDate(deadline)
        var digits: [Int] = []
        for _ in 0..<configuration.sequenceLength {
            let value = randomInteger(0...9)
            try require((0...9).contains(value), "Random memory digit outside requested range")
            digits.append(value)
        }
        // A wrong answer must produce a fresh sequence even with repeated RNG output.
        if digits == previousDigits, let last = digits.indices.last {
            digits[last] = (digits[last] + 1) % 10
        }
        return .memory(roundID: makeID(), digits: digits, phase: .visible, visibleUntil: deadline)
    }

    public static func accepts(_ answer: String, digits: [Int]) -> Bool {
        guard (2...12).contains(digits.count), digits.allSatisfy({ (0...9).contains($0) }) else {
            return false
        }
        let bytes = Array(answer.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        guard bytes.count == digits.count else { return false }
        return zip(bytes, digits).allSatisfy { byte, digit in byte == UInt8(48 + digit) }
    }
}
