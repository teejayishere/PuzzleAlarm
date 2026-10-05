import SwiftUI
import PuzzleAlarmCore

struct ContentView: View {
    @Bindable var store: AlarmStore
    @State private var draft: AlarmEditorDraft?
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section("Alarm access") {
                    Text(AlarmFormatting.authorization(store.authorization)).accessibilityIdentifier("authorization.status")
                    if store.authorization == .notDetermined {
                        Button("Allow Alarms") { Task { await store.grantAuthorization() } }
                            .accessibilityIdentifier("authorization.request")
                    } else if store.authorization == .denied {
                        Text("Enable alarm access in Settings to turn alarms on.")
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }.accessibilityIdentifier("authorization.settings")
                    }
                }
                if let error = store.errorMessage {
                    Section("Needs attention") {
                        Text(error).accessibilityIdentifier("application.error")
                        Button("Refresh") { Task { await store.refresh() } }.accessibilityIdentifier("application.refresh")
                    }
                }
                if !store.issues.isEmpty {
                    Section("Alarm status") {
                        ForEach(Array(store.issues.enumerated()), id: \.offset) { _, issue in
                            Text(AlarmFormatting.issue(issue))
                        }
                    }
                }
                if store.hasLoaded && store.alarms.isEmpty && store.errorMessage == nil {
                    ContentUnavailableView("No alarms", systemImage: "alarm",
                        description: Text("Add an alarm for your next wake-up.")).accessibilityIdentifier("alarms.empty")
                } else if !store.hasLoaded {
                    if store.errorMessage == nil { ProgressView("Loading alarms") }
                }
                ForEach(store.alarms, id: \.id) { alarm in
                    Section {
                        Button { draft = AlarmEditorDraft(alarm) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(AlarmFormatting.time(alarm.time)).font(.largeTitle).monospacedDigit()
                                Text(AlarmFormatting.repeatSummary(alarm.weekdays))
                                Text(AlarmFormatting.challenges(alarm))
                                Text(SoundChoice(alarm.selectedSound).title).foregroundStyle(.secondary)
                            }.foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                        }.accessibilityIdentifier("alarm.edit." + alarm.id.uuidString)
                        Toggle("Alarm enabled", isOn: Binding(get: { alarm.enabled }, set: { value in
                            Task { await store.setEnabled(alarm, value) }
                        })).accessibilityIdentifier("alarm.enabled." + alarm.id.uuidString)
                        Text(store.status(alarm)).accessibilityIdentifier("alarm.status." + alarm.id.uuidString)
                        if let date = store.nextOccurrence(alarm) {
                            Text(date, format: .dateTime.weekday().hour().minute()).foregroundStyle(.secondary)
                                .accessibilityLabel("Next occurrence")
                        }
                        if store.canRetry(alarm) {
                            Button("Retry") { Task { await store.retry(alarm.id) } }
                                .accessibilityIdentifier("alarm.retry." + alarm.id.uuidString)
                        }
                    }
                }
            }
            .navigationTitle("PuzzleAlarm")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Alarm", systemImage: "plus") {
                        do { draft = try store.newDraft() } catch { store.reportError(error) }
                    }.accessibilityIdentifier("alarms.add").disabled(!store.hasLoaded || store.isBusy)
                }
                ToolbarItem(placement: .status) {
                    if store.isBusy { ProgressView("Updating alarms").accessibilityIdentifier("application.busy") }
                }
            }
            .disabled(store.isBusy)
            .refreshable { await store.refresh() }
            .sheet(item: $draft) { value in AlarmEditorView(store: store, initial: value) }
        }
    }
}
