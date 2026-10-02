import Foundation

public enum SessionPhase: String, Codable, Sendable {
    case planned, scheduling, armed, active, completing, completed
    case schedulingFailed, cancellationPartiallyFailed, cancelling, cancelled
}

public enum SchedulingStatus: String, Codable, Sendable {
    case planned, inFlight, scheduled, failed
}

public enum CancellationStatus: String, Codable, Sendable {
    case notRequested, inFlight, succeeded, failed
}

// Stage 1 checkpoint model. Problem/round snapshots must be added and tested
// with the actual engines in Stages 8/9 before those features can be used.
public enum ChallengeProgress: Codable, Equatable, Sendable {
    case notStarted
    case math(correctAnswers: Int)
    case memory(successfulRounds: Int)
    case qrWaiting

    func validate(for configuration: ChallengeConfiguration) throws {
        switch (self, configuration) {
        case (.notStarted, _), (.qrWaiting, .qr): break
        case let (.math(count), .math(config)):
            try require((0..<config.requiredCorrect).contains(count), "Invalid math progress")
        case let (.memory(count), .memory(config)):
            try require((0..<config.requiredRounds).contains(count), "Invalid memory progress")
        default: throw DomainError.invalidConfiguration("Progress does not match current challenge")
        }
    }

    var count: Int {
        switch self {
        case let .math(count), let .memory(count): count
        default: 0
        }
    }
}

public struct WakeUpSession: Codable, Equatable, Sendable {
    public let id: UUID
    public let definitionSnapshot: AlarmDefinition
    public let context: ScheduleContext
    public let plan: BackupPlan
    public let createdAt: Date
    public private(set) var phase: SessionPhase
    public private(set) var scheduling: [SchedulingStatus]
    public private(set) var cancellation: [CancellationStatus]
    public private(set) var challengeCompletedAt: [Date]
    public private(set) var progress: ChallengeProgress
    public private(set) var completedAt: Date?

    public var parentAlarmID: UUID { definitionSnapshot.id }
    public var currentChallengeIndex: Int { challengeCompletedAt.count }
    public var scheduledWakeUpDate: Date { plan.alarms[0].date }
    public var primaryAlarmID: UUID { plan.alarms[0].id }
    public var backupAlarmIDs: [UUID] { plan.alarms.dropFirst().map(\.id) }
    public var scheduledAlarmIDs: [UUID] {
        plan.alarms.indices.filter { scheduling[$0] == .scheduled }.map { plan.alarms[$0].id }
    }
    public var uncertainAlarmIDs: [UUID] {
        plan.alarms.indices.filter { scheduling[$0] == .inFlight }.map { plan.alarms[$0].id }
    }
    public var remainingCancellationIDs: [UUID] {
        plan.alarms.indices.filter { cancellation[$0] != .succeeded }.map { plan.alarms[$0].id }
    }
    public var currentChallenge: ChallengeConfiguration? {
        let items = definitionSnapshot.challengeSequence.items
        return items.indices.contains(currentChallengeIndex) ? items[currentChallengeIndex] : nil
    }

    public init(
        id: UUID, definition: AlarmDefinition, context: ScheduleContext,
        plan: BackupPlan, createdAt: Date
    ) throws {
        self.id = id
        definitionSnapshot = definition
        self.context = context
        self.plan = plan
        self.createdAt = createdAt
        phase = .planned
        scheduling = Array(repeating: .planned, count: 5)
        cancellation = Array(repeating: .notRequested, count: 5)
        challengeCompletedAt = []
        progress = .notStarted
        completedAt = nil
        try validate()
    }

    public mutating func beginScheduling() throws {
        guard phase == .planned || phase == .scheduling else { throw DomainError.invalidTransition }
        phase = .scheduling
    }

    // Persist inFlight BEFORE an external scheduling call. After a crash, query
    // the scheduler for this stable ID before retrying; domain logic performs no IO.
    @discardableResult
    public mutating func beginScheduleAttempt(id: UUID) throws -> Bool {
        guard phase == .scheduling else { throw DomainError.invalidTransition }
        let index = try index(of: id)
        guard scheduling[index] == .planned else { return false }
        scheduling[index] = .inFlight
        return true
    }

