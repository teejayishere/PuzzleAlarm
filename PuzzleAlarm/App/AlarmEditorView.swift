import SwiftUI
import PuzzleAlarmCore

struct AlarmEditorView: View {
    @Bindable var store: AlarmStore
    @State private var draft: AlarmEditorDraft
    @State private var localError: String?
    @State private var confirmingDelete = false
    @Environment(\.dismiss) private var dismiss
    init(store: AlarmStore, initial: AlarmEditorDraft) {
        self.store = store; _draft = State(initialValue: initial)
    }
    var body: some View {
        NavigationStack {
            Form {
                if let message = localError ?? store.errorMessage {
                    Section("Needs attention") {
                        Text(message).accessibilityIdentifier("editor.error")
                        if store.editWasSuperseded {
                            Button("Reload Alarm") {
                                if let value = store.definition(draft.id) {
                                    draft = AlarmEditorDraft(value); localError = nil; store.clearError()
                                }
                            }.accessibilityIdentifier("editor.reload")
                        }
                        if let value = store.definition(draft.id), store.canRetry(value) {
                            Button("Retry") { Task {
                                await store.retry(value.id)
                                if let current = store.definition(value.id), !store.needsAttention(current) { localError = nil }
                            } }.accessibilityIdentifier("editor.retry")
                        }
                    }
                }
                Section("Time") {
                    DatePicker("Time", selection: $draft.pickerDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel).environment(\.timeZone, AlarmFormatting.wallCalendar.timeZone)
                        .accessibilityIdentifier("editor.time")
                    Toggle("Alarm enabled", isOn: $draft.enabled).accessibilityIdentifier("editor.enabled")
                    NavigationLink {
                        WeekdayEditor(days: $draft.weekdays)
                    } label: {
                        LabeledContent("Repeat", value: AlarmFormatting.repeatSummary(draft.weekdays))
                    }.accessibilityIdentifier("editor.repeat")
                }
                Section("Dismissal") {
                    Picker("Dismissal mode", selection: Binding(get: { draft.mode }, set: { value in
                        change { try draft.setMode(value) }
                    })) {
                        Text("Annoying Alarm Only").tag(DismissalMode.annoyingOnly)
                        Text("Challenges Required").tag(DismissalMode.challengesRequired)
                    }.accessibilityIdentifier("editor.mode")
                    if let message = draft.validationMessage {
                        Text(message).foregroundStyle(.secondary).accessibilityIdentifier("editor.validation")
                    }
                }
                if draft.mode == .challengesRequired {
                    Section("Challenges in order") {
                        ForEach(Array(draft.sequence.items.enumerated()), id: \.element.kind) { index, configuration in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(index + 1). \(AlarmFormatting.challenge(configuration.kind))").font(.headline)
                                    .accessibilityIdentifier("challenge.order." + configuration.kind.rawValue)
                                if configuration.kind != .qr {
                                    NavigationLink("Configure " + AlarmFormatting.challenge(configuration.kind)) {
                                        ChallengeConfigurationEditor(configuration: configuration) { updated in
                                            change { try draft.replace(index, with: updated) }
                                        }
                                    }.accessibilityIdentifier("challenge.configure." + configuration.kind.rawValue)
                                }
                                Button("Move Up") { change { try draft.move(index, by: -1) } }
                                    .disabled(index == 0).accessibilityIdentifier("challenge.up." + configuration.kind.rawValue)
                                    .accessibilityLabel("Move " + AlarmFormatting.challenge(configuration.kind) + " up")
                                Button("Move Down") { change { try draft.move(index, by: 1) } }
                                    .disabled(index == draft.sequence.items.count - 1)
                                    .accessibilityIdentifier("challenge.down." + configuration.kind.rawValue)
                                    .accessibilityLabel("Move " + AlarmFormatting.challenge(configuration.kind) + " down")
                                Button("Remove", role: .destructive) { change { try draft.remove(index) } }
                                    .accessibilityIdentifier("challenge.remove." + configuration.kind.rawValue)
                                    .accessibilityLabel("Remove " + AlarmFormatting.challenge(configuration.kind))
                            }.buttonStyle(.borderless)
                        }
                        ForEach(ChallengeKind.allCases.filter { kind in !draft.sequence.items.contains { $0.kind == kind } },
                                id: \.self) { kind in
                            Button("Add " + AlarmFormatting.challenge(kind)) {
                                change { try draft.add(kind, token: store.newToken()) }
                            }.accessibilityIdentifier("challenge.add." + kind.rawValue)
                        }
                    }
                }
                Section("Sound") {
                    Picker("Sound", selection: $draft.sound) {
                        ForEach(SoundChoice.allCases) { sound in Text(sound.title).tag(sound) }
                    }.accessibilityIdentifier("editor.sound")
                }
                if draft.original != nil {
                    Section {
                        Button("Delete Alarm", role: .destructive) { confirmingDelete = true }
                            .accessibilityIdentifier("editor.delete")
                    }
                }
            }
            .navigationTitle(draft.original == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("editor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            localError = nil
                            switch await store.save(draft) {
                            case .saved: dismiss()
                            case let .attention(value):
                                draft = AlarmEditorDraft(value)
                                localError = "Your settings are saved, but the alarm needs attention. Review its status or retry."
                            case .failed: break
                            }
                        }
                    }.disabled(draft.validationMessage != nil).accessibilityIdentifier("editor.save")
                }
            }
            .disabled(store.isBusy)
            .interactiveDismissDisabled(store.isBusy)
            .alert("Delete this alarm?", isPresented: $confirmingDelete) {
                Button("Delete Alarm", role: .destructive) {
                    Task {
                        if await store.delete(draft.id) { dismiss() }
                        else { localError = store.errorMessage ?? "Deletion is waiting for cleanup or an unfinished wake-up session." }
                    }
                }.accessibilityIdentifier("editor.confirmDelete")
                Button("Keep Alarm", role: .cancel) {}.accessibilityIdentifier("editor.keep")
            }
        }
    }
    private func change(_ body: () throws -> Void) {
        do { try body(); localError = nil }
        catch { localError = AlarmFormatting.error(error) }
    }
}

struct WeekdayEditor: View {
    @Binding var days: Set<Weekday>
    var body: some View {
        List {
            Section {
                ForEach(AlarmFormatting.orderedDays, id: \.self) { day in
                    Button {
                        if days.contains(day) { days.remove(day) } else { days.insert(day) }
                    } label: {
                        HStack {
                            Text(AlarmFormatting.day(day))
                            Spacer()
                            if days.contains(day) { Image(systemName: "checkmark") }
                        }.frame(minHeight: 44)
                    }.accessibilityIdentifier("weekday." + String(day.rawValue))
                        .accessibilityValue(days.contains(day) ? "Selected" : "Not selected")
                }
            }
            Section {
                Button("Once") { days = [] }.accessibilityIdentifier("repeat.once")
                Button("Weekdays") { days = Set(AlarmFormatting.orderedDays.prefix(5)) }.accessibilityIdentifier("repeat.weekdays")
                Button("Weekends") { days = [.saturday, .sunday] }.accessibilityIdentifier("repeat.weekends")
                Button("Every day") { days = Set(Weekday.allCases) }.accessibilityIdentifier("repeat.everyday")
            }
        }.navigationTitle("Repeat")
    }
}
