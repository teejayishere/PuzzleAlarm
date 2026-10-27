import SwiftUI
import Observation
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

// Only an in-flight request is local. Idle presentation always reads the current
// owner by stable identity, including external changes and removal.
@MainActor
@Observable
final class AlarmEnabledInput {
    private let alarm: AlarmDefinition
    private let store: AlarmStore
    private var requested: Bool?

    init(alarm: AlarmDefinition, store: AlarmStore) {
        self.alarm = alarm
        self.store = store
    }

    var value: Bool { requested ?? store.definition(alarm.id)?.enabled ?? false }
    var isSubmitting: Bool { requested != nil }
    var isEnabled: Bool { !isSubmitting && !store.isBusy && store.definition(alarm.id) != nil }

    var binding: Binding<Bool> {
        Binding(get: { self.value }, set: { value in
            guard self.isEnabled, value != self.value else { return }
            self.requested = value
            let command = AlarmEnabledBinding.make(for: self.alarm, store: self.store) {
                // The owner reconciles success, denial and partial failure before
                // returning. Dropping the request exposes that exact outcome.
                self.requested = nil
            }
            command.wrappedValue = value
        })
    }
}

struct AlarmEnabledToggle: View {
    @State private var input: AlarmEnabledInput
    private let identifier: String

    init(alarm: AlarmDefinition, store: AlarmStore) {
        _input = State(initialValue: AlarmEnabledInput(alarm: alarm, store: store))
        identifier = "alarm.enabled." + alarm.id.uuidString
    }

    var body: some View {
        Toggle("Alarm enabled", isOn: input.binding)
            .toggleStyle(.switch)
            .disabled(!input.isEnabled)
            .accessibilityIdentifier(identifier)
    }
}