    public mutating func recordScheduled(id: UUID) throws {
        guard phase == .scheduling else { throw DomainError.invalidTransition }
        let index = try index(of: id)
        if scheduling[index] == .scheduled { return }
        guard scheduling[index] == .inFlight else { throw DomainError.invalidTransition }
        scheduling[index] = .scheduled
    }

    public mutating func recordScheduleFailure(id: UUID) throws {
        guard phase == .scheduling else { throw DomainError.invalidTransition }
        let index = try index(of: id)
        guard scheduling[index] == .inFlight else { throw DomainError.invalidTransition }
        scheduling[index] = .failed
        phase = .schedulingFailed
    }

    public mutating func arm() throws {
        if phase == .armed { return }
        guard phase == .scheduling && scheduling.allSatisfy({ $0 == .scheduled })
        else { throw DomainError.invalidTransition }
        phase = .armed
    }

    public mutating func activate(at date: Date) throws {
        try validateDate(date)
        guard date >= scheduledWakeUpDate else { throw DomainError.invalidTransition }
        if phase == .active { return }
        guard phase == .armed else { throw DomainError.invalidTransition }
        phase = .active
    }

    public mutating func recordProgress(_ replacement: ChallengeProgress) throws {
        guard phase == .active, let currentChallenge else { throw DomainError.invalidTransition }
        try replacement.validate(for: currentChallenge)
        try require(replacement.count >= progress.count, "Progress cannot regress")
        progress = replacement
    }

    // A trusted challenge engine/coordinator supplies this event after it verifies
    // success. It is not an answer-validation API and must not be called by views.
    @discardableResult
    public mutating func recordChallengeSuccess(expectedIndex: Int, at date: Date) throws -> Bool {
        try validateDate(date)
        guard expectedIndex >= 0 else { throw DomainError.outOfOrder }
        if expectedIndex < currentChallengeIndex { return false }
        guard phase == .active && expectedIndex == currentChallengeIndex else { throw DomainError.outOfOrder }
        try require(date >= (challengeCompletedAt.last ?? scheduledWakeUpDate), "Success timestamp regressed")
        challengeCompletedAt.append(date)
        progress = .notStarted
        if currentChallengeIndex == definitionSnapshot.challengeSequence.items.count { phase = .completing }
        return true
    }

    // Retiring a future occurrence is distinct from solving its challenges.
    public mutating func requestRetirement() throws {
        if phase == .cancelling || phase == .cancelled { return }
        guard [.planned, .scheduling, .armed, .schedulingFailed].contains(phase)
        else { throw DomainError.invalidTransition }
        phase = .cancelling
    }

    @discardableResult
    public mutating func beginCancellation(id: UUID) throws -> Bool {
        guard [.completing, .cancellationPartiallyFailed, .schedulingFailed, .cancelling].contains(phase)
        else { throw DomainError.invalidTransition }
        let index = try index(of: id)
        guard cancellation[index] != .succeeded && cancellation[index] != .inFlight else { return false }
        cancellation[index] = .inFlight
        return true
    }

    public mutating func recordCancellation(id: UUID, succeeded: Bool) throws {
        guard [.completing, .cancellationPartiallyFailed, .schedulingFailed, .cancelling].contains(phase)
        else { throw DomainError.invalidTransition }
        let index = try index(of: id)
        if cancellation[index] == .succeeded {
            guard succeeded else { throw DomainError.invalidTransition }
            return
        }
        guard cancellation[index] == .inFlight else { throw DomainError.invalidTransition }
        cancellation[index] = succeeded ? .succeeded : .failed
        if !succeeded && phase == .completing { phase = .cancellationPartiallyFailed }
    }

    public mutating func finalizeCompletion(at date: Date) throws {
        try validateDate(date)
        if phase == .completed { return }
        guard [.completing, .cancellationPartiallyFailed].contains(phase),
              currentChallengeIndex == definitionSnapshot.challengeSequence.items.count,
              cancellation.allSatisfy({ $0 == .succeeded })
        else { throw DomainError.invalidTransition }
        try require(date >= (challengeCompletedAt.last ?? scheduledWakeUpDate), "Completion timestamp regressed")
        phase = .completed
        completedAt = date
    }

