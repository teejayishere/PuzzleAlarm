import SwiftUI
import PuzzleAlarmCore

struct AlarmEditorView: View {
    @State var draft: AlarmDraft
    @ObservedObject var model: AlarmListModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if let error = model.errorMessage { Text(error).foregroundStyle(.red) }
                Section {
                    DatePicker("Alarm time", selection: $draft.timeSelection, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.calendar, AlarmDraft.timePickerCalendar)
                        .environment(\.timeZone, AlarmDraft.timePickerCalendar.timeZone)
                        .accessibilityIdentifier("editor.time")
                } header: { Text("Time") }
                Section("Alarm") {
                    LabeledContent("Enabled") {
                        Toggle("Enabled", isOn: $draft.enabled).labelsHidden()
                            .accessibilityLabel("Enabled")
                            .accessibilityIdentifier("editor.enabled")
                    }
                }
                Section {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        LabeledContent(day.title) {
                            Toggle(day.title, isOn: Binding(get: { draft.weekdays.contains(day) }, set: { selected in
                                if selected { draft.weekdays.insert(day) } else { draft.weekdays.remove(day) }
                            })).labelsHidden()
                                .accessibilityLabel(day.title)
                                .accessibilityIdentifier("editor.day.\(day.rawValue)")
                        }
                    }
                } header: { Text("Repeat") } footer: { Text("No selected weekdays means one time at the next local occurrence.") }
                Section("Dismissal") {
                    Picker("Mode", selection: $draft.mode) {
                        Text("Alarm only").tag(DismissalMode.annoyingOnly)
                        Text("Challenges required").tag(DismissalMode.challengesRequired)
                    }.pickerStyle(.menu).accessibilityIdentifier("editor.mode")
                }
                if draft.mode == .challengesRequired { challengeSections }
                Section {
                    Picker("Sound", selection: $draft.soundIndex) {
                        ForEach(AlarmDraft.soundNames.indices, id: \.self) { index in
                            Text(AlarmDraft.soundNames[index]).tag(index)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("editor.sound")
                    SoundPreviewView(selection: AlarmDraft.sounds[draft.soundIndex])
                } header: { Text("Sound") } footer: {
                    Text("Preview a bundled sound before saving. Missing sound files fall back to the system default.")
                }
            }
            .navigationTitle(draft.original == nil ? "New alarm" : "Edit alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.accessibilityIdentifier("editor.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { if await model.save(draft) { dismiss() } } }
                        .disabled(!draft.canSave || !model.loaded || model.busy)
                        .accessibilityIdentifier("editor.save")
                }
            }
            .disabled(model.busy)
            .interactiveDismissDisabled(model.busy)
            .navigationTestState("id=\(draft.id); original=\(draft.original?.id.uuidString ?? "new"); mode=\(draft.mode.rawValue); hour=\(draft.hour); minute=\(draft.minute); weekdays=\(draft.weekdays.map(\.rawValue).sorted()); enabled=\(draft.enabled); soundIndex=\(draft.soundIndex); canSave=\(draft.canSave)" + draft.challengeTestState, context: "editor")
            .switchDiagnosticState("draft.id=\(draft.id); original.id=\(String(describing: draft.original?.id)); draft.enabled=\(draft.enabled); weekdays=\(draft.weekdays.map(\.rawValue).sorted()); busy=\(model.busy); loaded=\(model.loaded)", context: "editor")
        }
    }

    private var challengeSections: some View {
        Group {
            Section {
                ForEach(ChallengeKind.allCases, id: \.self) { kind in
                    Button("Add \(kind.title)") { draft.add(kind) }
                        .disabled(draft.challenges.contains { $0.kind == kind })
                        .accessibilityIdentifier("challenge.add.\(kind.rawValue)")
                }
                if draft.challenges.isEmpty { Text("Add at least one challenge to save.") }
            } header: { Text("Challenge sequence") } footer: {
                    Text("Each type can appear once. Complete them in the order shown.")
            }
            ForEach($draft.challenges) { $challenge in
                let kind = challenge.kind
                let index = draft.challenges.firstIndex(where: { $0.kind == kind }) ?? 0
                Section("\(index + 1). \(kind.title)") {
                    ChallengeConfigurationView(draft: $challenge)
                    HStack {
                        Button("Move up") { draft.move(index, by: -1) }
                            .disabled(index == 0)
                            .accessibilityLabel("Move \(kind.title) up")
                            .accessibilityIdentifier("challenge.up.\(kind.rawValue)")
                        Button("Move down") { draft.move(index, by: 1) }
                            .disabled(index == draft.challenges.count - 1)
                            .accessibilityLabel("Move \(kind.title) down")
                            .accessibilityIdentifier("challenge.down.\(kind.rawValue)")
                    }.buttonStyle(.borderless)
                    Button("Remove \(kind.title)", role: .destructive) {
                        draft.challenges.removeAll { $0.kind == kind }
                    }.accessibilityIdentifier("challenge.remove.\(kind.rawValue)")
                }
            }
        }
    }
}

private struct ChallengeConfigurationView: View {
    @Binding var draft: ChallengeDraft

    var body: some View {
        if draft.kind != .qr {
            Picker("Difficulty", selection: $draft.difficulty) {
                ForEach(Difficulty.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
            }.pickerStyle(.menu).accessibilityIdentifier("challenge.difficulty.\(draft.kind.rawValue)")
        }
        switch draft.kind {
        case .math:
            Stepper("Correct answers: \(draft.correctCount)", value: $draft.correctCount, in: 1...20)
                .accessibilityIdentifier("challenge.math.count")
        case .memory:
            Stepper("Sequence length: \(draft.length)", value: $draft.length, in: 2...12)
                .accessibilityIdentifier("challenge.memory.length")
            Stepper("Display seconds: \(draft.seconds.formatted())", value: $draft.seconds, in: 1...30, step: 1)
                .accessibilityIdentifier("challenge.memory.seconds")
            Stepper("Rounds: \(draft.rounds)", value: $draft.rounds, in: 1...20)
                .accessibilityIdentifier("challenge.memory.rounds")
        case .qr:
            Text("Target: \(QRConfiguration(token: draft.token).expectedPayload)")
                .textSelection(.enabled).accessibilityIdentifier("challenge.qr.target")
            QRTargetView(payload: QRConfiguration(token: draft.token).expectedPayload)
            Text("Save or share this code and place it where you want to scan it when you wake up.")
        }
    }
}
