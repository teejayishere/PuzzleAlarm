# Native iOS boundary

The [active restart PROJECT_STATE](https://github.com/teejayishere/PuzzleAlarm/blob/codex/restart-gate5-20261029-f8a41c/docs/PROJECT_STATE.md)
is the single current-status authority. Gates 0–5 are inherited accepted;
Stage/Gate 6 are NOT STARTED. Independently rebuilding Stage 6 is next; stop after
Gate 6. Main and all inactive branches are historical/abandoned.

PuzzleAlarmApp opens ContentView, which displays only the PuzzleAlarm title.
The application links the existing PuzzleAlarmCore product as a local Swift
package through project.yml. Core sources are not copied into the app target.

The UI test launches the app on a dynamically selected iPhone Simulator and
checks the displayed title. This is shell-launch evidence only.

The iOS boundary now includes the Stage 3 AlarmKit adapter and compile-spike App
Intent. The linked core supplies Stage 4 persistence and Stage 5 lifecycle
orchestration, with platform integration tests. Those services are not wired into
the title-screen app startup. Product alarm-management UI, challenge engines/UI,
final wake-up routing, camera and audio remain future work. Physical alarm behavior
remains DEVICE REQUIRED; compile and Simulator evidence cannot establish it.

Generate PuzzleAlarm.xcodeproj with pinned XcodeGen; generated
projects and Info.plist files are intentionally ignored.
