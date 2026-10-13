import Foundation
import Testing
@testable import PuzzleAlarmCore

private struct MemoryRandom: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed }
}
private func memoryEngine(count: Int = 2, followedByMath: Bool = false) throws -> MemoryEngine {
    var items: [ChallengeConfiguration] = [.memory(try MemoryConfiguration(sequenceLength: 4, requiredRounds: count))]
    if followedByMath { items.append(.math(try MathConfiguration())) }
    let session = try activeSession(sequence: items)
    return try MemoryEngine(restoring: PersistedSession(session: session, updatedAt: session.scheduledWakeUpDate))
}
private func memoryRound(_ id: UInt8 = 90, digits: [Int] = [0, 1, 2, 3]) throws -> MemoryRound {
    try MemoryRound(id: uuid(id), digits: digits)
}

@Test(arguments: Difficulty.allCases)
func MemoryEngineDeterministicGeneration(_ difficulty: Difficulty) throws {
    let configuration = try MemoryConfiguration(difficulty: difficulty)
    var random = MemoryRandom(seed: 42), replay = MemoryRandom(seed: 42)
    var seen: Set<Int> = []
    for _ in 0..<100 {
        let round = try MemoryRound.generate(configuration: configuration, id: uuid(90), using: &random)
        #expect(round == (try MemoryRound.generate(configuration: configuration, id: uuid(90), using: &replay)))
        #expect(round.digits.count == (difficulty == .easy ? 4 : difficulty == .medium ? 6 : 8))
        #expect(round.digits.allSatisfy { (0...9).contains($0) })
        seen.formUnion(round.digits)
    }
    #expect(seen == Set(0...9))
    #expect(throws: DomainError.self) { try MemoryRound(id: uuid(90), digits: [1]) }
    #expect(throws: DomainError.self) { try MemoryRound(id: uuid(90), digits: [0, 10]) }
}

@Test func MemoryEngineDeadlineHidingRestoreAndNoLeakage() throws {
    var engine = try memoryEngine()
    let identity = try #require(engine.coordinator.currentIdentity), date = engine.record.updatedAt
    #expect(engine.visibleDigits(at: date) == nil)
    try engine.prepare(memoryRound(), for: identity, at: date)
    #expect(engine.visibleDigits(at: date) == "0123")
    #expect(engine.visibleDigits(at: date.addingTimeInterval(2.999)) == "0123")
    #expect(engine.visibleDigits(at: date.addingTimeInterval(3)) == nil)
    #expect(engine.visibleDigits(at: date.addingTimeInterval(-1)) == nil)
    #expect(try engine.submit("0123", roundID: uuid(90), for: identity, next: nil, at: date) == .notHidden)
    let before = engine
    try engine.prepare(memoryRound(91), for: identity, at: date.addingTimeInterval(1))
    #expect(engine == before)
    engine = try MemoryEngine(restoring: roundTrip(engine.record))
    // Entry/foreground calls hide before rendering, even before the original deadline.
    try engine.hide(for: identity, at: date.addingTimeInterval(1))
    #expect(engine.phase == .hidden && engine.deadline == nil)
    #expect(engine.visibleDigits(at: date.addingTimeInterval(1)) == nil)
    engine = try MemoryEngine(restoring: roundTrip(engine.record))
    let hidden = engine
    try engine.hide(for: identity, at: date.addingTimeInterval(2))
    try engine.prepare(memoryRound(92), for: identity, at: date.addingTimeInterval(2))
    #expect(engine == hidden)
    #expect(engine.visibleDigits(at: date.addingTimeInterval(-100)) == nil)
}

@Test func MemoryEngineWrongInvalidAndFreshRoundAtomically() throws {
    var engine = try memoryEngine()
    let identity = try #require(engine.coordinator.currentIdentity), date = engine.record.updatedAt
    try engine.prepare(memoryRound(), for: identity, at: date)
    let hiddenAt = date.addingTimeInterval(3), before = engine
    for input in ["", "123", "01234", "0 23", "０１２３", "-123", "1.23"] {
        #expect(try engine.submit(input, roundID: uuid(90), for: identity, next: nil, at: hiddenAt) == .invalid)
        #expect(engine == before)
    }
    #expect(throws: DomainError.self) {
        try engine.submit("9999", roundID: uuid(90), for: identity, next: memoryRound(91), at: hiddenAt)
    }
    #expect(engine == before)
    #expect(throws: DomainError.self) {
        try engine.submit("0123", roundID: uuid(90), for: identity,
                          next: memoryRound(91, digits: [1, 2]), at: hiddenAt)
    }
    #expect(engine == before)
    let next = try memoryRound(91, digits: [4, 5, 6, 7])
    #expect(try engine.submit("9999", roundID: uuid(90), for: identity, next: next, at: hiddenAt) == .wrong)
    #expect(engine.successfulRounds == 0 && engine.round == next)
    #expect(engine.visibleDigits(at: hiddenAt) == "4567")
    #expect(engine.deadline == hiddenAt.addingTimeInterval(3))
    let after = engine
    #expect(try engine.submit("0123", roundID: uuid(90), for: identity, next: nil, at: hiddenAt) == .stale)
    #expect(engine == after)
}

