import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func scheduleFailureKeepsConcurrentUnknownOutcomeForReconciliation() throws {
    var value = try session()
    try value.beginScheduling()
    let first = value.plan.alarms[0].id
    let second = value.plan.alarms[1].id
    try value.beginScheduleAttempt(id: first)
    try value.beginScheduleAttempt(id: second)
    try value.recordScheduleFailure(id: first)
    value = try roundTrip(value)
    #expect(value.uncertainAlarmIDs == [second])
    #expect(value.scheduledAlarmIDs.isEmpty)
    #expect(value.remainingCancellationIDs.contains(second))
    #expect(throws: DomainError.self) { try value.arm() }
    try cancelAll(&value)
    try value.finishRetirement()
    #expect(value.phase == .cancelled)
    #expect(value.completedAt == nil)
}

@Test func sessionCannotSnapshotAnEditFromAfterItsCreation() throws {
    let original = try session()
    let edited = try original.definitionSnapshot.settingEnabled(
        true, at: original.createdAt.addingTimeInterval(60)
    )
    #expect(throws: DomainError.self) {
        try WakeUpSession(id: uuid(3), definition: edited, context: original.context,
                          plan: original.plan, createdAt: original.createdAt)
    }
}

@Test func corruptPartialProgressCannotBeAcceptedDuringRestore() throws {
    var active = try activeSession()
    try active.recordProgress(.math(correctAnswers: 2))
    for count in [-1, 5, Int.max] {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(active) {
                $0["progress"] = ["math": ["correctAnswers": count]]
            })
        }
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(active) {
            $0["progress"] = ["memory": ["successfulRounds": 0]]
        })
    }
}

@Test func extremeDatesAndNonFiniteInstantsAreRejectedBeforeCalendarUse() throws {
    let alarm = try definition()
    let context = try ScheduleContext(timeZoneIdentifier: "UTC")
    for interval in [Double.nan, .infinity, -.infinity, .greatestFiniteMagnitude] {
        #expect(throws: DomainError.self) {
            try OccurrenceCalculator.next(for: alarm, after: Date(timeIntervalSince1970: interval), context: context)
        }
    }
}

@Test func completionAndProgressTimestampsCannotRegress() throws {
    var value = try activeSession()
    let first = value.scheduledWakeUpDate.addingTimeInterval(60)
    try value.recordChallengeSuccess(expectedIndex: 0, at: first)
    let checkpoint = value
    #expect(throws: DomainError.self) {
        try value.recordChallengeSuccess(expectedIndex: 1, at: first.addingTimeInterval(-1))
    }
    #expect(value == checkpoint)
    try value.recordChallengeSuccess(expectedIndex: 1, at: first)
    try value.recordChallengeSuccess(expectedIndex: 2, at: first)
    try cancelAll(&value)
    #expect(throws: DomainError.self) { try value.finalizeCompletion(at: first.addingTimeInterval(-1)) }
    #expect(value.phase == .completing)
    try value.finalizeCompletion(at: first)
    #expect(value.completedAt == first)
}
