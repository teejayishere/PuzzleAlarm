import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func QRLifecycleCASRevalidatesSnapshotAndNeverPerformsEffects() async throws {
    let repository = FaultRepository(), scheduler = FakeAlarmScheduler()
    let session = try activeSession(sequence: [.qr(QRConfiguration(token: uuid(99))), .math(try MathConfiguration())])
    let date = session.scheduledWakeUpDate
    let record = try PersistedSession(session: session, updatedAt: date)
    _ = try await repository.commit(RepositoryState(definitions: [session.definitionSnapshot], sessions: [record]),
                                    expecting: .missing)
    let owner = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: { date })
    let identity = ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr)
    await repository.interfereOnce { storage in
        let state = try await repositoryState(storage)
        var next = state
        var reducer = try ChallengeCoordinator(restoring: next.sessions[0])
        try reducer.recordSuccess(for: identity, at: date)
        next.sessions[0] = reducer.record
        let read = try await storage.load()
        _ = try await storage.commit(next, expecting: read.version)
    }
    let result = try await owner.submitQR(QRConfiguration(token: uuid(99)).expectedPayload, for: identity)
    #expect(result.1 == .stale)
    #expect(result.0.state.sessions[0].session.currentChallengeIndex == 1)
    #expect(scheduler.values.calls.isEmpty)
    let conflicting = FaultRepository()
    let before = try RepositoryState(definitions: [session.definitionSnapshot], sessions: [record])
    _ = try await conflicting.commit(before, expecting: .missing)
    let boundedOwner = AlarmLifecycleCoordinator(repository: conflicting, scheduler: scheduler, clock: { date })
    await conflicting.conflictForever()
    await #expect(throws: LifecycleError.conflictLimit) {
        try await boundedOwner.submitQR(QRConfiguration(token: uuid(99)).expectedPayload, for: identity)
    }
    #expect(try await repositoryState(conflicting) == before)
    #expect(await conflicting.attempts == 4) // Seed plus exactly three CAS attempts.
}

@Test func QRLifecycleMissingRecordRejectsAndWriteFailureDiscardsSuccess() async throws {
    let repository = InMemoryRepository(), scheduler = FakeAlarmScheduler()
    let session = try activeSession(sequence: [.qr(QRConfiguration(token: uuid(99)))])
    let date = session.scheduledWakeUpDate
    let owner = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: { date })
    let identity = ChallengeIdentity(sessionID: session.id, index: 0, kind: .qr)
    await #expect(throws: DomainError.outOfOrder) { try await owner.submitQR("", for: identity) }
    // Parent definition changed after occurrence activation. Its new token must
    // neither replace the snapshot nor satisfy the protected occurrence.
    let edited = try definition(sequence: [.qr(QRConfiguration(token: uuid(100)))])
    let state = try RepositoryState(definitions: [edited],
        sessions: [PersistedSession(session: session, updatedAt: date)])
    _ = try await repository.commit(state, expecting: .missing)
    let foreign = try await owner.submitQR(QRConfiguration(token: uuid(100)).expectedPayload, for: identity)
    #expect(foreign.1 == .wrong && foreign.0.state == state)
    await repository.failNext(.write)
    await #expect(throws: PersistenceError.self) {
        try await owner.submitQR(QRConfiguration(token: uuid(99)).expectedPayload, for: identity)
    }
    #expect(try await repositoryState(repository) == state)
    let result = try await owner.submitQR(QRConfiguration(token: uuid(99)).expectedPayload, for: identity)
    #expect(result.1 == .completed && result.0.state.sessions[0].session.phase == .completing)
    #expect(scheduler.values.calls.isEmpty)
}
