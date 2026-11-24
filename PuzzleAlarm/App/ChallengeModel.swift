import Foundation
import Combine
import PuzzleAlarmCore

@MainActor
final class ChallengeModel: ObservableObject {
    @Published private(set) var current: ChallengeSnapshot?
    @Published private(set) var busy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var feedback: String?
    @Published private(set) var nextWakeUpDate: Date?
    private let repository: any PuzzleAlarmRepository
    private let service: any AlarmManagementService
    private let clock: @Sendable () -> Date
    private let advancePreviewClock: (@Sendable (Date) throws -> Void)?
    private let coordinator = ChallengeCoordinator()
    private var selectedSessionID: UUID?

    var supportsPreview: Bool { advancePreviewClock != nil }
    var now: Date { clock() }
    var secondsUntilNextWakeUp: TimeInterval? { nextWakeUpDate.map { max(0, $0.timeIntervalSince(clock())) } }

    init(repository: any PuzzleAlarmRepository, service: any AlarmManagementService,
         clock: @escaping @Sendable () -> Date = { Date() },
         advancePreviewClock: (@Sendable (Date) throws -> Void)? = nil) {
        self.repository = repository; self.service = service
        self.clock = clock; self.advancePreviewClock = advancePreviewClock
    }

    func refresh() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do {
            _ = try await service.perform(.refresh)
            try await publish(prepare: true)
            errorMessage = nil
        } catch { errorMessage = "Could not restore the wake-up session. \(error)" }
    }

    func runNow(alarmID: UUID) async {
        guard let advancePreviewClock, !busy else { return }
        busy = true; defer { busy = false }
        do {
            guard case let .loaded(snapshot, _) = try await repository.load(),
                  let record = snapshot.state.sessions.filter({
                      $0.session.parentAlarmID == alarmID && [.armed, .degraded].contains($0.session.phase)
                  }).min(by: { $0.session.scheduledWakeUpDate < $1.session.scheduledWakeUpDate })
            else { throw DomainError.invalidTransition }
            try advancePreviewClock(record.session.scheduledWakeUpDate)
            selectedSessionID = record.session.id
            _ = try await service.perform(.refresh)
            try await publish(prepare: true)
            errorMessage = nil; feedback = nil
        } catch { errorMessage = "Could not start this preview. Enable a challenge alarm first. \(error)" }
    }

    func submit(_ action: ChallengeCommand.Action, expecting displayed: ChallengeSnapshot? = nil) async {
        guard let current, current.phase == .active, !busy else { return }
        if let displayed,
           displayed.sessionID != current.sessionID || displayed.challengeIndex != current.challengeIndex { return }
        let command = ChallengeCommand(sessionID: current.sessionID,
            challengeIndex: current.challengeIndex, action: action)
        busy = true; defer { busy = false }
        do {
            let before = current
            try await transition(command)
            _ = try await service.perform(.refresh)
            try await publish(prepare: true)
            errorMessage = nil
            switch action {
            case .submitMath, .submitMemory, .scanQR:
                if let after = self.current,
                   after.challengeIndex == before.challengeIndex && progress(after) == progress(before) {
                    feedback = "That didn’t match. Try again."
                } else { feedback = nil }
            default: break
            }
        } catch {
            errorMessage = "Progress could not be saved. Your alarm is not complete. \(error)"
            // Keep the challenge visible on persistence or cleanup failure.
            try? await publish(prepare: false)
        }
    }

    func tick() async {
        guard let current, case let .memory(_, digits, _, deadline, _, _) = current.content,
              digits != nil, let deadline, clock() >= deadline else { return }
        await submit(.advanceTime, expecting: current)
    }

    func interrupt() async {
        guard let current, case .memory = current.content else { return }
        await submit(.interruptMemory, expecting: current)
    }

    func dismissCompleted() {
        guard current?.phase == .completed else { return }
        selectedSessionID = nil; current = nil; feedback = nil
    }

    #if DEBUG && targetEnvironment(simulator)
    func simulateQR(matches: Bool, expecting displayed: ChallengeSnapshot? = nil) async {
        guard supportsPreview, let current, current.phase == .active else { return }
        do {
            guard case let .loaded(snapshot, _) = try await repository.load(),
                  let record = snapshot.state.sessions.first(where: { $0.session.id == current.sessionID }),
                  case let .qr(configuration) = record.session.currentChallenge else { return }
            await submit(.scanQR(payload: matches ? configuration.expectedPayload : "puzzlealarm://challenge/other"), expecting: displayed ?? current)
        } catch { errorMessage = "Could not read the registered QR target. \(error)" }
    }
    #endif

    private func progress(_ snapshot: ChallengeSnapshot) -> Int {
        switch snapshot.content {
        case let .math(_, _, count, _), let .memory(_, _, _, _, count, _): count
        default: 0
        }
    }

    private func transition(_ command: ChallengeCommand) async throws {
        // Reapply an identity-bound command after a CAS conflict; a stale problem
        // or challenge cannot count twice. Publish only after the whole commit.
        for _ in 0..<3 {
            guard case let .loaded(snapshot, _) = try await repository.load(),
                  let index = snapshot.state.sessions.firstIndex(where: { $0.session.id == command.sessionID })
            else { throw DomainError.unknownAlarm }
            var state = snapshot.state
            let old = state.sessions[index]
            var updated = try coordinator.apply(command, to: old, at: clock())
            if updated.session.phase == .active {
                updated = try coordinator.apply(ChallengeCommand(sessionID: command.sessionID,
                    challengeIndex: updated.session.currentChallengeIndex, action: .prepare),
                    to: updated, at: clock())
            }
            if updated == old { return }
            state.sessions[index] = updated
            do {
                _ = try await repository.commit(state, expecting: snapshot.version)
                return
            } catch PersistenceError.conflict { continue }
        }
        throw LifecycleError.conflictLimit
    }

    private func publish(prepare: Bool) async throws {
        guard case let .loaded(snapshot, _) = try await repository.load() else { current = nil; return }
        let candidates = snapshot.state.sessions.sorted { $0.session.scheduledWakeUpDate < $1.session.scheduledWakeUpDate }
        nextWakeUpDate = candidates.first { [.armed, .degraded].contains($0.session.phase) }?.session.scheduledWakeUpDate
        let pending = UserDefaults.standard.string(forKey: "PuzzleAlarm.pendingOccurrenceID").flatMap(UUID.init(uuidString:))
        let actionable: (PersistedSession) -> Bool = { [.active, .completing, .cancellationPartiallyFailed].contains($0.session.phase) }
        let record = candidates.first { $0.session.id == pending && actionable($0) }
            ?? candidates.first { $0.session.id == selectedSessionID && actionable($0) }
            ?? candidates.first(where: actionable)
            ?? candidates.first { $0.session.id == selectedSessionID }
        UserDefaults.standard.removeObject(forKey: "PuzzleAlarm.pendingOccurrenceID")
        guard let record else { current = nil; return }
        selectedSessionID = record.session.id
        if prepare && record.session.phase == .active {
            try await transition(ChallengeCommand(sessionID: record.session.id,
                challengeIndex: record.session.currentChallengeIndex, action: .prepare))
            try await publish(prepare: false)
            return
        }
        current = try coordinator.snapshot(of: record, at: clock())
    }
}
