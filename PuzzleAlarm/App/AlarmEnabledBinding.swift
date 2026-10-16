import SwiftUI
import PuzzleAlarmCore

@MainActor
enum AlarmEnabledBinding {
    static func make(for alarm: AlarmDefinition, store: AlarmStore) -> Binding<Bool> {
        // A native control may retain this binding across owner updates to the
        // same row. Its getter must read live authoritative state, not a snapshot.
        Binding(get: { store.definition(alarm.id)?.enabled ?? false }, set: { value in
            #if DEBUG
            UITestEnvironment.traceToggle("binding requested=\(value) captured=\(alarm.enabled) busy=\(store.isBusy)")
            #endif
            Task { await store.setEnabled(alarm, value) }
        })
    }
}
