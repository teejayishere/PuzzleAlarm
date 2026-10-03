# Stage 3 — installed SDK capability evidence

Scope: compile/integration spike only. No alarm scheduling is triggered by app
launch or tests. No permission dialog, persistence, orchestration or product UI.
Gate 3 compilation and tests passed at 6e750fd in run 37095598366. Final follow-ups require their own exact-HEAD green workflow before acceptance.

## Observed SDK, before implementation

[SDK inspection run 37095284734](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095284734)
at 917a3990b0c8a5bbbe4233cdfdbfc3af5b429e7c completed successfully.
Xcode 26.6 (17F113), Swift 6.3.3; selected iPhoneSimulator26.5 SDK.
The module interface itself was produced with Swift 6.3.2; that is not the active
compiler version. Public AlarmKit declarations are iOS 26.0+, unavailable on
Mac Catalyst. The app remains iPhone/iOS 26.0+.

Scripts/inspect_alarmkit_sdk.py prints the installed public interfaces; the
manual, standard macos-26 workflow can repeat this investigation on future SDKs.
No SDK binaries or interface copies are committed.

## Capability matrix

Compilation status for all API rows: XCODE COMPILE PASS in [run 37095598366](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095598366), revision 6e750fd. Usage-description validation and seven platform tests also passed.
“Device” distinguishes a compiled API from its actual OS behavior.

| Capability | Exact installed API/type observed | Spike use / deferred work | Device |
| --- | --- | --- | --- |
| Authorization | AlarmManager.authorizationState: AuthorizationState; requestAuthorization() async throws -> AuthorizationState | Service maps notDetermined/authorized/denied, unknown conservatively; no startup call | Allow/deny and Settings changes required |
| Fixed schedule | Alarm.Schedule.fixed(Date) | Configuration uses the existing PlannedAlarm.date | Actual firing required |
| Relative schedule | Alarm.Schedule.relative(Relative); Relative.Time(hour:minute:); Relative(time:repeats:) | Pure translation probe; no daemon call | Local-time/timezone behavior required |
| Weekly recurrence | Relative.Recurrence.weekly([Locale.Weekday]); .never | Empty weekdays -> never; sorted nonempty domain weekdays -> weekly | DST/recurrence delivery required |
| Metadata | AlarmMetadata: Decodable, Encodable, Hashable, Sendable | OccurrenceMetadata: session UUID, parent UUID, ordinal; primary role derives from ordinal 0 | OS acceptance required |
| Presentation | AlarmPresentation(alert:countdown:paused:); AlarmAttributes(presentation:metadata:tintColor:) | Alert only, PuzzleAlarm title, Solve button, custom behavior; no countdown/paused values | Lock-screen rendering required |
| Secondary intent | AlarmConfiguration secondaryIntent: (any LiveActivityIntent)? | OpenOccurrenceIntent, one String parameter containing the session UUID | Invocation and opening required after first unlock |
| Open behavior | AppIntent.supportedModes: IntentModes; IntentModes.foreground | Explicit foreground request; perform returns .result(), no effects | OS launch behavior required |
| Default sound | ActivityKit.AlertConfiguration.AlertSound.default | Default configuration | Audible firing required |
| Named sound | AlertConfiguration.AlertSound.named(_ name: String) | Named configuration compile path only; no sound resources | Actual custom playback required |
| Schedule | AlarmManager.schedule(id: Alarm.ID, configuration: AlarmConfiguration<Metadata>) async throws -> Alarm | Externally supplied PlannedAlarm.id; return mapped to RegisteredAlarm | OS scheduling/limits required |
| Cancel | AlarmManager.cancel(id: Alarm.ID) throws | Synchronous, one known UUID, error propagates | Actual removal required |
| Current snapshot | AlarmManager.alarms: [Alarm] { get throws } | Return stable ID/state; errors propagate instead of empty success | Freshness/relaunch consistency required |
| Updates | alarmUpdates: some AsyncSequence<[Alarm], Never> | for await in caller-owned task; maps full snapshots; respects cancellation | Delivery/cancellation behavior required |
| Stable ID | Alarm.id: UUID; Alarm.ID = UUID | Same supplied ID across schedule/cancel/snapshot boundary | Daemon persistence required |
| State | Alarm.State: scheduled, countdown, paused, alerting | All observed states mapped, plus unknown; no completion inference | Real state transitions required |
| Usage description | NSAlarmKitUsageDescription | Generated from project.yml; CI reads built .app/Info.plist | Actual prompt required |

