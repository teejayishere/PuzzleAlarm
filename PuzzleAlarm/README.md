# Native iOS application through Stage 11

The app links the Foundation-only PuzzleAlarmCore package through project.yml.
It provides alarm management, persisted ordered Math/Memory/QR challenges,
AlarmKit adapters, QR generation/sharing/capture and bundled audio selection,
preview cleanup and validated default fallback. App Intent wake-up routing is
deferred to Stage 12 and is outside the Stage 11 task.

Generate PuzzleAlarm.xcodeproj with pinned XcodeGen. Generated projects and
Info.plist files are ignored. See ../docs/PROJECT_STATE.md for current gate status
and exact-revision CI, ../docs/TEST_MATRIX.md for separate automated/Simulator
evidence, and ../docs/DEVICE_TEST_PLAN.md for unperformed hardware validation.
No physical alarm, camera or audio success is inferred from source or Simulator.
