import Foundation

public struct ChallengeCommand: Equatable, Sendable {
    public enum Action: Equatable, Sendable {
        case prepare
        case submitMath(problemID: UUID, answer: String)
        case submitMemory(roundID: UUID, answer: String)
        case advanceTime
        case interruptMemory
        case scanQR(payload: String)
    }
    public let sessionID: UUID
    public let challengeIndex: Int
    public let action: Action

    public init(sessionID: UUID, challengeIndex: Int, action: Action) {
        self.sessionID = sessionID; self.challengeIndex = challengeIndex; self.action = action
    }
}

public struct ChallengeSnapshot: Equatable, Sendable {
    public enum Content: Equatable, Sendable {
        case waiting
        case math(problemID: UUID, prompt: String, correctAnswers: Int, requiredCorrect: Int)
        case memory(roundID: UUID, visibleDigits: [Int]?, phase: ResumeCheckpoint.MemoryPhase,
                    visibleUntil: Date?, successfulRounds: Int, requiredRounds: Int)
        case qr
        case finished
    }
    public let sessionID: UUID
    public let challengeIndex: Int
    public let challengeCount: Int
    public let phase: SessionPhase
    public let content: Content

    public init(sessionID: UUID, challengeIndex: Int, challengeCount: Int,
                phase: SessionPhase, content: Content) {
        self.sessionID = sessionID; self.challengeIndex = challengeIndex
        self.challengeCount = challengeCount; self.phase = phase; self.content = content
    }
}

// A pure transition: callers commit the entire returned PersistedSession before
// publishing its snapshot. No answer, scanner, or view can directly mark success.
public struct ChallengeCoordinator: Sendable {
    public init() {}

