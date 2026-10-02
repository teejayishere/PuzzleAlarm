# Native iOS shell — Stage 2

PuzzleAlarmApp opens ContentView, which displays only the PuzzleAlarm title.
The application links the existing PuzzleAlarmCore product as a local Swift
package through project.yml. Core sources are not copied into the app target.

The UI test launches the app on a dynamically selected iPhone Simulator and
checks the displayed title. This is shell-launch evidence only.

No AlarmKit, App Intents, scheduling, storage, challenge UI, camera or audio is
implemented. Generate PuzzleAlarm.xcodeproj with pinned XcodeGen; generated
projects and Info.plist files are intentionally ignored.
