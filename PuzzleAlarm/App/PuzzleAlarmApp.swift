import SwiftUI

@main
struct PuzzleAlarmApp: App {
    @State private var environment = AppEnvironment.live
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            Group {
                if let failure = environment.failure {
                    ContentUnavailableView("Alarms unavailable", systemImage: "exclamationmark.triangle",
                                           description: Text(failure))
                } else if environment.ready, let store = environment.store {
                    ContentView(store: store)
                } else { ProgressView("Restoring alarms") }
            }
            .task { await environment.start() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await environment.foreground() }
                }
            }
        }
    }
}