    public func apply(
        _ command: ChallengeCommand, to record: PersistedSession, at now: Date,
        makeID: () -> UUID = { UUID() },
        randomInteger: (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) throws -> PersistedSession {
        try record.validate()
        try validateDate(now)
        try require(now >= record.updatedAt, "Challenge timestamp regressed")
        guard command.sessionID == record.session.id else { throw DomainError.unknownAlarm }
        guard command.challengeIndex >= 0, command.challengeIndex <= record.session.currentChallengeIndex
        else { throw DomainError.outOfOrder }
        // Includes a duplicate final submission after the sequence reached completing.
        if command.challengeIndex < record.session.currentChallengeIndex { return record }
        guard record.session.phase == .active, let configuration = record.session.currentChallenge
        else { throw DomainError.invalidTransition }

        var session = record.session
        var checkpoint = record.checkpoint
        var succeeded = false

        func nextMath(_ config: MathConfiguration, replacing prior: UUID? = nil) throws -> ResumeCheckpoint {
            let detail = try MathChallengeEngine.makeProblem(difficulty: config.difficulty,
                makeID: makeID, randomInteger: randomInteger)
            guard case let .math(id, _, _) = detail, id != prior else { throw DomainError.invalidTransition }
            return ResumeCheckpoint(challengeIndex: command.challengeIndex, detail: detail)
        }
        func nextMemory(_ config: MemoryConfiguration, replacing prior: UUID? = nil,
                        digits: [Int]? = nil) throws -> ResumeCheckpoint {
            let detail = try MemoryChallengeEngine.makeRound(configuration: config, at: now,
                previousDigits: digits, makeID: makeID, randomInteger: randomInteger)
            guard case let .memory(id, _, phase, deadline) = detail,
                  id != prior, phase == .visible, deadline == now.addingTimeInterval(config.displayDuration)
            else { throw DomainError.invalidTransition }
            return ResumeCheckpoint(challengeIndex: command.challengeIndex, detail: detail)
        }

        switch (command.action, configuration) {
        case let (.prepare, .math(config)):
            if checkpoint == nil { checkpoint = try nextMath(config) }
        case let (.prepare, .memory(config)):
            if checkpoint == nil { checkpoint = try nextMemory(config) }
            else { checkpoint = hiddenIfNeeded(checkpoint, at: now) }
        case (.prepare, .qr):
            try session.recordProgress(.qrWaiting)
        case let (.submitMath(id, answer), .math(config)):
            guard case let .math(currentID, _, expected)? = checkpoint?.detail, currentID == id
            else { return record }
            guard MathChallengeEngine.accepts(answer, expectedAnswer: expected) else { return record }
            let count = session.progress.count + 1
            if count == config.requiredCorrect { succeeded = true }
            else {
                try session.recordProgress(.math(correctAnswers: count))
                checkpoint = try nextMath(config, replacing: id)
            }
        case let (.submitMemory(id, answer), .memory(config)):
            guard case let .memory(currentID, digits, phase, deadline)? = checkpoint?.detail,
                  currentID == id else { return record }
            // An expired reveal can accept recall without depending on a timer firing.
            guard phase == .hidden || (phase == .visible && deadline.map { now >= $0 } == true)
            else { return record }
            if MemoryChallengeEngine.accepts(answer, digits: digits) {
                let count = session.progress.count + 1
                if count == config.requiredRounds { succeeded = true }
                else {
                    try session.recordProgress(.memory(successfulRounds: count))
                    checkpoint = try nextMemory(config, replacing: id, digits: digits)
                }
            } else { checkpoint = try nextMemory(config, replacing: id, digits: digits) }
        case (.advanceTime, .memory):
            checkpoint = hiddenIfNeeded(checkpoint, at: now)
        case (.interruptMemory, .memory):
            if case let .memory(id, digits, _, _)? = checkpoint?.detail {
                checkpoint = ResumeCheckpoint(challengeIndex: command.challengeIndex,
                    detail: .memory(roundID: id, digits: digits, phase: .hidden, visibleUntil: nil))
            }
        case let (.scanQR(payload), .qr(config)):
            succeeded = QRChallengeEngine.accepts(payload, configuration: config)
        default: throw DomainError.invalidTransition
        }
        if succeeded {
            try session.recordChallengeSuccess(expectedIndex: command.challengeIndex, at: now)
            checkpoint = nil
        }
        guard session != record.session || checkpoint != record.checkpoint else { return record }
        return try PersistedSession(session: session, updatedAt: now, checkpoint: checkpoint)
    }

    public func snapshot(of record: PersistedSession, at now: Date) throws -> ChallengeSnapshot {
        try record.validate()
        try validateDate(now)
        try require(now >= record.updatedAt, "Challenge timestamp regressed")
        let session = record.session
        let content: ChallengeSnapshot.Content
        switch (session.currentChallenge, record.checkpoint?.detail) {
        case let (.math(config), .math(id, prompt, _)):
            content = .math(problemID: id, prompt: prompt, correctAnswers: session.progress.count,
                            requiredCorrect: config.requiredCorrect)
        case let (.memory(config), .memory(id, digits, phase, deadline)):
            let visible = phase == .visible && deadline.map { now < $0 } == true
            content = .memory(roundID: id, visibleDigits: visible ? digits : nil,
                phase: visible ? .visible : .hidden, visibleUntil: visible ? deadline : nil,
                successfulRounds: session.progress.count, requiredRounds: config.requiredRounds)
        case (.qr, _): content = .qr
        case (nil, _): content = .finished
        default: content = .waiting
        }
        return ChallengeSnapshot(sessionID: session.id, challengeIndex: session.currentChallengeIndex,
            challengeCount: session.definitionSnapshot.challengeSequence.items.count,
            phase: session.phase, content: content)
    }

    private func hiddenIfNeeded(_ checkpoint: ResumeCheckpoint?, at now: Date) -> ResumeCheckpoint? {
        guard let checkpoint, case let .memory(id, digits, phase, deadline) = checkpoint.detail
        else { return checkpoint }
        if phase == .hidden || (phase == .visible && deadline.map { now < $0 } == true) { return checkpoint }
        return ResumeCheckpoint(challengeIndex: checkpoint.challengeIndex,
            detail: .memory(roundID: id, digits: digits, phase: .hidden, visibleUntil: nil))
    }
}
