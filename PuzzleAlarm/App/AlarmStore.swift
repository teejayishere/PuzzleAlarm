import Foundation
import Observation
import PuzzleAlarmCore

enum AlarmSaveResult {
    case saved
    case attention(AlarmDefinition)
    case failed
}

@MainActor @Observable
final class AlarmStore {
    private(set) var state: RepositoryState?
    private(set) var issues: [LifecycleReport.Issue] = []
    private(set) var authorization: AlarmAuthorization
    private(set) var isBusy = false
    private(set) var hasLoaded = false
    private(set) var confirmed = false
    private(set) var errorMessage: String?
    private(set) var editWasSuperseded = false
    private var refreshPending = false
    let coordinator: AlarmLifecycleCoordinator
    @ObservationIgnored private let repository: any PuzzleAlarmRepository
    @ObservationIgnored private let scheduler: any AlarmScheduling
    @ObservationIgnored private let context: @Sendable () throws -> ScheduleContext
    @ObservationIgnored private let clock: @Sendable () -> Date
    @ObservationIgnored private let makeID: @Sendable () -> UUID

    init(repository: any PuzzleAlarmRepository, scheduler: any AlarmScheduling,
         clock: @escaping @Sendable () -> Date = { Date() },
         makeID: @escaping @Sendable () -> UUID = { UUID() },
         context: @escaping @Sendable () throws -> ScheduleContext = {
             try ScheduleContext(timeZoneIdentifier: TimeZone.current.identifier)
         }) {
        self.repository = repository; self.scheduler = scheduler
        self.clock = clock; self.makeID = makeID; self.context = context
        authorization = scheduler.authorization
        coordinator = AlarmLifecycleCoordinator(repository: repository, scheduler: scheduler, clock: clock, makeID: makeID)
    }

    var alarms: [AlarmDefinition] {
        (state?.definitions ?? []).sorted {
            if $0.enabled != $1.enabled { return $0.enabled }
            if $0.time.hour != $1.time.hour { return $0.time.hour < $1.time.hour }
            if $0.time.minute != $1.time.minute { return $0.time.minute < $1.time.minute }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
    func definition(_ id: UUID) -> AlarmDefinition? { state?.definitions.first { $0.id == id } }
    func newDraft() throws -> AlarmEditorDraft { try AlarmEditorDraft(id: makeID(), now: clock()) }
    func newToken() -> UUID { makeID() }
    func currentDate() -> Date { clock() }
    func displayContext() throws -> ScheduleContext { try context() }
    func clearError() { errorMessage = nil; editWasSuperseded = false }
    func reportError(_ error: any Error) { errorMessage = AlarmFormatting.error(error) }

    func refresh() async {
        if isBusy { refreshPending = true; return }
        _ = await perform { try await self.reconcile() }
    }
    func grantAuthorization() async {
        guard !isBusy else { return }
        _ = await perform {
            self.authorization = try await self.scheduler.requestAuthorization()
            if self.authorization != .authorized { throw StoreError.access }
            return try await self.reconcile()
        }
    }

    func save(_ draft: AlarmEditorDraft) async -> AlarmSaveResult {
        guard !isBusy else { return .failed }
        var replacement: AlarmDefinition?
        let success = await perform {
            let value = try draft.definition(at: self.clock())
            replacement = value
            if value.enabled { try await self.requireAccess() }
            let context = try self.context()
            if let original = draft.original {
                return try await self.coordinator.edit(value, expecting: original, context: context)
            }
            return try await self.coordinator.create(value, context: context)
        }
        if success, let current = definition(draft.id) {
            if needsAttention(current) { return .attention(current) }
            return .saved
        }
        // An acknowledgment can fail after configuration was persisted. Only adopt
        // OUR exact submitted value; never rebase a superseded edit automatically.
        if !editWasSuperseded, let replacement, let current = definition(draft.id), current == replacement {
            return .attention(current)
        }

        return .failed
    }

    func setEnabled(_ alarm: AlarmDefinition, _ enabled: Bool) async {
        _ = await perform {
            if enabled { try await self.requireAccess() }
            let context = try self.context()
            if enabled { return try await self.coordinator.enable(alarm.id, context: context) }
            return try await self.coordinator.disable(alarm.id, context: context)
        }
    }
    func delete(_ id: UUID) async -> Bool {
        let success = await perform { try await self.coordinator.delete(id, context: self.context()) }
        return success && definition(id) == nil
    }
    func retry(_ id: UUID) async {
        _ = await perform {
            if self.definition(id)?.enabled == true { try await self.requireAccess() }
            return try await self.coordinator.retry(id, context: self.context())
        }
    }
    private func requireAccess() async throws {
        authorization = scheduler.authorization
        if authorization == .notDetermined { authorization = try await scheduler.requestAuthorization() }
        guard authorization == .authorized else { throw StoreError.access }
    }
    private func reconcile() async throws -> LifecycleReport? {
        authorization = scheduler.authorization
        // Reading configuration does not require permission or trigger a prompt.
        if authorization != .authorized {
            try await loadPersisted()
            return nil
        }
        return try await coordinator.startup(context: context())
    }
    private func loadPersisted() async throws {
        switch try await repository.load() {
        case .missing: state = try RepositoryState()
        case let .loaded(snapshot, _): state = snapshot.state
        }
        confirmed = false
    }
    private func accept(_ report: LifecycleReport?) {
        if let report { state = report.state; issues = report.issues; confirmed = true }
        hasLoaded = true
    }
    // One action plus at most one coalesced foreground refresh. No unbounded queue.
    @discardableResult
    private func perform(_ action: () async throws -> LifecycleReport?) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true; errorMessage = nil; editWasSuperseded = false
        var success = false
        do { accept(try await action()); success = true }
        catch {
            confirmed = false
            if let error = error as? LifecycleError, error == .superseded {
                editWasSuperseded = true
            }
            errorMessage = error is StoreError ? "Allow alarm access in Settings before enabling this alarm." :
                AlarmFormatting.error(error)
            // Retain authoritative partial progress without issuing more OS effects.
            do { try await loadPersisted(); hasLoaded = true }
            catch { errorMessage = AlarmFormatting.error(error) }
        }
        if refreshPending {
            refreshPending = false
            do { accept(try await reconcile()) }
            catch { confirmed = false; if errorMessage == nil { errorMessage = AlarmFormatting.error(error) } }
        }
        isBusy = false
        return success
    }
    private enum StoreError: Error { case access }
}
