import Foundation
import Testing
@testable import PuzzleAlarmCore

private let coordinatorOrders = [
    [0], [1], [2], [0, 1], [1, 0], [0, 2], [2, 0], [1, 2], [2, 1],
    [0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]
]

private func challengeRecord(_ configs: [ChallengeConfiguration]) throws -> PersistedSession {
    let session = try activeSession(sequence: configs)
    return try PersistedSession(session: session, updatedAt: session.scheduledWakeUpDate)
}

private func command(_ record: PersistedSession, _ action: ChallengeCommand.Action) -> ChallengeCommand {
    ChallengeCommand(sessionID: record.session.id,
                     challengeIndex: record.session.currentChallengeIndex, action: action)
}

@Test(arguments: coordinatorOrders)
private func coordinatorSolvesEveryPermutationOnlyInOrder(_ order: [Int]) throws {
    let configs: [ChallengeConfiguration] = [
        .math(try MathConfiguration(requiredCorrect: 1)),
        .memory(try MemoryConfiguration(requiredRounds: 1)), .qr(QRConfiguration(token: uuid(99)))
    ]
    let coordinator = ChallengeCoordinator()
    var record = try challengeRecord(order.map { configs[$0] })
    var now = record.updatedAt
    var identity: UInt8 = 100
    for index in order.indices {
        record = try coordinator.apply(command(record, .prepare), to: record, at: now,
            makeID: { identity += 1; return uuid(identity) }, randomInteger: { $0.lowerBound })
        record = try roundTrip(record)
        let answer: ChallengeCommand.Action
        switch record.checkpoint?.detail {
        case let .math(id, _, expected): answer = .submitMath(problemID: id, answer: String(expected))
        case let .memory(id, digits, _, deadline):
            now = try #require(deadline)
            answer = .submitMemory(roundID: id, answer: digits.map(String.init).joined())
        case nil:
            guard case let .qr(configuration)? = record.session.currentChallenge else {
                Issue.record("Missing prepared challenge"); return
            }
            answer = .scanQR(payload: configuration.expectedPayload)
        }
        let submission = command(record, answer)
        record = try coordinator.apply(submission, to: record, at: now)
        #expect(record.session.currentChallengeIndex == index + 1)
        #expect(record.checkpoint == nil)
        #expect(record.session.completedAt == nil)
        #expect(record.session.cancellation.allSatisfy { $0 == .notRequested })
        #expect(record.session.phase == (index == order.count - 1 ? .completing : .active))
        #expect(try coordinator.apply(submission, to: record, at: now) == record)
        record = try roundTrip(record)
    }
    #expect(try coordinator.snapshot(of: record, at: now).content == .finished)
}

@Test func coordinatorMathPersistsOneProblemAndRejectsReplayedAnswers() throws {
    let coordinator = ChallengeCoordinator()
    var record = try challengeRecord([.math(try MathConfiguration(requiredCorrect: 2))])
    let now = record.updatedAt
    record = try coordinator.apply(command(record, .prepare), to: record, at: now,
        makeID: { uuid(100) }, randomInteger: { $0.lowerBound })
    let restored = try roundTrip(record)
    #expect(try coordinator.apply(command(restored, .prepare), to: restored,
                                  at: now.addingTimeInterval(1)) == record)
    guard case let .math(id, prompt, expected)? = record.checkpoint?.detail else {
        Issue.record("Missing math problem"); return
    }
    #expect(try coordinator.snapshot(of: record, at: now).content == .math(problemID: id,
        prompt: prompt, correctAnswers: 0, requiredCorrect: 2))
    for answer in ["", " ", "malformed", String(expected == 0 ? 1 : 0)] {
        #expect(try coordinator.apply(command(record, .submitMath(problemID: id, answer: answer)),
                                      to: record, at: now) == record)
    }
    let submission = command(record, .submitMath(problemID: id, answer: String(expected)))
    record = try coordinator.apply(submission, to: record, at: now,
        makeID: { uuid(101) }, randomInteger: { $0.upperBound })
    #expect(record.session.progress == .math(correctAnswers: 1))
    #expect(record.session.phase == .active)
    #expect(record.session.currentChallengeIndex == 0)
    #expect(try coordinator.apply(submission, to: record, at: now) == record)
    guard case let .math(nextID, _, nextAnswer)? = record.checkpoint?.detail else {
        Issue.record("Missing next math problem"); return
    }
    record = try coordinator.apply(command(record, .submitMath(problemID: nextID,
        answer: String(nextAnswer))), to: record, at: now)
    #expect(record.session.phase == .completing)
    #expect(record.session.progress == .notStarted)
    #expect(record.checkpoint == nil)
}

