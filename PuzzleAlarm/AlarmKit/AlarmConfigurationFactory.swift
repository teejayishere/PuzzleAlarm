import ActivityKit
import AlarmKit
import Foundation
import PuzzleAlarmCore
import SwiftUI

enum AlarmConfigurationFactory {
    static func presentation(challenge: Bool = true) -> AlarmPresentation {
        let solve: AlarmButton? = challenge ? AlarmButton(text: "Solve", textColor: .white, systemImageName: "arrow.up.forward") : nil
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: "PuzzleAlarm", secondaryButton: solve, secondaryButtonBehavior: challenge ? .custom : nil
            )
        } else {
            // Required only by the iOS 26.0 initializer; 26.1+ owns its Stop control.
            alert = AlarmPresentation.Alert(
                title: "PuzzleAlarm",
                stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill"),
                secondaryButton: solve, secondaryButtonBehavior: challenge ? .custom : nil
            )
        }
        return AlarmPresentation(alert: alert)
    }

    static func configuration(
        for request: AlarmRequest, sound: AlertConfiguration.AlertSound? = nil
    ) -> AlarmManager.AlarmConfiguration<OccurrenceMetadata> {
        .alarm(
            schedule: schedule(for: request),
            attributes: AlarmAttributes(
                presentation: presentation(challenge: request.sessionID != nil), metadata: request.metadata, tintColor: .orange
            ),
            secondaryIntent: request.sessionID.map { OpenOccurrenceIntent(occurrenceID: $0) },
            sound: sound ?? selectedSound(request.selectedSound)
        )
    }


    static func schedule(for request: AlarmRequest) -> Alarm.Schedule {
        switch request.schedule {
        case let .fixed(date): .fixed(date)
        case let .weekly(time, days): relativeSchedule(time: time, weekdays: days)
        }
    }

    static func selectedSound(_ selection: SoundSelection) -> AlertConfiguration.AlertSound {
        switch selection {
        case .systemDefault: .default
        case let .bundled(sound): .named(sound.rawValue + ".caf")
        }
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
