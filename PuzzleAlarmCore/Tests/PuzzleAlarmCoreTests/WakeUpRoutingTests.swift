import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func wakeUpRoutingExcludesFutureUnactivatedAndTerminalSessions() throws {
    let active = try activeSession()
    let now = active.scheduledWakeUpDate
    func route(_ value: WakeUpSession, at date: Date) throws -> UUID? {
        WakeUpRouting.sessionID(in: try RepositoryState(sessions: [PersistedSession(session: value, updatedAt: now)]), at: date)
    }
    #expect(try route(active, at: now) == active.id)
    #expect(try route(active, at: now.addingTimeInterval(-1)) == nil)
    #expect(try route(active, at: Date(timeIntervalSince1970: .nan)) == nil)
    #expect(try route(armedSession(), at: now) == nil)
    var solved = try solvedSession()
    #expect(try route(solved, at: now) == nil)
    try cancelAll(&solved)
    try solved.finalizeCompletion(at: now)
    #expect(try route(solved, at: now) == nil)
    #expect(WakeUpRouting.sessionID(in: try RepositoryState(), at: now) == nil)
}

@Test func wakeUpRoutingMultipleSessionsUsesDateThenStableIDRegardlessOfStorageOrder() throws {
    let original = try activeSession()
    func another(_ id: UInt8, offset: TimeInterval) throws -> PersistedSession {
        var value = try WakeUpSession(id: uuid(id), definition: original.definitionSnapshot,
            context: original.context, plan: BackupPlan(at: original.scheduledWakeUpDate.addingTimeInterval(offset),
                ids: (0..<5).map { uuid(id + UInt8($0) + 10) }), createdAt: original.createdAt)
        try value.beginScheduling()
        for alarm in value.plan.alarms { try value.beginScheduleAttempt(id: alarm.id); try value.recordScheduled(id: alarm.id) }
        try value.arm(); try value.activate(at: value.scheduledWakeUpDate)
        return try PersistedSession(session: value, updatedAt: value.scheduledWakeUpDate)
    }
    let a = try another(30, offset: 0)
    let b = try another(50, offset: 0)
    let c = try another(70, offset: -60)
    let now = original.scheduledWakeUpDate
    for records in [[a, b], [b, a]] {
        #expect(WakeUpRouting.sessionID(in: try RepositoryState(sessions: records), at: now) == a.session.id)
    }
    for records in [[a, c, b], [b, a, c]] {
        #expect(WakeUpRouting.sessionID(in: try RepositoryState(sessions: records), at: now) == c.session.id)
    }
}
