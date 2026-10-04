import Foundation
import Testing
@testable import PuzzleAlarmCore

@Suite("Persistence")
struct PersistenceTests {
    private func state(_ session: WakeUpSession? = nil, checkpoint: ResumeCheckpoint? = nil) throws -> RepositoryState {
        let value = try session ?? activeSession()
        return try RepositoryState(definitions: [value.definitionSnapshot], sessions: [
            PersistedSession(session: value, updatedAt: value.completedAt ?? value.scheduledWakeUpDate,
                             checkpoint: checkpoint)
        ])
    }

    private func loaded(_ repository: any PuzzleAlarmRepository) async throws -> RepositorySnapshot {
        guard case let .loaded(snapshot, _) = try await repository.load() else {
            throw FixtureError.invalidDate
        }
        return snapshot
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PuzzleAlarmTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func missingAndExplicitlyEmptyAreDistinct() async throws {
        let repository = InMemoryRepository()
        #expect(try await repository.load() == .missing)
        let saved = try await repository.commit(RepositoryState(), expecting: .missing)
        #expect(try await repository.load() == .loaded(saved, interruptedWrite: false))
        #expect(saved.schemaVersion == 2)
    }

    @Test func definitionsSaveLoadUpdateDeleteAndMultiple() async throws {
        let repository = InMemoryRepository()
        var value = try RepositoryState(definitions: [definition()])
        let first = try await repository.commit(value, expecting: .missing)
        let other = try AlarmDefinition(
            id: uuid(90), time: AlarmTime(hour: 23, minute: 59), weekdays: [.saturday, .sunday],
            enabled: false, dismissalMode: .annoyingOnly, challengeSequence: ChallengeSequence([]),
            selectedSound: .bundled(.siren), createdAt: instant("2025-01-01T00:00:00Z"),
            updatedAt: instant("2025-01-01T00:00:00Z")
        )
        value.definitions.append(other)
        value.definitions[0] = try value.definitions[0].settingEnabled(false, at: instant("2026-10-01T00:00:00Z"))
        let second = try await repository.commit(value, expecting: first.version)
        #expect(try await loaded(repository).state == value)
        value.definitions.removeAll { $0.id == uuid(1) }
        _ = try await repository.commit(value, expecting: second.version)
        #expect(try await loaded(repository).state.definitions == [other])
    }

    @Test func configurationPermutationsRoundTrip() async throws {
        for sound in [SoundSelection.systemDefault] + BundledSound.allCases.map(SoundSelection.bundled) {
            let initial = try definition(sequence: Array(configurations().reversed()))
            let edited = try initial.replacing(
                time: AlarmTime(hour: 0, minute: 0), weekdays: Set(Weekday.allCases), enabled: true,
                mode: .challengesRequired, challenges: initial.challengeSequence, sound: sound,
                at: instant("2026-10-01T00:00:00Z")
            )
            let repository = InMemoryRepository()
            let value = try RepositoryState(definitions: [edited])
            _ = try await repository.commit(value, expecting: .missing)
            #expect(try await loaded(repository).state == value)
        }
    }

    @Test func sessionIndexProgressLedgerAndParentSurviveReload() async throws {
        var value = try activeSession()
        try value.recordChallengeSuccess(expectedIndex: 0, at: value.scheduledWakeUpDate)
        try value.recordProgress(.memory(successfulRounds: 2))
        let checkpoint = ResumeCheckpoint(challengeIndex: 1, detail: .memory(
            roundID: uuid(70), digits: [0, 1, 2, 3, 4, 5], phase: .hidden, visibleUntil: nil
        ))
        let stored = try state(value, checkpoint: checkpoint)
        let repository = InMemoryRepository()
        _ = try await repository.commit(stored, expecting: .missing)
        let bytes = try #require(await repository.storedRepresentation())
        let restarted = InMemoryRepository(storedRepresentation: bytes)
        let result = try await loaded(restarted).state
        #expect(result == stored)
        #expect(result.sessions[0].session.currentChallengeIndex == 1)
        #expect(result.sessions[0].session.parentAlarmID == uuid(1))
        #expect(try result.ownershipLedger().map(\.alarmKitID) == value.plan.alarms.map(\.id))
        #expect(try result.ownershipLedger().map(\.ordinal) == [0, 1, 2, 3, 4])
        #expect(result.sessions[0].checkpoint == checkpoint)
    }

    @Test func mathProblemSurvivesWithoutDuplicatingProgressCounter() async throws {
        var value = try activeSession()
        try value.recordProgress(.math(correctAnswers: 3))
        let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .math(
            problemID: uuid(80), prompt: "12 + 7", expectedAnswer: 19
        ))
        let repository = InMemoryRepository()
        _ = try await repository.commit(state(value, checkpoint: checkpoint), expecting: .missing)
        let restored = try await loaded(repository).state.sessions[0]
        #expect(restored.checkpoint == checkpoint)
        #expect(restored.session.progress == .math(correctAnswers: 3))
    }