@Test func coordinatorRejectsWrongSessionFutureIndexWrongKindAndRegressedTime() throws {
    let coordinator = ChallengeCoordinator()
    let record = try challengeRecord([.math(try MathConfiguration()), .qr(QRConfiguration(token: uuid(99)))])
    let now = record.updatedAt
    #expect(throws: DomainError.unknownAlarm) {
        try coordinator.apply(ChallengeCommand(sessionID: uuid(90), challengeIndex: 0, action: .prepare),
                              to: record, at: now)
    }
    for index in [-1, 1, 2] {
        #expect(throws: DomainError.outOfOrder) {
            try coordinator.apply(ChallengeCommand(sessionID: record.session.id,
                challengeIndex: index, action: .prepare), to: record, at: now)
        }
    }
    #expect(throws: DomainError.invalidTransition) {
        try coordinator.apply(command(record, .scanQR(payload: QRConfiguration(token: uuid(99)).expectedPayload)),
                              to: record, at: now)
    }
    #expect(throws: DomainError.self) {
        try coordinator.apply(command(record, .prepare), to: record, at: now.addingTimeInterval(-1))
    }
    let armed = try armedSession(sequence: [.qr(QRConfiguration(token: uuid(99)))])
    let inactive = try PersistedSession(session: armed, updatedAt: armed.createdAt)
    #expect(throws: DomainError.invalidTransition) {
        try coordinator.apply(command(inactive, .scanQR(payload: QRConfiguration(token: uuid(99)).expectedPayload)),
                              to: inactive, at: now)
    }
}

@Test func coordinatorMemoryDeadlineSurvivesRelaunchAndInterruptHidesWithoutRevealing() throws {
    let coordinator = ChallengeCoordinator()
    var record = try challengeRecord([.memory(try MemoryConfiguration(displayDuration: 3))])
    let now = record.updatedAt
    record = try coordinator.apply(command(record, .prepare), to: record, at: now,
        makeID: { uuid(100) }, randomInteger: { $0.lowerBound })
    guard case let .memory(id, digits, _, deadline)? = record.checkpoint?.detail else {
        Issue.record("Missing memory round"); return
    }
    let end = try #require(deadline)
    let early = command(record, .submitMemory(roundID: id, answer: digits.map(String.init).joined()))
    #expect(try coordinator.apply(early, to: record, at: now) == record)
    record = try roundTrip(record)
    #expect(try coordinator.apply(command(record, .prepare), to: record,
        at: now.addingTimeInterval(1)) == record)
    guard case let .memory(_, shown, _, visibleUntil, _, _) = try coordinator.snapshot(of: record, at: now).content,
          case let .memory(_, hidden, hiddenPhase, expiredUntil, _, _) = try coordinator.snapshot(of: record, at: end).content
    else { Issue.record("Missing memory snapshots"); return }
    #expect(shown == digits)
    #expect(visibleUntil == end)
    #expect(hidden == nil)
    #expect(hiddenPhase == .hidden)
    #expect(expiredUntil == nil)
    let interrupted = try coordinator.apply(command(record, .interruptMemory), to: record,
                                            at: now.addingTimeInterval(1))
    let resumed = try coordinator.apply(command(interrupted, .prepare), to: roundTrip(interrupted),
                                       at: now.addingTimeInterval(2))
    #expect(resumed == interrupted)
    guard case let .memory(_, interruptedDigits, phase, _, _, _) = try coordinator.snapshot(of: resumed,
        at: now.addingTimeInterval(2)).content else { Issue.record("Missing hidden snapshot"); return }
    #expect(interruptedDigits == nil)
    #expect(phase == .hidden)
    let elapsed = try coordinator.apply(command(record, .advanceTime), to: record, at: end)
    guard case let .memory(_, _, persistedPhase, persistedDeadline)? = elapsed.checkpoint?.detail else {
        Issue.record("Missing hidden checkpoint"); return
    }
    #expect(persistedPhase == .hidden)
    #expect(persistedDeadline == nil)
}

