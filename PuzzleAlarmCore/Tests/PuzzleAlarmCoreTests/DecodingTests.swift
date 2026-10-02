import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func decodingRejectsFalseLifecycleStatesAndCorruptedLedgers() throws {
    let planned = try session()
    let invalidMutations: [(inout [String: Any]) -> Void] = [
        { $0["phase"] = "armed" },
        { $0["phase"] = "completed" },
        { $0["phase"] = "schedulingFailed" },
        { $0["phase"] = "unknown" },
        { $0["scheduling"] = [] },
        { $0["cancellation"] = ["notRequested"] },
        { $0["completedAt"] = 0 },
        { $0["createdAt"] = 9_000_000_000.0 }
    ]
    for mutate in invalidMutations {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(planned, mutate))
        }
    }
    let active = try activeSession()
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(active) {
            $0["cancellation"] = Array(repeating: "succeeded", count: 5)
        })
    }
    let solved = try solvedSession()
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(solved) { $0["phase"] = "active" })
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WakeUpSession.self, from: Data("{".utf8))
    }
    let decoded = try roundTrip(planned)
    #expect(decoded == planned)
}

@Test func decodedPlanCannotChangeOrdinalsOrDatesOrReuseIDs() throws {
    let plan = try session().plan
    for field in ["id", "date", "ordinal"] {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(BackupPlan.self, from: mutatedJSON(plan) { object in
                if var alarms = object["alarms"] as? [[String: Any]] {
                    alarms[1][field] = alarms[0][field]
                    object["alarms"] = alarms
                }
            })
        }
    }
}

@Test func decodedCompletionRequiresBothFullSequenceAndCancellation() throws {
    var value = try solvedSession()
    try cancelAll(&value)
    try value.finalizeCompletion(at: value.scheduledWakeUpDate)
    #expect(try roundTrip(value) == value)
    let mutations: [(inout [String: Any]) -> Void] = [
        { $0["challengeCompletedAt"] = [] },
        { $0.removeValue(forKey: "completedAt") },
        { $0["cancellation"] = Array(repeating: "inFlight", count: 5) },
        { $0["scheduling"] = Array(repeating: "planned", count: 5) },
        { $0["completedAt"] = 0 }
    ]
    for mutation in mutations {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WakeUpSession.self, from: mutatedJSON(value, mutation))
        }
    }
}