@Test(arguments: [1, 2, 20])
func MemoryEngineThresholdAndOrderedContinuation(_ count: Int) throws {
    var engine = try memoryEngine(count: count, followedByMath: true)
    let identity = try #require(engine.coordinator.currentIdentity)
    var date = engine.record.updatedAt
    try engine.prepare(memoryRound(), for: identity, at: date)
    for index in 0..<count {
        engine = try MemoryEngine(restoring: roundTrip(engine.record))
        let round = try #require(engine.round)
        date = date.addingTimeInterval(3)
        let digits = round.digits.map(String.init).joined()
        let next = try memoryRound(UInt8(91 + index), digits: index % 2 == 0 ? [4, 5, 6, 7] : [0, 1, 2, 3])
        let result = try engine.submit(" \(digits)\n", roundID: round.id, for: identity, next: next, at: date)
        #expect(result == (index == count - 1 ? .completed : .correct))
        if index < count - 1 { #expect(engine.successfulRounds == index + 1) }
    }
    #expect(engine.record.checkpoint == nil)
    #expect(engine.coordinator.currentChallenge?.kind == .math && engine.record.session.phase == .active)
    #expect(!engine.coordinator.sequenceSucceeded)
    #expect(throws: DomainError.outOfOrder) { try MemoryEngine(restoring: engine.record) }
}

@Test func MemoryEngineRejectsForeignIdentityLengthAndTime() throws {
    var engine = try memoryEngine()
    let identity = try #require(engine.coordinator.currentIdentity), date = engine.record.updatedAt
    let foreign = ChallengeIdentity(sessionID: uuid(220), index: 0, kind: .memory)
    #expect(throws: DomainError.outOfOrder) { try engine.prepare(memoryRound(), for: foreign, at: date) }
    #expect(throws: DomainError.outOfOrder) { try engine.hide(for: foreign, at: date) }
    #expect(throws: DomainError.outOfOrder) { try engine.submit("0123", roundID: uuid(90), for: foreign, next: nil, at: date) }
    #expect(throws: DomainError.self) { try engine.prepare(memoryRound(digits: [1, 2]), for: identity, at: date) }
    try engine.prepare(memoryRound(), for: identity, at: date)
    let before = engine
    #expect(throws: DomainError.self) { try engine.submit("0123", roundID: uuid(90), for: identity, next: nil, at: date.addingTimeInterval(-1)) }
    #expect(throws: DomainError.self) { try engine.hide(for: identity, at: date.addingTimeInterval(-1)) }
    #expect(engine == before)
}

@Test func MemoryEngineOwnerClockRollbackStaleTimerAndForeignSession() async throws {
    let engine = try memoryEngine()
    let identity = try #require(engine.coordinator.currentIdentity), date = engine.record.updatedAt
    let repository = FaultRepository(), clock = TestClock(date)
    _ = try await repository.commit(RepositoryState(sessions: [engine.record]), expecting: .missing)
    let owner = AlarmLifecycleCoordinator(repository: repository, scheduler: FakeAlarmScheduler(), clock: { clock.now() })
    _ = try await owner.prepareMemory(for: identity, round: memoryRound())
    clock.set(date.addingTimeInterval(-10))
    let hidden = try await owner.hideMemory(for: identity)
    #expect(try MemoryEngine(restoring: #require(hidden.state.sessions.first)).phase == .hidden)
    clock.set(date)
    let result = try await owner.submitMemory("9999", roundID: uuid(90), for: identity,
                                            next: memoryRound(91, digits: [4, 5, 6, 7]))
    #expect(result.1 == .wrong)
    let stale = try await owner.hideMemory(for: identity, roundID: uuid(90))
    #expect(stale.state == result.0.state)
    let foreign = ChallengeIdentity(sessionID: uuid(230), index: 0, kind: .memory)
    await #expect(throws: DomainError.outOfOrder) { try await owner.prepareMemory(for: foreign, round: memoryRound()) }
    await #expect(throws: DomainError.outOfOrder) { try await owner.hideMemory(for: foreign) }
    await #expect(throws: DomainError.outOfOrder) { try await owner.submitMemory("0123", roundID: uuid(90), for: foreign, next: nil) }
}

@Test func MemoryEngineOwnerFailureConflictDuplicateAndCleanupBoundary() async throws {
    var engine = try memoryEngine(count: 1)
    let identity = try #require(engine.coordinator.currentIdentity), date = engine.record.updatedAt
    let repository = FaultRepository()
    _ = try await repository.commit(RepositoryState(sessions: [engine.record]), expecting: .missing)
    let effects = FakeAlarmScheduler()
    let owner = AlarmLifecycleCoordinator(repository: repository, scheduler: effects, clock: { date })
    _ = try await owner.prepareMemory(for: identity, round: memoryRound())
    await repository.rejectOnce { state in
        guard case .memory(_, _, .hidden, _) = state.sessions.first?.checkpoint?.detail else { return false }
        return true
    }
    await #expect(throws: PersistenceError.self) { try await owner.hideMemory(for: identity) }
    let saved = try #require(try await repositoryState(repository).sessions.first)
    #expect(try MemoryEngine(restoring: saved).phase == .visible)
    _ = try await owner.hideMemory(for: identity)
    engine = try MemoryEngine(restoring: #require(try await repositoryState(repository).sessions.first))
    _ = try engine.submit("0123", roundID: uuid(90), for: identity, next: nil, at: date)
    let concurrent = engine.record
    await repository.interfereOnce { storage in
        let read = try await storage.load()
        guard case let .loaded(snapshot, _) = read else { return }
        var state = snapshot.state; state.sessions[0] = concurrent
        _ = try await storage.commit(state, expecting: read.version)
    }
    #expect(try await owner.submitMemory("0123", roundID: uuid(90), for: identity, next: nil).1 == .stale)
    #expect(try await repositoryState(repository).sessions.first == concurrent)
    #expect(concurrent.session.phase == .completing && concurrent.session.remainingCancellationIDs.count == 5)
    #expect(effects.values.calls.isEmpty)
    let bad = ChallengeIdentity(sessionID: identity.sessionID, index: 0, kind: .qr)
    await #expect(throws: DomainError.outOfOrder) { try await owner.submitMemory("0123", roundID: uuid(90), for: bad, next: nil) }
}
