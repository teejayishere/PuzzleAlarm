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
        await route(to: AppEnvironment.live)
        return .result()
    }

    @MainActor
    func route(to environment: AppEnvironment) async {
        await environment.openOccurrence(occurrenceID)
    }
}