    @Test(arguments: ResumeCheckpoint.MemoryPhase.allCases)
    func memoryPhaseNeverBecomesVisibleOnDecode(_ phase: ResumeCheckpoint.MemoryPhase) throws {
        let value = try activeSession(sequence: [.memory(MemoryConfiguration(requiredRounds: 3))])
        let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .memory(
            roundID: uuid(80), digits: [9, 8, 7, 6, 5, 4], phase: phase,
            visibleUntil: phase == .visible ? value.scheduledWakeUpDate.addingTimeInterval(3) : nil
        ))
        let original = try state(value, checkpoint: checkpoint)
        #expect(try roundTrip(original) == original)
    }

    @Test func qrPersistsTokenWithoutCameraState() throws {
        let value = try activeSession(sequence: [.qr(QRConfiguration(token: uuid(99)))])
        let result = try roundTrip(state(value))
        #expect(result.sessions[0].session.currentChallenge == .qr(QRConfiguration(token: uuid(99))))
        #expect(result.sessions[0].checkpoint == nil)
    }

    @Test func checkpointMismatchAndMalformedSequencesAreRejected() throws {
        let value = try activeSession()
        let bad: [ResumeCheckpoint] = [
            .init(challengeIndex: 1, detail: .math(problemID: uuid(80), prompt: "1+1", expectedAnswer: 2)),
            .init(challengeIndex: 0, detail: .math(problemID: uuid(80), prompt: " ", expectedAnswer: 0)),
            .init(challengeIndex: 0, detail: .memory(roundID: uuid(80), digits: [1], phase: .hidden, visibleUntil: nil))
        ]
        for checkpoint in bad {
            #expect(throws: DomainError.self) { try state(value, checkpoint: checkpoint) }
        }
        let memory = try activeSession(sequence: [.memory(MemoryConfiguration())])
        for (digits, phase, deadline) in [
            ([1, 2], ResumeCheckpoint.MemoryPhase.hidden, Optional<Date>.none),
            ([1, 2, 3, 4, 5, 11], .hidden, nil),
            ([1, 2, 3, 4, 5, 6], .visible, nil),
            ([1, 2, 3, 4, 5, 6], .hidden, memory.scheduledWakeUpDate),
            ([1, 2, 3, 4, 5, 6], .visible, memory.scheduledWakeUpDate.addingTimeInterval(100))
        ] {
            let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .memory(
                roundID: uuid(80), digits: digits, phase: phase, visibleUntil: deadline
            ))
            #expect(throws: DomainError.self) { try state(memory, checkpoint: checkpoint) }
        }
    }

    @Test func allLifecyclePhasesAndUncertainOperationsRoundTrip() async throws {
        var variants = [try session()]
        var scheduling = try session()
        try scheduling.beginScheduling()
        try scheduling.beginScheduleAttempt(id: scheduling.primaryAlarmID)
        variants.append(scheduling) // Process death after OS effect, before acknowledgment.
        try scheduling.recordScheduleFailure(id: scheduling.primaryAlarmID)
        variants.append(scheduling)
        variants += [try armedSession(), try activeSession(), try solvedSession()]
        var partial = try solvedSession()
        try partial.beginCancellation(id: partial.primaryAlarmID)
        variants.append(partial)
        try partial.recordCancellation(id: partial.primaryAlarmID, succeeded: false)
        variants.append(partial)
        try partial.beginCancellation(id: partial.backupAlarmIDs[0])
        variants.append(partial)
        var completed = try solvedSession()
        try cancelAll(&completed)
        try completed.finalizeCompletion(at: completed.scheduledWakeUpDate)
        variants.append(completed)
        var retiring = try armedSession()
        try retiring.requestRetirement()
        variants.append(retiring)
        try cancelAll(&retiring)
        try retiring.finishRetirement()
        variants.append(retiring)
        for value in variants {
            let repository = InMemoryRepository()
            let original = try state(value)
            _ = try await repository.commit(original, expecting: .missing)
            #expect(try await loaded(repository).state == original)
        }
        #expect(Set(variants.map(\.phase)).count == 10)
    }

    @Test func completedSessionRemainsCompletedOnRepeatedReload() async throws {
        var value = try solvedSession()
        try cancelAll(&value)
        try value.finalizeCompletion(at: value.scheduledWakeUpDate)
        let repository = InMemoryRepository()
        _ = try await repository.commit(state(value), expecting: .missing)
        for _ in 0..<5 {
            #expect(try await loaded(repository).state.sessions[0].session == value)
        }
    }

    @Test func parentEditAndDeletionRetainSessionSnapshotAndOwnership() async throws {
        let repository = InMemoryRepository()
        var value = try state()
        let original = value.sessions[0]
        let first = try await repository.commit(value, expecting: .missing)
        value.definitions[0] = try value.definitions[0].settingEnabled(false, at: original.updatedAt)
        let second = try await repository.commit(value, expecting: first.version)
        #expect(try await loaded(repository).state.sessions[0] == original)
        value.definitions.removeAll()
        _ = try await repository.commit(value, expecting: second.version)
        #expect(try await loaded(repository).state.sessions[0] == original)
        #expect(try await loaded(repository).state.ownershipLedger().count == 5)
    }

    @Test func schemaAndWholeDocumentRoundTrip() throws {
        let snapshot = try RepositorySnapshot(state: state())
        let bytes = try RepositoryCodec.encode(snapshot)
        #expect(try RepositoryCodec.decode(bytes) == snapshot)
        #expect(try roundTrip(snapshot) == snapshot)
        #expect(snapshot.schemaVersion == 2)
    }

    @Test(arguments: [0, 3, 99])
    func unsupportedSchemasNeverBecomeEmpty(_ version: Int) async throws {
        let bytes = Data("{\"schemaVersion\":\(version)}".utf8)
        let repository = InMemoryRepository(storedRepresentation: bytes)
        await #expect(throws: PersistenceError.unsupportedSchema(version)) { try await repository.load() }
        await #expect(throws: PersistenceError.unsupportedSchema(version)) {
            try await repository.commit(RepositoryState(), expecting: .missing)
        }
        #expect(await repository.storedRepresentation() == bytes)
    }

    @Test func malformedTruncatedAndInvalidConfigurationFailClosed() async throws {
        let good = try RepositoryCodec.encode(RepositorySnapshot(state: state()))
        let text = String(decoding: good, as: UTF8.self)
        let variants = [Data(), Data("{".utf8), Data("null".utf8), Data(good.dropLast(5)),
                        Data(text.replacingOccurrences(of: "challenges_required", with: "unknown_mode").utf8),
                        Data(text.replacingOccurrences(of: "\"hour\":6", with: "\"hour\":99").utf8)]
        for bytes in variants {
            let repository = InMemoryRepository(storedRepresentation: bytes)
            await #expect(throws: PersistenceError.self) { try await repository.load() }
            await #expect(throws: PersistenceError.self) {
                try await repository.commit(RepositoryState(), expecting: .missing)
            }
            #expect(await repository.storedRepresentation() == bytes)
        }
    }

    @Test func duplicateOwnershipAcrossSessionsIsRejected() throws {
        let first = try session()
        let second = try WakeUpSession(id: uuid(3), definition: first.definitionSnapshot,
                                      context: first.context, plan: first.plan, createdAt: first.createdAt)
        #expect(throws: PersistenceError.duplicateOwnership(first.primaryAlarmID)) {
            try RepositoryState(sessions: [
                PersistedSession(session: first, updatedAt: first.createdAt),
                PersistedSession(session: second, updatedAt: second.createdAt)
            ])
        }
        let record = try AlarmOwnership(alarmKitID: uuid(100), sessionID: nil, parentAlarmID: uuid(1),
                                        ordinal: 0, intendedDate: first.scheduledWakeUpDate,
                                        scheduling: .inFlight, cancellation: .notRequested)
        #expect(throws: PersistenceError.duplicateOwnership(uuid(100))) {
            try RepositoryState(detachedOwnership: [record, record])
        }
    }

    @Test func duplicateDefinitionsSessionsAndCompetingLedgerAuthorityAreRejected() throws {
        let value = try state()
        #expect(throws: DomainError.self) {
            try RepositoryState(definitions: value.definitions + value.definitions)
        }
        #expect(throws: DomainError.self) {
            try RepositoryState(sessions: value.sessions + value.sessions)
        }
        #expect(throws: DomainError.self) {
            try RepositoryState(sessions: value.sessions, detachedOwnership: value.ownershipLedger())
        }
    }

    @Test func reconciliationInventoryRecognizesMissingStaleAndOrphanedIDs() throws {
        let value = try state()
        let ids = value.sessions[0].session.plan.alarms.map(\.id)
        let report = try ReconciliationInventory(state: value, observedOwnedIDs: [ids[0], ids[1], uuid(200)])
        #expect(report.entries.filter { $0.status == .recognizedPresent }.count == 2)
        #expect(report.entries.filter { $0.status == .persistedMissing }.count == 3)
        #expect(report.entries.last?.status == .potentiallyOrphanedOwned)
        var stale = value
        stale.definitions = []
        let staleReport = try ReconciliationInventory(state: stale, observedOwnedIDs: [ids[0]])
        #expect(staleReport.entries.filter { $0.status == .stalePresent }.count == 1)
        #expect(staleReport.entries.filter { $0.status == .staleMissing }.count == 4)
        #expect(throws: DomainError.self) {
            try ReconciliationInventory(state: value, observedOwnedIDs: [ids[0], ids[0]])
        }
    }

    @Test func emptyAndDetachedLedgerRemainHonest() throws {
        #expect(try ReconciliationInventory(state: RepositoryState(), observedOwnedIDs: []).entries.isEmpty)
        let original = try session()
        let tombstone = try AlarmOwnership(
            alarmKitID: uuid(101), sessionID: uuid(201), parentAlarmID: original.parentAlarmID,
            ordinal: 4, intendedDate: original.scheduledWakeUpDate,
            scheduling: .inFlight, cancellation: .failed
        )
        let ordinary = try AlarmOwnership(
            alarmKitID: uuid(102), sessionID: nil, parentAlarmID: original.parentAlarmID,
            ordinal: 0, intendedDate: original.scheduledWakeUpDate,
            scheduling: .scheduled, cancellation: .notRequested
        )
        let value = try RepositoryState(definitions: [original.definitionSnapshot],
                                        detachedOwnership: [tombstone, ordinary])
        #expect(try roundTrip(value) == value)
        let report = try ReconciliationInventory(state: value, observedOwnedIDs: [uuid(101), uuid(102)])
        #expect(report.entries.map(\.status) == [.stalePresent, .recognizedPresent])
    }

    @Test func inMemoryReadWriteFailuresPreserveCommittedBytes() async throws {
        let repository = InMemoryRepository()
        let good = try await repository.commit(state(), expecting: .missing)
        let bytes = await repository.storedRepresentation()
        await repository.failNext(.read)
        await #expect(throws: PersistenceError.self) { try await repository.load() }
        await repository.failNext(.write)
        await #expect(throws: PersistenceError.self) {
            try await repository.commit(RepositoryState(), expecting: good.version)
        }
        #expect(await repository.storedRepresentation() == bytes)
        #expect(try await loaded(repository) == good)
    }

    @Test func staleWritersCannotOverwriteNewerState() async throws {
        let repository = InMemoryRepository()
        let base = try await repository.commit(RepositoryState(), expecting: .missing)
        let saved = try await repository.commit(state(), expecting: base.version)
        await #expect(throws: PersistenceError.conflict) {
            try await repository.commit(RepositoryState(), expecting: base.version)
        }
        #expect(try await loaded(repository) == saved)
    }

    @Test func simultaneousMemoryWritesHaveExactlyOneWinner() async throws {
        let repository = InMemoryRepository()
        let value = try state()
        let wins = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do { _ = try await repository.commit(value, expecting: .missing); return true }
                    catch PersistenceError.conflict { return false } catch { Issue.record(error); return false }
                }
            }
            var count = 0
            for await result in group where result { count += 1 }
            return count
        }
        #expect(wins == 1)
        #expect(try await loaded(repository).state == value)
    }

    @Test func diskMissingSaveReplaceAndReload() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        #expect(try await repository.load() == .missing)
        let original = try state()
        let first = try await repository.commit(original, expecting: .missing)
        let restarted = DiskRepository(directory: directory)
        #expect(try await loaded(restarted) == first)
        let second = try await restarted.commit(RepositoryState(), expecting: first.version)
        #expect(try await loaded(repository) == second)
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("state.json.pending").path))
        #expect(try DiskRepository.applicationSupportDirectory().lastPathComponent == "PuzzleAlarm")
    }

    @Test func diskFailedWritePreservesPriorDocumentAndReportsInterruptedWrite() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let good = try await repository.commit(state(), expecting: .missing)
        let originalBytes = try Data(contentsOf: directory.appendingPathComponent("state.json"))
        let failing = DiskRepository(directory: directory, beforeCommit: { throw PersistenceError.io("injected") })
        await #expect(throws: PersistenceError.self) {
            try await failing.commit(RepositoryState(), expecting: good.version)
        }
        #expect(try Data(contentsOf: directory.appendingPathComponent("state.json")) == originalBytes)
        #expect(try await repository.load() == .loaded(good, interruptedWrite: true))
        let next = try await repository.commit(good.state, expecting: good.version)
        #expect(try await repository.load() == .loaded(next, interruptedWrite: false))
    }

    @Test func interruptedInitialWriteNeverLooksLikeEmptyRepository() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let failing = DiskRepository(directory: directory, beforeCommit: { throw PersistenceError.io("injected") })
        await #expect(throws: PersistenceError.self) { try await failing.commit(state(), expecting: .missing) }
        let restarted = DiskRepository(directory: directory)
        await #expect(throws: PersistenceError.interruptedInitialWrite) { try await restarted.load() }
        await #expect(throws: PersistenceError.interruptedInitialWrite) {
            try await restarted.commit(RepositoryState(), expecting: .missing)
        }
    }

    @Test func diskCorruptionIsRetainedAndCannotBeOverwritten() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("state.json")
        let bytes = Data("{\"schemaVersion\":1,".utf8)
        try bytes.write(to: file)
        let repository = DiskRepository(directory: directory)
        await #expect(throws: PersistenceError.corrupt) { try await repository.load() }
        await #expect(throws: PersistenceError.corrupt) {
            try await repository.commit(RepositoryState(), expecting: .missing)
        }
        #expect(try Data(contentsOf: file) == bytes)
    }

    @Test func realFilesystemWriteAndReadErrorsAreSurfaced() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = DiskRepository(directory: directory)
        let good = try await repository.commit(state(), expecting: .missing)
        // A directory at the staging path causes a real filesystem write failure.
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("state.json.pending"),
                                                withIntermediateDirectories: false)
        await #expect(throws: PersistenceError.self) {
            try await repository.commit(RepositoryState(), expecting: good.version)
        }
        #expect(try await loaded(repository) == good)
        let blocked = DiskRepository(directory: directory.appendingPathComponent("state.json"))
        await #expect(throws: PersistenceError.self) { try await blocked.load() }
    }

    @Test func separateDiskActorsDoNotLoseConcurrentWrites() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let value = try state()
        let wins = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    let repository = DiskRepository(directory: directory)
                    do { _ = try await repository.commit(value, expecting: .missing); return true }
                    catch PersistenceError.conflict { return false } catch { Issue.record(error); return false }
                }
            }
            var count = 0
            for await result in group where result { count += 1 }
            return count
        }
        #expect(wins == 1)
        #expect(try await loaded(DiskRepository(directory: directory)).state == value)
    }

    @Test func invalidCommitCannotDamageKnownGoodState() async throws {
        let repository = InMemoryRepository()
        let valid = try state()
        let first = try await repository.commit(valid, expecting: .missing)
        let bytes = await repository.storedRepresentation()
        var invalid = valid
        invalid.sessions += valid.sessions
        await #expect(throws: DomainError.self) {
            try await repository.commit(invalid, expecting: first.version)
        }
        #expect(await repository.storedRepresentation() == bytes)
    }

    @Test func invalidOwnershipAndTimestampDecodeAreRejected() throws {
        let value = try session()
        let ownership = try AlarmOwnership(alarmKitID: uuid(100), sessionID: nil,
                                           parentAlarmID: value.parentAlarmID, ordinal: 0,
                                           intendedDate: value.scheduledWakeUpDate,
                                           scheduling: .inFlight, cancellation: .notRequested)
        for ordinal in [-1, 1, 5] {
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(AlarmOwnership.self, from: mutatedJSON(ownership) { $0["ordinal"] = ordinal })
            }
        }
        let record = try PersistedSession(session: value, updatedAt: value.createdAt)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(PersistedSession.self, from: mutatedJSON(record) { $0["updatedAt"] = 0 })
        }
        let checkpoint = ResumeCheckpoint(challengeIndex: 0, detail: .math(
            problemID: uuid(80), prompt: "1+1", expectedAnswer: 2
        ))
        #expect(throws: DomainError.self) {
            try PersistedSession(session: value, updatedAt: value.createdAt, checkpoint: checkpoint)
        }
    }

    @Test func cancelledIDsStillPresentAreStaleNotNewSessions() throws {
        var value = try solvedSession()
        try value.beginCancellation(id: value.primaryAlarmID)
        try value.recordCancellation(id: value.primaryAlarmID, succeeded: true)
        let before = value
        let report = try ReconciliationInventory(state: state(value), observedOwnedIDs: [value.primaryAlarmID])
        #expect(report.entries.first?.status == .stalePresent)
        #expect(value == before)
        #expect(value.phase == .completing)
    }

    @Test func realDiskReadFailureIsNotMissing() async throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("state.json"),
                                                withIntermediateDirectories: false)
        let repository = DiskRepository(directory: directory)
        await #expect(throws: PersistenceError.io("read")) { try await repository.load() }
    }

    @Test func restoredLedgerKeepsExactlyOnePrimaryAndFourBackups() async throws {
        let value = try state()
        let repository = InMemoryRepository()
        _ = try await repository.commit(value, expecting: .missing)
        let restarted = InMemoryRepository(storedRepresentation: await repository.storedRepresentation())
        let restored = try await loaded(restarted).state
        let ledger = try restored.ownershipLedger()
        let session = restored.sessions[0].session
        #expect(ledger.filter(\.isPrimary).map(\.alarmKitID) == [session.primaryAlarmID])
        #expect(ledger.filter { !$0.isPrimary }.map(\.alarmKitID) == session.backupAlarmIDs)
        #expect(ledger.allSatisfy { $0.sessionID == session.id && $0.parentAlarmID == session.parentAlarmID })
        // A detached ordinary alarm is also primary, despite having no session.
        let ordinary = try AlarmOwnership(alarmKitID: uuid(100), sessionID: nil,
            parentAlarmID: session.parentAlarmID, ordinal: 0, intendedDate: session.scheduledWakeUpDate,
            scheduling: .scheduled, cancellation: .notRequested)
        #expect(try roundTrip(ordinary).isPrimary)
    }
}