@Test func coordinatorMemoryWrongRecallStartsFreshAndCountsSuccessfulRoundsOnly() throws {
    let coordinator = ChallengeCoordinator()
    var record = try challengeRecord([.memory(try MemoryConfiguration(requiredRounds: 2))])
    var now = record.updatedAt
    var identity: UInt8 = 100
    func apply(_ action: ChallengeCommand.Action) throws {
        record = try coordinator.apply(command(record, action), to: record, at: now,
            makeID: { identity += 1; return uuid(identity) }, randomInteger: { $0.lowerBound })
    }
    try apply(.prepare)
    guard case let .memory(id, digits, _, deadline)? = record.checkpoint?.detail else {
        Issue.record("Missing first round"); return
    }
    now = try #require(deadline)
    let wrong = command(record, .submitMemory(roundID: id, answer: "wrong"))
    try apply(wrong.action)
    #expect(record.session.progress == .notStarted)
    guard case let .memory(nextID, nextDigits, _, nextDeadline)? = record.checkpoint?.detail else {
        Issue.record("Missing fresh round"); return
    }
    #expect(nextID != id)
    #expect(nextDigits != digits)
    #expect(try coordinator.apply(wrong, to: record, at: now) == record)
    now = try #require(nextDeadline)
    let success = command(record, .submitMemory(roundID: nextID, answer: nextDigits.map(String.init).joined()))
    try apply(success.action)
    #expect(record.session.progress == .memory(successfulRounds: 1))
    #expect(record.session.phase == .active)
    #expect(try coordinator.apply(success, to: record, at: now) == record)
    guard case let .memory(finalID, finalDigits, _, finalDeadline)? = record.checkpoint?.detail else {
        Issue.record("Missing final round"); return
    }
    now = try #require(finalDeadline)
    try apply(.submitMemory(roundID: finalID, answer: finalDigits.map(String.init).joined()))
    #expect(record.session.phase == .completing)
    #expect(record.checkpoint == nil)
}

@Test func coordinatorQRUsesExactMatcherAndDoesNotSkipLaterChallenges() throws {
    let coordinator = ChallengeCoordinator()
    let config = QRConfiguration(token: uuid(99))
    let record = try challengeRecord([.qr(config), .math(try MathConfiguration())])
    for payload in ["", "wrong", QRConfiguration(token: uuid(98)).expectedPayload, config.expectedPayload + " "] {
        #expect(try coordinator.apply(command(record, .scanQR(payload: payload)),
                                      to: record, at: record.updatedAt) == record)
    }
    let solved = try coordinator.apply(command(record, .scanQR(payload: config.expectedPayload)),
                                       to: record, at: record.updatedAt)
    #expect(solved.session.currentChallengeIndex == 1)
    #expect(solved.session.phase == .active)
    #expect(solved.session.completedAt == nil)
    #expect(solved.session.cancellation.allSatisfy { $0 == .notRequested })
    #expect(try coordinator.apply(command(record, .scanQR(payload: config.expectedPayload)),
                                  to: solved, at: solved.updatedAt) == solved)
}
