import Foundation

public enum Difficulty: String, Codable, CaseIterable, Sendable { case easy, medium, hard }
public enum ChallengeKind: String, Codable, CaseIterable, Sendable { case math, memory, qr }

public struct MathConfiguration: Codable, Equatable, Sendable {
    public let difficulty: Difficulty
    public let requiredCorrect: Int

    public init(difficulty: Difficulty = .medium, requiredCorrect: Int = 5) throws {
        try require((1...20).contains(requiredCorrect), "Math count must be 1...20")
        self.difficulty = difficulty
        self.requiredCorrect = requiredCorrect
    }

    private enum CodingKeys: String, CodingKey { case difficulty, requiredCorrect }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(difficulty: c.decode(Difficulty.self, forKey: .difficulty),
                      requiredCorrect: c.decode(Int.self, forKey: .requiredCorrect))
    }
}

public struct MemoryConfiguration: Codable, Equatable, Sendable {
    public let difficulty: Difficulty
    public let sequenceLength: Int
    public let displayDuration: TimeInterval
    public let requiredRounds: Int

    public init(
        difficulty: Difficulty = .medium, sequenceLength: Int? = nil,
        displayDuration: TimeInterval = 3, requiredRounds: Int = 1
    ) throws {
        let length = sequenceLength ?? (difficulty == .easy ? 4 : difficulty == .medium ? 6 : 8)
        try require((2...12).contains(length), "Memory length must be 2...12")
        try require(displayDuration.isFinite && (1...30).contains(displayDuration), "Invalid display duration")
        try require((1...20).contains(requiredRounds), "Memory rounds must be 1...20")
        self.difficulty = difficulty
        self.sequenceLength = length
        self.displayDuration = displayDuration
        self.requiredRounds = requiredRounds
    }

    private enum CodingKeys: String, CodingKey { case difficulty, sequenceLength, displayDuration, requiredRounds }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            difficulty: c.decode(Difficulty.self, forKey: .difficulty),
            sequenceLength: c.decode(Int.self, forKey: .sequenceLength),
            displayDuration: c.decode(TimeInterval.self, forKey: .displayDuration),
            requiredRounds: c.decode(Int.self, forKey: .requiredRounds)
        )
    }
}

public struct QRConfiguration: Codable, Equatable, Sendable {
    public let token: UUID
    public var expectedPayload: String { "puzzlealarm://challenge/\(token.uuidString.lowercased())" }
    public init(token: UUID) { self.token = token }
}

public enum ChallengeConfiguration: Codable, Equatable, Sendable {
    case math(MathConfiguration)
    case memory(MemoryConfiguration)
    case qr(QRConfiguration)

    public var kind: ChallengeKind {
        switch self {
        case .math: .math
        case .memory: .memory
        case .qr: .qr
        }
    }
}

public struct ChallengeSequence: Codable, Equatable, Sendable {
    public let items: [ChallengeConfiguration]

    public init(_ items: [ChallengeConfiguration]) throws {
        try require(items.count <= 3 && Set(items.map(\.kind)).count == items.count, "Duplicate/excess challenges")
        self.items = items
    }

    public func appending(_ configuration: ChallengeConfiguration) throws -> Self {
        try Self(items + [configuration])
    }

    public func removing(at index: Int) throws -> Self {
        try require(items.indices.contains(index), "Invalid challenge index")
        var replacement = items
        replacement.remove(at: index)
        return try Self(replacement)
    }

    public func replacing(at index: Int, with configuration: ChallengeConfiguration) throws -> Self {
        try require(items.indices.contains(index), "Invalid challenge index")
        var replacement = items
        replacement[index] = configuration
        return try Self(replacement)
    }

    public func moving(from source: Int, to destination: Int) throws -> Self {
        try require(items.indices.contains(source) && items.indices.contains(destination), "Invalid move")
        var replacement = items
        replacement.insert(replacement.remove(at: source), at: destination)
        return try Self(replacement)
    }

    private enum CodingKeys: String, CodingKey { case items }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(c.decode([ChallengeConfiguration].self, forKey: .items))
    }
}
