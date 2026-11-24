import AppIntents
import Foundation

struct OpenOccurrenceIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Solve PuzzleAlarm" }
    static var supportedModes: IntentModes { .foreground }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Wake-up occurrence")
    var occurrenceID: String

    init() {}

    init(occurrenceID: UUID) {
        self.occurrenceID = occurrenceID.uuidString
    }

    func perform() async throws -> some IntentResult {
        // Persist the routing hint before notifying a running foreground app.
        // It selects an existing due session; it never creates or completes one.
        if let id = UUID(uuidString: occurrenceID) {
            UserDefaults.standard.set(id.uuidString, forKey: "PuzzleAlarm.pendingOccurrenceID")
            NotificationCenter.default.post(name: Notification.Name("PuzzleAlarm.openOccurrence"), object: nil)
        }
        return .result()
    }
}
