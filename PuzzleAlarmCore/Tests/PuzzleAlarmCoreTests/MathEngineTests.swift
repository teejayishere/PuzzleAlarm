import Foundation
import Testing
@testable import PuzzleAlarmCore

private struct MathRandom: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return seed
    }
}
private func mathEngine(count: Int = 2, followedByQR: Bool = false) throws -> MathEngine {
    var items: [ChallengeConfiguration] = [.math(try MathConfiguration(requiredCorrect: count))]
    if followedByQR { items.append(.qr(QRConfiguration(token: uuid(99)))) }
    let session = try activeSession(sequence: items)
    return try MathEngine(restoring: PersistedSession(session: session, updatedAt: session.scheduledWakeUpDate))
}
private func problem(_ id: UInt8 = 90, answer: Int = 5) throws -> MathProblem {
    try MathProblem(id: uuid(id), prompt: "2 + 3", expectedAnswer: answer)
}

@Test(arguments: Difficulty.allCases)
func MathEngineGenerationBoundsAndIndependentAnswers(_ difficulty: Difficulty) throws {
    var random = MathRandom(seed: 42)
    var replay = MathRandom(seed: 42)
    var symbols: Set<String> = []
    for _ in 0..<1000 {
        let generated = try MathProblem.generate(difficulty: difficulty, id: uuid(90), using: &random)
        #expect(generated == (try MathProblem.generate(difficulty: difficulty, id: uuid(90), using: &replay)))
        let tokens = generated.prompt.replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "").split(separator: " ").map(String.init)
        let a = try #require(Int(tokens[0])), b = try #require(Int(tokens[2]))
        symbols.insert(tokens[1])
        let independentlyCalculated: Int
        if difficulty == .hard {
            let c = try #require(Int(tokens[4]))
            #expect((2...12).contains(a) && (2...12).contains(b) && (1...99).contains(c))
            #expect(generated.prompt.hasPrefix("(") && tokens[1] == "×")
            independentlyCalculated = tokens[3] == "+" ? a * b + c : a * b - c
        } else {
            let bound = tokens[1] == "×" ? 12 : 99
            #expect((1...bound).contains(a) && (1...bound).contains(b))
            independentlyCalculated = tokens[1] == "+" ? a + b : tokens[1] == "−" ? a - b : a * b
        }
        #expect(generated.expectedAnswer == independentlyCalculated)
        #expect(abs(generated.expectedAnswer) <= 243)
    }
    #expect(symbols == (difficulty == .easy ? ["+", "−"] : difficulty == .medium ? ["+", "−", "×"] : ["×"]))
}

@Test func MathEngineInvalidWrongAndSignedAnswers() throws {
    var engine = try mathEngine()
    let identity = try #require(engine.coordinator.currentIdentity)
    let date = engine.record.updatedAt
    try engine.prepare(problem(answer: -5), for: identity, at: date)
    let before = engine
    for input in ["", " ", "-", "+", "1.0", "1e2", "5abc", "1 2", "１２", String(repeating: "9", count: 100)] {
        #expect(try engine.submit(input, problemID: uuid(90), for: identity, next: nil, at: date) == .invalid)
        #expect(engine == before)
    }
    #expect(try engine.submit("5", problemID: uuid(90), for: identity, next: nil, at: date) == .wrong)
    #expect(engine == before)
    #expect(try engine.submit("  -5\n", problemID: uuid(90), for: identity, next: problem(91), at: date) == .correct)
    #expect(engine.correctAnswers == 1)
    #expect(try engine.submit("+5", problemID: uuid(91), for: identity, next: nil, at: date) == .completed)
}

