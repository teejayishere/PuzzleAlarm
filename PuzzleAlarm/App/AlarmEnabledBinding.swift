import SwiftUI
import PuzzleAlarmCore

@MainActor
enum AlarmEnabledBinding {
    static func make(for alarm: AlarmDefinition, store: AlarmStore) -> Binding<Bool> {
        Binding(get: { alarm.enabled }, set: { value in
            #if DEBUG
            UITestEnvironment.traceToggle("binding requested=\(value) captured=\(alarm.enabled) busy=\(store.isBusy)")
            #endif
            Task { await store.setEnabled(alarm, value) }
        })
    }
}
