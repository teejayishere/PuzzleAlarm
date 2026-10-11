import Foundation
import Testing
@testable import PuzzleAlarmCore

private let allowedChallengeOrders: [[Int]] = [
    [0], [1], [2], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1],
    [0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]
]

private func challengeCoordinator(_ order: [Int] = [0, 1, 2]) throws -> ChallengeCoordinator {
    let configurations = try configurations()
    let session = try activeSession(sequence: order.map { configurations[$0] })
    return try ChallengeCoordinator(restoring: PersistedSession(session: session, updatedAt: session.scheduledWakeUpDate))
}

@Test(arguments: allowedChallengeOrders)
func ChallengeCoordinatorAllOrdersRestoreAndComplete(_ order: [Int]) throws {
    var coordinator = try challengeCoordinator(order)
    let configuration = try configurations()
    for (index, kindIndex) in order.enumerated() {
        coordinator = try ChallengeCoordinator(restoring: roundTrip(coordinator.record))
        #expect(coordinator.currentChallenge == configuration[kindIndex])
        let identity = try #require(coordinator.currentIdentity)
        #expect(identity.index == index)
        let date = coordinator.record.updatedAt.addingTimeInterval(1)
        #expect(try coordinator.recordSuccess(for: identity, at: date))
        let after = coordinator
        #expect(!(try coordinator.recordSuccess(for: identity, at: date.addingTimeInterval(10))))
        #expect(coordinator == after)
        #expect(coordinator.record.session.completedAt == nil)
        #expect(coordinator.record.session.remainingCancellationIDs.count == 5)
    }
    coordinator = try ChallengeCoordinator(restoring: roundTrip(coordinator.record))
    #expect(coordinator.sequenceSucceeded)
    #expect(coordinator.currentChallenge == nil && coordinator.currentIdentity == nil)
    #expect(coordinator.record.session.phase == .completing)
    // Completion remains exclusively gated by lifecycle cleanup.
    var session = coordinator.record.session
    #expect(throws: DomainError.self) { try session.finalizeCompletion(at: coordinator.record.updatedAt) }
    try cancelAll(&session)
    try session.finalizeCompletion(at: coordinator.record.updatedAt)
    let completed = try ChallengeCoordinator(restoring: PersistedSession(session: session, updatedAt: coordinator.record.updatedAt))
    #expect(completed.sequenceSucceeded && completed.currentIdentity == nil)
}

@Test(arguments: allowedChallengeOrders)
func ChallengeCoordinatorRejectsInvalidIdentitiesWithoutMutation(_ order: [Int]) throws {
    var coordinator = try challengeCoordinator(order)
    let current = try #require(coordinator.currentIdentity)
    let invalid = [
        ChallengeIdentity(sessionID: uuid(200), index: 0, kind: current.kind),
        ChallengeIdentity(sessionID: current.sessionID, index: -1, kind: current.kind),
        ChallengeIdentity(sessionID: current.sessionID, index: order.count, kind: current.kind),
        ChallengeIdentity(sessionID: current.sessionID, index: 0, kind: current.kind == .math ? .qr : .math)
    ] + order.dropFirst().enumerated().map { offset, kindIndex in
        ChallengeIdentity(sessionID: current.sessionID, index: offset + 1, kind: ChallengeKind.allCases[kindIndex])
    }
    let before = coordinator
    for identity in invalid {
        #expect(throws: DomainError.outOfOrder) {
            try coordinator.recordSuccess(for: identity, at: before.record.updatedAt)
        }
        #expect(coordinator == before)
    }
}

