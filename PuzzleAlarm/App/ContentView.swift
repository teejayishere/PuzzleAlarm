import SwiftUI
import PuzzleAlarmCore

struct ContentView: View {
    @ObservedObject var model: AlarmListModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft: AlarmDraft?
    @State private var deleting: AlarmDefinition?

    var body: some View {
        NavigationStack {
            List {
                Text("PuzzleAlarm").font(.title).accessibilityIdentifier("shell.title")
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("alarms.error")
                }
                if let message = model.message { Text(message).accessibilityIdentifier("alarms.warning") }
                if model.loaded && model.definitions.isEmpty {
                    Text("No alarms yet. Add an alarm to get started.").accessibilityIdentifier("alarms.empty")
                }
                ForEach(model.definitions, id: \.id) { alarm in alarmRow(alarm) }
                Button("Refresh alarms") { Task { await model.refresh() } }
                    .accessibilityIdentifier("alarms.refresh")
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add alarm", systemImage: "plus") { draft = AlarmDraft() }
                        .disabled(!model.loaded || model.busy)
                        .accessibilityIdentifier("alarms.add")
                }
            }
            .disabled(model.busy)
            .overlay { if model.busy { ProgressView("Updating alarms") } }
            .sheet(item: $draft) { value in AlarmEditorView(draft: value, model: model) }
            .alert("Delete alarm?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let value = deleting { Task { await model.execute(.delete(value.id)) } }
                    deleting = nil
                }
                Button("Cancel", role: .cancel) { deleting = nil }
            } message: { Text("Scheduled alarms will be cancelled when safe. Active challenge sessions remain protected.") }
            .task { await model.refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && model.loaded { Task { await model.refresh() } }
            }
        }
    }

    private func alarmRow(_ alarm: AlarmDefinition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { draft = AlarmDraft(alarm) } label: {
                VStack(alignment: .leading) {
                    Text(String(format: "%02d:%02d", alarm.time.hour, alarm.time.minute)).font(.title2)
                    Text(alarm.weekdays.isEmpty ? "One time" : Weekday.allCases.filter {
                        alarm.weekdays.contains($0)
                    }.map(\.title).joined(separator: ", "))
                    Text(alarm.dismissalMode == .annoyingOnly ? "Alarm only" :
                        alarm.challengeSequence.items.map { $0.kind.title }.joined(separator: " → "))
                    Text(AlarmDraft.soundNames[AlarmDraft.sounds.firstIndex(of: alarm.selectedSound) ?? 0])
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit alarm at \(alarm.time.hour):\(String(format: "%02d", alarm.time.minute))")
            .accessibilityIdentifier("alarm.edit.\(alarm.id)")
            Toggle("Enabled", isOn: Binding(get: { alarm.enabled }, set: { enabled in
                Task { await model.execute(enabled ? .enable(alarm.id) : .disable(alarm.id)) }
            }))
            .accessibilityLabel("Enable alarm at \(alarm.time.hour):\(String(format: "%02d", alarm.time.minute))")
            .accessibilityIdentifier("alarm.enabled.\(alarm.id)")
            if let status = model.status(for: alarm.id) {
                Text(status).accessibilityIdentifier("alarm.status.\(alarm.id)")
            }
            if model.canRetry(alarm.id) {
                Button("Retry scheduling") { Task { await model.execute(.retry(alarm.id)) } }
                    .accessibilityIdentifier("alarm.retry.\(alarm.id)")
            }
            Button("Delete alarm", role: .destructive) { deleting = alarm }
                .accessibilityIdentifier("alarm.delete.\(alarm.id)")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 6)
    }
}
