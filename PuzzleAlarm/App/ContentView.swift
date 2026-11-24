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
                #if APPETIZE_PREVIEW && DEBUG && targetEnvironment(simulator)
                Text("Preview: alarm scheduling is simulated. Alarms will not ring. Challenge solving is not available yet.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("preview.notice")
                #endif
                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red).accessibilityIdentifier("alarms.error")
                }
                if let message = model.message { Text(message).accessibilityIdentifier("alarms.warning") }
                if model.listState == .loading {
                    Text("Loading alarms…").accessibilityIdentifier("alarms.loading")
                }
                if model.listState == .ready {
                    Text("Your alarms").accessibilityIdentifier("alarms.ready")
                }
                if model.listState == .empty {
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
            .switchDiagnosticState("stored=\(model.definitions); busy=\(model.busy); loaded=\(model.loaded); error=\(String(describing: model.errorMessage)); selected=\(String(describing: draft?.id))", context: "list")
            .navigationTestState("list", context: "list")
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
            LabeledContent("Enabled") {
                AlarmEnabledSwitch(alarm: alarm, model: model)
            }
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
        .disabled(!model.loaded || model.busy)
    }
}

private struct AlarmEnabledSwitch: View {
    let alarm: AlarmDefinition
    @ObservedObject var model: AlarmListModel
    @State private var requestedValue: Bool? = nil

    var body: some View {
        Toggle("Enabled", isOn: Binding(
            get: { requestedValue ?? alarm.enabled },
            set: { enabled in
                guard requestedValue == nil, !model.busy else { return }
                // A native control needs its binding to reflect the gesture
                // synchronously, before the service suspends for persistence.
                requestedValue = enabled
                Task {
                    await model.execute(enabled ? .enable(alarm.id) : .disable(alarm.id))
                    // Success and failure both reconcile to authoritative state.
                    requestedValue = nil
                }
            }
        ))
        .labelsHidden()
        .disabled(!model.loaded || model.busy || requestedValue != nil)
        .accessibilityLabel("Enable alarm at \(alarm.time.hour):\(String(format: "%02d", alarm.time.minute))")
        .accessibilityIdentifier("alarm.enabled.\(alarm.id)")
    }
}
