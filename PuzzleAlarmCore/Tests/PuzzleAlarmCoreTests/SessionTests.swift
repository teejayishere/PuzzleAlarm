import Foundation
import Testing
@testable import PuzzleAlarmCore

private let permutations = [
    [0], [1], [2], [0, 1], [1, 0], [0, 2], [2, 0], [1, 2], [2, 1],
    [0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]
]

@Test(arguments: permutations)
private func everyAllowedSequenceRequiresOrderedSuccess(_ order: [Int]) throws {
    let configs = try configurations()
    var value = try activeSession(sequence: order.map { configs[$0] })
    #expect(value.currentChallengeIndex == 0)
    #expect(value.completedAt == nil)
    for index in order.indices {
        let before = value
        #expect(throws: DomainError.outOfOrder) {
            try value.recordChallengeSuccess(expectedIndex: index + 1, at: value.scheduledWakeUpDate)
        }
        #expect(value == before)
        #expect(value.currentChallenge == configs[order[index]])
        #expect(try value.recordChallengeSuccess(expectedIndex: index, at: value.scheduledWakeUpDate))
        #expect(!(try value.recordChallengeSuccess(expectedIndex: index, at: value.scheduledWakeUpDate)))
        #expect(value.currentChallengeIndex == index + 1)
        #expect(value.cancellation.allSatisfy { $0 == .notRequested })
        #expect(value.completedAt == nil)
        #expect(try roundTrip(value) == value)
        if index < order.count - 1 {
            #expect(value.phase == .active)
            #expect(throws: DomainError.self) { try value.beginCancellation(id: value.primaryAlarmID) }
            #expect(throws: DomainError.self) { try value.finalizeCompletion(at: value.scheduledWakeUpDate) }
        }
    }
    #expect(value.phase == .completing)
    #expect(value.currentChallenge == nil)
    try cancelAll(&value)
    try value.finalizeCompletion(at: value.scheduledWakeUpDate)
    let terminal = value
    try value.finalizeCompletion(at: value.scheduledWakeUpDate.addingTimeInterval(60))
    #expect(value == terminal)
    #expect(value.phase == .completed)
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.activate(at: value.scheduledWakeUpDate) }
    #expect(throws: DomainError.self) { try value.beginScheduling() }
    #expect(throws: DomainError.self) { try value.requestRetirement() }
}

@Test func schedulingMustBeCompleteBeforeArmingAndMayRestoreInFlight() throws {
    var value = try session()
    #expect(value.phase == .planned)
    #expect(value.scheduledAlarmIDs.isEmpty)
    #expect(value.backupAlarmIDs.count == 4)
    #expect(throws: DomainError.self) { try value.arm() }
    try value.beginScheduling()
    try value.beginScheduling()
    for (index, item) in value.plan.alarms.enumerated() {
        #expect(throws: DomainError.self) { try value.recordScheduled(id: item.id) }
        #expect(try value.beginScheduleAttempt(id: item.id))
        #expect(!(try value.beginScheduleAttempt(id: item.id)))
        #expect(value.uncertainAlarmIDs == [item.id])
        value = try roundTrip(value)
        #expect(value.phase == .scheduling)
        #expect(throws: DomainError.self) { try value.arm() }
        try value.recordScheduled(id: item.id)
        try value.recordScheduled(id: item.id)
        #expect(value.scheduledAlarmIDs.count == index + 1)
    }
    try value.arm()
    try value.arm()
    #expect(value.phase == .armed)
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.activate(at: value.scheduledWakeUpDate.addingTimeInterval(-1)) }
    #expect(throws: DomainError.self) {
        try value.recordChallengeSuccess(expectedIndex: 0, at: value.scheduledWakeUpDate)
    }
    try value.activate(at: value.scheduledWakeUpDate)
    try value.activate(at: value.scheduledWakeUpDate)
    #expect(value.phase == .active)
}

@Test(arguments: [0, 1, 2, 3, 4])
func partialScheduleFailureIsNeverArmedAndRetainsRollbackEvidence(_ failedIndex: Int) throws {
    var value = try session()
    try value.beginScheduling()
    for index in 0...failedIndex {
        let id = value.plan.alarms[index].id
        try value.beginScheduleAttempt(id: id)
        if index == failedIndex { try value.recordScheduleFailure(id: id) }
        else { try value.recordScheduled(id: id) }
    }
    #expect(value.phase == .schedulingFailed)
    #expect(value.scheduledAlarmIDs.count == failedIndex)
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.arm() }
    #expect(throws: DomainError.self) { try value.beginScheduling() }
    // Include all planned IDs when reconciling: some may have unknown OS outcomes.
    #expect(value.remainingCancellationIDs.count == 5)
    let failedID = value.primaryAlarmID
    try value.beginCancellation(id: failedID)
    try value.recordCancellation(id: failedID, succeeded: false)
    #expect(value.phase == .schedulingFailed)
    #expect(value.cancellation[0] == .failed)
    #expect(try roundTrip(value) == value)
    try cancelAll(&value)
    try value.finishRetirement()
    #expect(value.phase == .cancelled)
    #expect(value.completedAt == nil)
    #expect(value.currentChallengeIndex == 0)
    #expect(try roundTrip(value) == value)
}

