import ActivityKit
import AlarmKit
import Foundation
import PuzzleAlarmCore
import SwiftUI

enum AlarmConfigurationFactory {
    static func presentation() -> AlarmPresentation {
        let solve = AlarmButton(text: "Solve", textColor: .white, systemImageName: "arrow.up.forward")
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: "PuzzleAlarm", secondaryButton: solve, secondaryButtonBehavior: .custom
            )
        } else {
            // Required only by the iOS 26.0 initializer; 26.1+ owns its Stop control.
            alert = AlarmPresentation.Alert(
                title: "PuzzleAlarm",
                stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill"),
                secondaryButton: solve, secondaryButtonBehavior: .custom
            )
        }
        return AlarmPresentation(alert: alert)
    }

    static func configuration(
        for request: AlarmRequest, sound: AlertConfiguration.AlertSound = .default
    ) -> AlarmManager.AlarmConfiguration<OccurrenceMetadata> {
        .alarm(
            schedule: .fixed(request.plannedAlarm.date),
            attributes: AlarmAttributes(
                presentation: presentation(), metadata: request.metadata, tintColor: .orange
            ),
            secondaryIntent: OpenOccurrenceIntent(occurrenceID: request.metadata.sessionID),
            sound: sound
        )
    }

    // Compile-only named-sound path. No resource is supplied or playback claimed.
    static func namedSoundConfiguration(
        for request: AlarmRequest, filename: String
    ) -> AlarmManager.AlarmConfiguration<OccurrenceMetadata> {
        configuration(for: request, sound: .named(filename))
    }

    // Capability translation only; never submitted to the daemon by this spike.
    static func relativeSchedule(time: AlarmTime, weekdays: Set<Weekday>) -> Alarm.Schedule {
        let days = weekdays.sorted { $0.rawValue < $1.rawValue }.map(localeWeekday)
        return .relative(.init(
            time: .init(hour: time.hour, minute: time.minute),
            repeats: days.isEmpty ? .never : .weekly(days)
        ))
    }

    private static func localeWeekday(_ day: Weekday) -> Locale.Weekday {
        switch day {
        case .sunday: .sunday
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        }
    }
}