@Test(arguments: [1, 2, 20])
func MathEngineThresholdRestoreAndDuplicate(_ count: Int) throws {
    var engine = try mathEngine(count: count)
    let identity = try #require(engine.coordinator.currentIdentity)
    let date = engine.record.updatedAt
    try engine.prepare(problem(), for: identity, at: date)
    for index in 0..<count {
        engine = try MathEngine(restoring: roundTrip(engine.record))
        let current = try #require(engine.problem)
        #expect(engine.correctAnswers == index)
        let next = try problem(UInt8(91 + index))
        let result = try engine.submit("5", problemID: current.id, for: identity, next: next, at: date)
        if index == count - 1 {
            #expect(result == .completed)
            #expect(engine.record.session.phase == .completing && engine.record.checkpoint == nil)
            #expect(engine.record.session.remainingCancellationIDs.count == 5)
        } else {
            #expect(result == .correct)
            let after = engine
            #expect(try engine.submit("5", problemID: current.id, for: identity, next: next, at: date) == .stale)
            #expect(engine == after)
            try engine.prepare(problem(200), for: identity, at: date)
            #expect(engine == after)
        }
    }
    #expect(engine.coordinator.sequenceSucceeded)
    let before = engine
    #expect(throws: DomainError.outOfOrder) {
        try engine.submit("5", problemID: uuid(90), for: identity, next: nil, at: date)
    }
    #expect(engine == before)
}

@Test func MathEngineRejectsForeignIdentityBadNextAndRegressingTimeAtomically() throws {
    var engine = try mathEngine(followedByQR: true)
    let identity = try #require(engine.coordinator.currentIdentity)
    let date = engine.record.updatedAt
    let foreign = ChallengeIdentity(sessionID: uuid(220), index: 0, kind: .math)
    #expect(throws: DomainError.outOfOrder) { try engine.prepare(problem(), for: foreign, at: date) }
    #expect(try engine.submit("5", problemID: uuid(90), for: identity, next: nil, at: date) == .stale)
    try engine.prepare(problem(), for: identity, at: date)
    let before = engine
    #expect(throws: DomainError.self) { try engine.submit("5", problemID: uuid(90), for: identity, next: nil, at: date) }
    #expect(throws: DomainError.self) { try engine.submit("5", problemID: uuid(90), for: identity, next: problem(), at: date) }
    #expect(throws: DomainError.self) {
        try engine.submit("5", problemID: uuid(90), for: identity, next: problem(91), at: date.addingTimeInterval(-1))
    }
    #expect(engine == before)
    _ = try engine.submit("5", problemID: uuid(90), for: identity, next: problem(91), at: date)
    _ = try engine.submit("5", problemID: uuid(91), for: identity, next: nil, at: date)
    #expect(engine.coordinator.currentChallenge?.kind == .qr && engine.record.session.phase == .active)
    #expect(!engine.coordinator.sequenceSucceeded)
    #expect(throws: DomainError.self) { try MathEngine(restoring: engine.record) }
    #expect(throws: DomainError.self) { try MathProblem(id: uuid(90), prompt: " ", expectedAnswer: 0) }
}

@Test func MathEngineOwnerPersistenceFailureAndConflictReplay() async throws {
    let initial = try mathEngine()
    let identity = try #require(initial.coordinator.currentIdentity)
    let date = initial.record.updatedAt
    let repository = FaultRepository()
    let state = try RepositoryState(sessions: [initial.record])
    _ = try await repository.commit(state, expecting: .missing)
    let effects = FakeAlarmScheduler()
    let owner = AlarmLifecycleCoordinator(repository: repository, scheduler: effects, clock: { date })
    _ = try await owner.prepareMath(for: identity, problem: problem())
    let prepared = try await repositoryState(repository)
    await repository.rejectOnce { $0.sessions.first?.session.progress == .math(correctAnswers: 1) }
    await #expect(throws: PersistenceError.self) {
        try await owner.submitMath("5", problemID: uuid(90), for: identity, next: problem(91))
    }
    #expect(try await repositoryState(repository) == prepared)
    await repository.interfereOnce { storage in
        let read = try await storage.load()
        guard case let .loaded(snapshot, _) = read else { return }
        _ = try await storage.commit(snapshot.state, expecting: read.version)
    }
    let result = try await owner.submitMath("5", problemID: uuid(90), for: identity, next: problem(91))
    #expect(result.1 == .correct)
    let restored = try MathEngine(restoring: #require(result.0.state.sessions.first))
    #expect(restored.correctAnswers == 1 && restored.problem?.id == uuid(91))
    #expect(try await owner.submitMath("5", problemID: uuid(90), for: identity, next: problem(92)).1 == .stale)
    #expect(try await owner.submitMath("5", problemID: uuid(91), for: identity, next: nil).1 == .completed)
    #expect(try await owner.submitMath("5", problemID: uuid(91), for: identity, next: nil).1 == .stale)
    #expect(effects.values.calls.isEmpty)
}