    public mutating func finishRetirement() throws {
        if phase == .cancelled { return }
        guard [.cancelling, .schedulingFailed].contains(phase),
              cancellation.allSatisfy({ $0 == .succeeded })
        else { throw DomainError.invalidTransition }
        phase = .cancelled
    }

    private func index(of id: UUID) throws -> Int {
        guard let index = plan.alarms.firstIndex(where: { $0.id == id }) else { throw DomainError.unknownAlarm }
        return index
    }

    private func validate() throws {
        try plan.validate()
        try validateDate(createdAt)
        try require(definitionSnapshot.enabled && definitionSnapshot.dismissalMode == .challengesRequired,
                    "Only enabled challenge alarms create sessions")
        try require(createdAt >= definitionSnapshot.updatedAt && createdAt <= scheduledWakeUpDate,
                    "Invalid session creation time")
        try require(scheduling.count == 5 && cancellation.count == 5, "Invalid operation ledger size")
        let count = definitionSnapshot.challengeSequence.items.count
        try require((0...count).contains(currentChallengeIndex), "Invalid challenge index")
        for (index, date) in challengeCompletedAt.enumerated() {
            try validateDate(date)
            try require(date >= (index == 0 ? scheduledWakeUpDate : challengeCompletedAt[index - 1]),
                        "Invalid challenge completion time")
        }
        if let currentChallenge { try progress.validate(for: currentChallenge) }
        else { try require(progress == .notStarted, "Progress after final challenge") }
        let completionPhases: [SessionPhase] = [.completing, .cancellationPartiallyFailed, .completed]
        if completionPhases.contains(phase) {
            try require(currentChallengeIndex == count, "Completion without full sequence")
        } else {
            try require(currentChallengeIndex < count, "Full sequence in non-completion phase")
        }
        if [.armed, .active, .completing, .cancellationPartiallyFailed, .completed].contains(phase) {
            try require(scheduling.allSatisfy { $0 == .scheduled }, "False armed state")
        }
        if phase == .planned { try require(scheduling.allSatisfy { $0 == .planned }, "Scheduled planned session") }
        if phase == .scheduling { try require(!scheduling.contains(.failed), "Failed scheduling without failure phase") }
        if phase == .schedulingFailed { try require(scheduling.contains(.failed), "Failure phase without failure") }
        if phase != .active && !completionPhases.contains(phase) {
            try require(currentChallengeIndex == 0 && progress == .notStarted, "Progress before activation")
        }
        if [.planned, .scheduling, .armed, .active].contains(phase) {
            try require(cancellation.allSatisfy { $0 == .notRequested }, "Premature cancellation")
        }
        if phase == .completing {
            try require(!cancellation.contains(.failed), "Failed cancellation without failure phase")
        }
        if phase == .completed || phase == .cancelled {
            try require(cancellation.allSatisfy { $0 == .succeeded }, "Unresolved terminal cancellation")
        }
        if phase == .completed {
            guard let completedAt else { throw DomainError.invalidConfiguration("Missing completion timestamp") }
            try validateDate(completedAt)
            try require(completedAt >= (challengeCompletedAt.last ?? scheduledWakeUpDate), "Invalid completion timestamp")
        } else { try require(completedAt == nil, "Premature completion timestamp") }
    }

    private enum CodingKeys: String, CodingKey {
        case id, definitionSnapshot, context, plan, createdAt, phase, scheduling
        case cancellation, challengeCompletedAt, progress, completedAt
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        definitionSnapshot = try c.decode(AlarmDefinition.self, forKey: .definitionSnapshot)
        context = try c.decode(ScheduleContext.self, forKey: .context)
        plan = try c.decode(BackupPlan.self, forKey: .plan)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        phase = try c.decode(SessionPhase.self, forKey: .phase)
        scheduling = try c.decode([SchedulingStatus].self, forKey: .scheduling)
        cancellation = try c.decode([CancellationStatus].self, forKey: .cancellation)
        challengeCompletedAt = try c.decode([Date].self, forKey: .challengeCompletedAt)
        progress = try c.decode(ChallengeProgress.self, forKey: .progress)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        try validate()
    }
}
