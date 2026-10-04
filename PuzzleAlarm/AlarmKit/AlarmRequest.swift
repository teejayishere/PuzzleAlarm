import AlarmKit
import Foundation
import PuzzleAlarmCore

struct OccurrenceMetadata: AlarmMetadata {
    let sessionID: UUID?
    let parentAlarmID: UUID
    let ordinal: Int
    var isPrimary: Bool { ordinal == 0 }
}

extension AlarmRequest {
    var metadata: OccurrenceMetadata {
        OccurrenceMetadata(sessionID: sessionID, parentAlarmID: parentAlarmID, ordinal: plannedAlarm.ordinal)
    }
}