@Test func ChallengeCoordinatorRestoresProgressAndCheckpointAndClearsOnAdvance() throws {
    var coordinator = try challengeCoordinator()
    let math = try #require(coordinator.currentIdentity)
    let time = coordinator.record.updatedAt.addingTimeInterval(1)
    #expect(try coordinator.recordProgress(.math(correctAnswers: 2), for: math, at: time))
    let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .math(problemID: uuid(90), prompt: "2 + 3", expectedAnswer: 5))
    #expect(try coordinator.saveCheckpoint(checkpoint, for: math, at: time))
    coordinator = try ChallengeCoordinator(restoring: roundTrip(coordinator.record))
    #expect(coordinator.record.session.progress == .math(correctAnswers: 2))
    #expect(coordinator.record.checkpoint == checkpoint)
    let before = coordinator
    #expect(!(try coordinator.recordProgress(.math(correctAnswers: 2), for: math, at: time)))
    #expect(!(try coordinator.saveCheckpoint(checkpoint, for: math, at: time)))
    #expect(coordinator == before)
    #expect(throws: DomainError.self) { try coordinator.recordProgress(.math(correctAnswers: 1), for: math, at: time) }
    #expect(throws: DomainError.self) { try coordinator.recordProgress(.memory(successfulRounds: 1), for: math, at: time) }
    #expect(throws: DomainError.self) {
        try coordinator.saveCheckpoint(ResumeCheckpoint(challengeIndex: 1, detail: checkpoint.detail), for: math, at: time)
    }
    #expect(coordinator == before)
    #expect(try coordinator.recordSuccess(for: math, at: time))
    #expect(coordinator.record.checkpoint == nil && coordinator.record.session.progress == .notStarted)
    #expect(throws: DomainError.outOfOrder) { try coordinator.recordProgress(.math(correctAnswers: 3), for: math, at: time) }
    #expect(throws: DomainError.outOfOrder) { try coordinator.saveCheckpoint(checkpoint, for: math, at: time) }
    let memory = try #require(coordinator.currentIdentity)
    #expect(try coordinator.recordProgress(.memory(successfulRounds: 1), for: memory, at: time))
    let hidden = ResumeCheckpoint(challengeIndex: 1, detail: .memory(roundID: uuid(91), digits: [1, 2, 3, 4, 5, 6], phase: .hidden, visibleUntil: nil))
    #expect(try coordinator.saveCheckpoint(hidden, for: memory, at: time))
    coordinator = try ChallengeCoordinator(restoring: roundTrip(coordinator.record))
    #expect(coordinator.record.checkpoint == hidden)
    #expect(try coordinator.recordSuccess(for: memory, at: time))
    let qr = try #require(coordinator.currentIdentity)
    #expect(try coordinator.recordProgress(.qrWaiting, for: qr, at: time))
    coordinator = try ChallengeCoordinator(restoring: roundTrip(coordinator.record))
    #expect(coordinator.currentChallenge == .qr(QRConfiguration(token: uuid(99))))
    #expect(coordinator.record.session.progress == .qrWaiting)
}

@Test func ChallengeCoordinatorRejectsRegressingAndNonfiniteTimeAtomically() throws {
    var coordinator = try challengeCoordinator()
    let identity = try #require(coordinator.currentIdentity)
    let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .math(problemID: uuid(90), prompt: "1 + 1", expectedAnswer: 2))
    let time = coordinator.record.updatedAt.addingTimeInterval(10)
    try coordinator.saveCheckpoint(checkpoint, for: identity, at: time)
    let before = coordinator
    for invalid in [time.addingTimeInterval(-1), Date(timeIntervalSince1970: .infinity)] {
        #expect(throws: DomainError.self) { try coordinator.recordSuccess(for: identity, at: invalid) }
        #expect(throws: DomainError.self) { try coordinator.recordProgress(.math(correctAnswers: 1), for: identity, at: invalid) }
        let replacement = ResumeCheckpoint(challengeIndex: 0, detail: .math(problemID: uuid(91), prompt: "2 + 2", expectedAnswer: 4))
        #expect(throws: DomainError.self) { try coordinator.saveCheckpoint(replacement, for: identity, at: invalid) }
        #expect(coordinator == before)
    }
}

@Test func ChallengeCoordinatorNonactiveSessionsCannotStartOrSolve() throws {
    for session in [try session(), try armedSession()] {
        var coordinator = try ChallengeCoordinator(restoring: PersistedSession(session: session, updatedAt: session.createdAt))
        #expect(coordinator.currentIdentity == nil && !coordinator.sequenceSucceeded)
        let before = coordinator
        let identity = ChallengeIdentity(sessionID: session.id, index: 0, kind: .math)
        #expect(throws: DomainError.self) { try coordinator.recordSuccess(for: identity, at: session.scheduledWakeUpDate) }
        #expect(coordinator == before)
    }
}

@Test func ChallengeCoordinatorPersistenceFailureRestoresCommittedProgress() async throws {
    let repository = InMemoryRepository()
    var coordinator = try challengeCoordinator()
    var state = try RepositoryState(sessions: [coordinator.record])
    let initial = try await repository.commit(state, expecting: .missing)
    let identity = try #require(coordinator.currentIdentity)
    try coordinator.recordSuccess(for: identity, at: coordinator.record.updatedAt)
    state.sessions[0] = coordinator.record
    await repository.failNext(.write)
    await #expect(throws: PersistenceError.self) { try await repository.commit(state, expecting: initial.version) }
    guard case let .loaded(restored, _) = try await repository.load() else { Issue.record("Missing committed state"); return }
    coordinator = try ChallengeCoordinator(restoring: restored.state.sessions[0])
    #expect(coordinator.currentIdentity == identity)
    #expect(try coordinator.recordSuccess(for: identity, at: coordinator.record.updatedAt))
    state.sessions[0] = coordinator.record
    _ = try await repository.commit(state, expecting: restored.version)
    guard case let .loaded(relaunched, _) = try await repository.load() else { Issue.record("Missing progress"); return }
    coordinator = try ChallengeCoordinator(restoring: relaunched.state.sessions[0])
    let before = coordinator
    #expect(!(try coordinator.recordSuccess(for: identity, at: coordinator.record.updatedAt)))
    #expect(coordinator == before && coordinator.currentIdentity?.kind == .memory)
}
