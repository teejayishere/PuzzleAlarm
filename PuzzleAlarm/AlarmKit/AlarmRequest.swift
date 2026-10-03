import AlarmKit
import Foundation
import PuzzleAlarmCore

// Role is derived from the core ordinal, not a second independently stored value.
struct OccurrenceMetadata: AlarmMetadata {
    let sessionID: UUID
    let parentAlarmID: UUID
    let ordinal: Int
    var isPrimary: Bool { ordinal == 0 }
}

struct AlarmRequest: Sendable {
    let plannedAlarm: PlannedAlarm
    let metadata: OccurrenceMetadata

    init(session: WakeUpSession, alarmID: UUID) throws {
        guard let alarm = session.plan.alarms.first(where: { $0.id == alarmID }) else {
            throw DomainError.unknownAlarm
        }
        plannedAlarm = alarm
        metadata = OccurrenceMetadata(
            sessionID: session.id, parentAlarmID: session.parentAlarmID, ordinal: alarm.ordinal
        )
    }
}
