import SwiftUI

@main
struct PuzzleAlarmApp: App {
    @State private var environment = AppEnvironment.make()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            Group {
                if let failure = environment.failure {
                    ContentUnavailableView("Alarms unavailable", systemImage: "exclamationmark.triangle",
                                           description: Text(failure))
                } else if let store = environment.store {
                    ContentView(store: store)
                }
            }
            .task { await environment.start() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && environment.ready {
                    Task { await environment.store?.refresh() }
                }
            }
        }
    }
}
