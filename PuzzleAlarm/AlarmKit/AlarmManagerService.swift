import AlarmKit
import Foundation
import PuzzleAlarmCore

struct AlarmManagerService: AlarmScheduling {
    // A closure seam lets tests exercise this adapter without touching the daemon.
    // There is one scheduler protocol, not a second mock-only manager protocol.
    struct Operations: Sendable {
        var authorization: @Sendable () -> AlarmAuthorization
        var requestAuthorization: @Sendable () async throws -> AlarmAuthorization
        var schedule: @Sendable (UUID, AlarmManager.AlarmConfiguration<OccurrenceMetadata>) async throws -> RegisteredAlarm
        var cancel: @Sendable (UUID) throws -> Void
        var currentAlarms: @Sendable () throws -> [RegisteredAlarm]
        var observeAlarms: @Sendable (@escaping @Sendable ([RegisteredAlarm]) -> Void) async -> Void

        static var live: Self {
            Self(
                authorization: { AlarmAuthorization(AlarmManager.shared.authorizationState) },
                requestAuthorization: {
                    AlarmAuthorization(try await AlarmManager.shared.requestAuthorization())
                },
                schedule: { id, configuration in
                    let alarm: Alarm = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
                    return RegisteredAlarm(alarm)
                },
                cancel: { try AlarmManager.shared.cancel(id: $0) },
                currentAlarms: { try AlarmManager.shared.alarms.map(RegisteredAlarm.init) },
                observeAlarms: { receive in
                    for await alarms in AlarmManager.shared.alarmUpdates {
                        guard !Task.isCancelled else { break }
                        receive(alarms.map(RegisteredAlarm.init))
                    }
                }
            )
        }
    }

    private let operations: Operations

    init(operations: Operations = .live) {
        self.operations = operations
    }

    var authorization: AlarmAuthorization { operations.authorization() }

    func requestAuthorization() async throws -> AlarmAuthorization {
        try await operations.requestAuthorization()
    }

    func schedule(_ request: AlarmRequest) async throws -> RegisteredAlarm {
        try await operations.schedule(
            request.plannedAlarm.id, AlarmConfigurationFactory.configuration(for: request)
        )
    }

    func cancel(id: UUID) throws { try operations.cancel(id) }

    func currentAlarms() throws -> [RegisteredAlarm] { try operations.currentAlarms() }

    func observeAlarms(_ receive: @escaping @Sendable ([RegisteredAlarm]) -> Void) async {
        await operations.observeAlarms(receive)
    }
}