## Findings and architectural limits

- Registered Alarm exposes ID, schedule, countdownDuration and state. It does
  **not** expose the custom metadata in its public snapshot. Reconciliation is
  feasible through persisted IDs, as Stage 1 already requires. Metadata is not
  a substitute for the local session ledger, and cannot reconstruct a lost one.
- An absent ID establishes only absence from a successful snapshot. It cannot
  establish that challenges were solved or distinguish stop from cancellation.
  Stage 5 must reconcile uncertainty without inventing completion.
- Traditional AlarmConfiguration.alarm requires neither countdown presentation
  nor a Widget extension. ActivityKit is imported solely because AlarmKit's sound
  parameter uses its AlertSound type; no Live Activity is implemented.
- AlarmManagerService is a value with injectable operations. It owns no singleton
  or background producer task. Apple AlarmManager.shared is the sole singleton.
  observeAlarms must run in a future caller-owned, cancelable task.
- AlarmRequest resolves a supplied ID within the existing session plan and rejects
  unrelated IDs. No adapter UUID is generated. The immutable session snapshot is
  untouched. Role is derived from the core ordinal instead of duplicated state.
- Relative recurrence follows device-local wall time according to Apple's
  documentation; fixed dates remain absolute. There is no SDK timezone/calendar
  parameter or documented DST policy in these declarations. Stage 1's Foundation
  calculation remains authoritative for fixed challenge occurrences; it is not
  proof of AlarmKit recurring-alarm DST behavior. Stage 5/device tests must retain
  this distinction.

## Documentation vs installed interface

Apple's older [WWDC25 example](https://developer.apple.com/videos/play/wwdc2025/230/)
uses a custom stopButton and openAppWhenRun. The installed SDK deprecates
stopButton at iOS 26.1 and openAppWhenRun at iOS 26.0.
The spike uses the 26.1 Alert initializer, with the old initializer confined to
the iOS 26.0 availability branch, and supportedModes = .foreground.
No system Stop control is removed; no stopIntent/business logic is supplied.

The current [configuration overview](https://developer.apple.com/documentation/alarmkit/alarmmanager/alarmconfiguration)
also lists newer appEntityIdentifier overloads and an older alertConfiguration
example absent from the installed interface. Neither is used.
That page documents the secondary intent as available only after first unlock.

The installed intent parameter wrapper accepts supported IntentValue/Sendable
types, including String; it does not accept arbitrary domain Codable structs
as parameters merely because they are Codable. Our single @Parameter String
serializes the occurrence UUID. The intent itself need not conform to Codable.
The same session ID identifies primary and backup actions for future routing.
No routing sink or persistence is implemented in this stage.

[Foreground mode](https://developer.apple.com/documentation/appintents/intentmodes/foreground)
requests immediate foreground execution. Compilation does not prove alarm-origin
launch, lock-state behavior or parameter delivery on a physical iPhone.

[Named sound documentation](https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:))
specifies the main app bundle or the app data container's Library/Sounds folder.
The signature alone does not establish format, reliable playback or fallback.
Those remain Stage 11/device work.

## Validation and adversarial review

Seven platform tests cover metadata mapping/round trips/minimal keys and foreign-ID
rejection; all 128 weekday subsets; alert-only presentation; intent identity;
authorization mapping; fake-operation stable-ID forwarding/snapshots/updates;
and injected permission/schedule/cancel/snapshot errors. Tests never use live
operations or the real AlarmKit daemon.

The real iOS target compiles all platform files. The unchanged shell does not
instantiate the service. All 26 core tests, coverage reporting, XcodeGen
reproducibility, dynamic Simulator selection, launch test and diagnostic review
remain required. No compiler warning suppression, paid service or larger runner.

Review: no Apple platform imports or model changes in core; no Stage 4+ behavior;
no timer, snooze, widget, hidden UUID, swallowed error, Stop-as-completion path,
or competing scheduler protocol. No earlier assumption has been disproved by
the observed interface. Gate acceptance still requires actual CI.

Physical validation remains DEVICE REQUIRED for permission, firing, lock screen,
Focus/Silent override, intent opening/identity delivery, real reconciliation,
and default/custom sound playback. iOS 26.0 fallback is compile-only on the
available iOS 26.5 Simulator.