@Test(arguments: [0, 1, 2, 3, 4])
func cancellationFailureContinuesAndRelaunchResumes(_ failedIndex: Int) throws {
    var value = try solvedSession()
    for (index, item) in value.plan.alarms.enumerated() {
        try value.beginCancellation(id: item.id)
        #expect(try roundTrip(value) == value)
        try value.recordCancellation(id: item.id, succeeded: index != failedIndex)
    }
    #expect(value.phase == .cancellationPartiallyFailed)
    #expect(value.remainingCancellationIDs == [value.plan.alarms[failedIndex].id])
    #expect(value.completedAt == nil)
    #expect(throws: DomainError.self) { try value.finalizeCompletion(at: value.scheduledWakeUpDate) }
    value = try roundTrip(value)
    let pending = value.remainingCancellationIDs[0]
    #expect(try value.beginCancellation(id: pending))
    #expect(!(try value.beginCancellation(id: pending)))
    value = try roundTrip(value)
    // After reconciliation confirms the cancellation, record the outcome.
    try value.recordCancellation(id: pending, succeeded: true)
    try value.recordCancellation(id: pending, succeeded: true)
    #expect(!(try value.beginCancellation(id: pending)))
    #expect(throws: DomainError.self) { try value.recordCancellation(id: pending, succeeded: false) }
    try value.finalizeCompletion(at: value.scheduledWakeUpDate)
    #expect(value.phase == .completed)
    #expect(try roundTrip(value) == value)
}

@Test func snapshotRemainsStableAcrossParentEditsAndDisable() throws {
    let value = try session()
    let original = value.definitionSnapshot
    let edited = try original.replacing(
        time: AlarmTime(hour: 9, minute: 0), weekdays: [.sunday], enabled: false,
        mode: .annoyingOnly, challenges: ChallengeSequence([]), sound: .bundled(.rapidBeeps),
        at: value.createdAt
    )
    #expect(edited.id == original.id)
    #expect(value.definitionSnapshot == original)
    #expect(value.definitionSnapshot.challengeSequence.items.count == 3)
    #expect(value.definitionSnapshot.selectedSound == .systemDefault)
    #expect(throws: DomainError.self) {
        try WakeUpSession(id: uuid(3), definition: edited, context: value.context,
                          plan: value.plan, createdAt: value.createdAt)
    }
}

@Test func retiringFutureSessionNeverCountsAsChallengeCompletion() throws {
    var value = try armedSession()
    try value.requestRetirement()
    try value.requestRetirement()
    #expect(value.phase == .cancelling)
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.finishRetirement() }
    try cancelAll(&value)
    try value.finishRetirement()
    try value.finishRetirement()
    #expect(value.phase == .cancelled && value.completedAt == nil)
    #expect(value.currentChallengeIndex == 0)
    var active = try activeSession()
    #expect(throws: DomainError.self) { try active.requestRetirement() }
}

@Test func challengeSpecificProgressRoundTripsAndCannotSkipOrRegress() throws {
    var value = try activeSession()
    try value.recordProgress(.math(correctAnswers: 2))
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.recordProgress(.math(correctAnswers: 1)) }
    #expect(throws: DomainError.self) { try value.recordProgress(.math(correctAnswers: 5)) }
    #expect(throws: DomainError.self) { try value.recordProgress(.memory(successfulRounds: 1)) }
    #expect(value.currentChallengeIndex == 0)
    try value.recordChallengeSuccess(expectedIndex: 0, at: value.scheduledWakeUpDate)
    #expect(value.progress == .notStarted)
    try value.recordProgress(.memory(successfulRounds: 2))
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.recordProgress(.memory(successfulRounds: 3)) }
    try value.recordChallengeSuccess(expectedIndex: 1, at: value.scheduledWakeUpDate)
    try value.recordProgress(.qrWaiting)
    #expect(try roundTrip(value) == value)
    #expect(throws: DomainError.self) { try value.recordProgress(.math(correctAnswers: 0)) }
}

@Test func unknownIDsAndRegressingDatesDoNotMutateSession() throws {
    var value = try session()
    try value.beginScheduling()
    let original = value
    #expect(throws: DomainError.unknownAlarm) { try value.beginScheduleAttempt(id: uuid(200)) }
    #expect(value == original)
    var active = try activeSession()
    let before = active
    #expect(throws: DomainError.self) {
        try active.recordChallengeSuccess(expectedIndex: 0, at: active.scheduledWakeUpDate.addingTimeInterval(-1))
    }
    #expect(active == before)
    #expect(throws: DomainError.self) {
        try active.recordChallengeSuccess(expectedIndex: -1, at: active.scheduledWakeUpDate)
    }
}
