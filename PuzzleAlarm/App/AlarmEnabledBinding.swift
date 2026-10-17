import SwiftUI
import PuzzleAlarmCore

@MainActor
enum AlarmEnabledBinding {
    // Treat native setter delivery as the event boundary. Render-time onChange
    // observes presentation; it must not be the only way to submit a command.
    static func input(for alarm: AlarmDefinition, store: AlarmStore,
                      presentation: Binding<Bool>, submitting: Binding<Bool>) -> Binding<Bool> {
        let owner = make(for: alarm, store: store)
        return Binding(get: { presentation.wrappedValue }, set: { value in
            #if DEBUG
            UITestEnvironment.traceToggle("native setter=\(value) submitting=\(submitting.wrappedValue) owner=\(owner.wrappedValue)")
            #endif
            guard !submitting.wrappedValue, value != owner.wrappedValue else { return }
            presentation.wrappedValue = value
            submitting.wrappedValue = true
            let command = make(for: alarm, store: store) {
                presentation.wrappedValue = owner.wrappedValue
                submitting.wrappedValue = false
            }
            command.wrappedValue = value
        })
    }

    static func make(for alarm: AlarmDefinition, store: AlarmStore,
                     completed: @escaping @MainActor () -> Void = {}) -> Binding<Bool> {
        // A native control may retain this binding across owner updates to the
        // same row. Its getter must read live authoritative state, not a snapshot.
        Binding(get: { store.definition(alarm.id)?.enabled ?? false }, set: { value in
            #if DEBUG
            UITestEnvironment.traceToggle("binding requested=\(value) captured=\(alarm.enabled) busy=\(store.isBusy)")
            #endif
            Task { await store.setEnabled(alarm, value); completed() }
        })
    }
}

// A native Toggle edits synchronous presentation state, like the alarm editor.
// The store remains the only authority for durable configuration and OS effects.
struct AlarmEnabledToggle: View {
    let alarm: AlarmDefinition
    let store: AlarmStore
    @State private var input: Bool
    @State private var submitting = false

    init(alarm: AlarmDefinition, store: AlarmStore) {
        self.alarm = alarm; self.store = store
        _input = State(initialValue: store.definition(alarm.id)?.enabled ?? false)
    }

    private var owner: Binding<Bool> { AlarmEnabledBinding.make(for: alarm, store: store) }

    var body: some View {
        Toggle("Alarm enabled", isOn: AlarmEnabledBinding.input(for: alarm, store: store,
            presentation: $input, submitting: $submitting))
            .accessibilityIdentifier("alarm.enabled." + alarm.id.uuidString)
            .disabled(submitting || store.isBusy)
            .onChange(of: owner.wrappedValue) { _, value in
                if !submitting { input = value }
            }
    }
}
