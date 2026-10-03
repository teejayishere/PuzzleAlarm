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
        // Stage 3: the system opens the app. Routing and persistence are Stage 12.
        // Opening or stopping an alarm never implies challenge completion.
        .result()
    }
}
