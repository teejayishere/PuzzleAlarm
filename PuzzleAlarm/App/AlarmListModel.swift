import Foundation
import Combine
import PuzzleAlarmCore

@MainActor
final class AlarmListModel: ObservableObject {
    @Published private(set) var definitions: [AlarmDefinition] = []
    @Published private(set) var operations: [LifecycleOperation] = []
    @Published private(set) var busy = false
    @Published private(set) var loaded = false
    @Published private(set) var message: String?
    @Published private(set) var errorMessage: String?
    private let service: any AlarmManagementService
    private let repository: any PuzzleAlarmRepository

    init(service: any AlarmManagementService, repository: any PuzzleAlarmRepository) {
        self.service = service; self.repository = repository
    }

    func refresh() async { _ = await execute(.refresh) }

    func save(_ draft: AlarmDraft) async -> Bool {
        do {
            let value = try draft.definition(at: Date())
            if let original = draft.original { return await execute(.edit(value, original: original)) }
            return await execute(.create(value))
        } catch { errorMessage = "Check the alarm configuration: \(error)"; return false }
    }

    @discardableResult
    func execute(_ command: AlarmManagementCommand) async -> Bool {
        guard !busy else { return false }
        busy = true
        defer { busy = false }
        errorMessage = nil
        do {
            let report = try await service.perform(command)
            SwitchDiagnostics.record("service.return enabled=\(report.state.definitions.map(\.enabled))")
            apply(report.state)
            loaded = true
            message = report.issues.isEmpty ? nil :
                "Some alarms need attention. Saved settings do not guarantee scheduling. Review each alarm below."
            return true
        } catch {
            SwitchDiagnostics.record("service.error \(error)")
            // A thrown acknowledgment may follow a durable write. Reload actual
            // storage rather than optimistically restoring stale UI state.
            do {
                switch try await repository.load() {
                case .missing: apply(try RepositoryState())
                case let .loaded(snapshot, _): apply(snapshot.state)
                }
                loaded = true
            } catch {
                loaded = false
            }
            errorMessage = error is ManagementError
                ? "Alarm permission is required. Allow alarms in Settings, or save this alarm disabled."
                : "The operation could not finish. Saved state was reloaded when available. Reopen the editor before retrying. \(error)"
            return false
        }
    }

    private func apply(_ state: RepositoryState) {
        definitions = state.definitions.sorted {
            if $0.time.hour != $1.time.hour { return $0.time.hour < $1.time.hour }
            if $0.time.minute != $1.time.minute { return $0.time.minute < $1.time.minute }
            return $0.id.uuidString < $1.id.uuidString
        }
        operations = state.operations
    }

    func status(for id: UUID) -> String? {
        guard let operation = operations.first(where: { $0.configuration.id == id }) else { return nil }
        if operation.action == .delete { return "Deletion pending: cleanup or an active session must finish." }
        if operation.oneTimeConsumed { return "One-time occurrence consumed. Edit to schedule a new occurrence." }
        if let failure = operation.failure { return "Scheduling needs attention: \(failure)." }
        return nil
    }

    func canRetry(_ id: UUID) -> Bool {
        operations.contains { $0.configuration.id == id && $0.status == .failed && !$0.oneTimeConsumed }
    }
}
