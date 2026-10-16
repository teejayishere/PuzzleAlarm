import SwiftUI
import PuzzleAlarmCore

@MainActor
enum AlarmEnabledBinding {
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
        Toggle("Alarm enabled", isOn: $input)
            .accessibilityIdentifier("alarm.enabled." + alarm.id.uuidString)
            .disabled(submitting || store.isBusy)
            .onChange(of: input) { _, value in
                guard !submitting, value != owner.wrappedValue else { return }
                submitting = true
                let command = AlarmEnabledBinding.make(for: alarm, store: store) {
                    // Also runs when access, persistence or scheduling fails, even
                    // if busy's true/false changes coalesce within one render.
                    input = owner.wrappedValue
                    submitting = false
                }
                command.wrappedValue = value
            }
            .onChange(of: owner.wrappedValue) { _, value in
                if !submitting { input = value }
            }
    }
}
