# Native iOS boundary

The [active restart PROJECT_STATE](https://github.com/teejayishere/PuzzleAlarm/blob/codex/restart-gate5-20261029-f8a41c/docs/PROJECT_STATE.md)
is the single current-status authority. Gates 0–5 are inherited accepted;
Stage 6 alarm-management UI is implemented as a candidate. Gate 6 requires the
exact-final-HEAD full CI result reported in closeout. Stop after Gate 6.
Main and all inactive branches are historical/abandoned.

PuzzleAlarmApp composes disk storage, the existing Apple adapter and one lifecycle
coordinator behind an injected management service. ContentView displays the alarm
list and opens an isolated draft editor for time/weekdays/mode/challenges/sound.
The application links the existing PuzzleAlarmCore product as a local Swift
package through project.yml. Core sources are not copied into the app target.

UI tests use DEBUG Simulator-only injection, isolated disk storage and a persistent
fake OS-ID registry. They exercise real lifecycle/persistence through CRUD,
configuration, ordering, relaunch and visible failure flows, plus the title assertion.

The iOS boundary now includes the Stage 3 AlarmKit adapter and compile-spike App
Intent. The linked core supplies Stage 4 persistence and Stage 5 lifecycle
orchestration, with platform integration tests. Startup/foreground/manual refresh
now invokes recovery through the same service as user commands. Challenge engines,
final wake-up routing, camera and audio remain future work. Physical alarm behavior
remains DEVICE REQUIRED; compile and Simulator evidence cannot establish it.

Generate PuzzleAlarm.xcodeproj with pinned XcodeGen; generated
projects and Info.plist files are intentionally ignored.
