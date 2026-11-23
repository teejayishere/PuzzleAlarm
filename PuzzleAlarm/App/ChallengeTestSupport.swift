import Foundation

extension AlarmDraft {
    // Read actual draft fields only when explicitly requested by Simulator tests.
    var challengeTestState: String {
        #if DEBUG && targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains("--ui-challenge-audit") else { return "" }
        let values = challenges.map { item in
            switch item.kind {
            case .math: return "math:\(item.difficulty.rawValue):\(item.correctCount)"
            case .memory: return "memory:\(item.difficulty.rawValue):\(item.length):\(item.seconds):\(item.rounds)"
            case .qr: return "qr:\(item.token.uuidString)"
            }
        }
        return "; challenges=[" + values.joined(separator: ",") + "]"
        #else
        return ""
        #endif
    }
}
