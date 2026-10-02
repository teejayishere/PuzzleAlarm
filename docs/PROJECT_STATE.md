# Project state

Current stage: 0 — Repository / Environment
Current gate: Gate 0 — BLOCKED
Last known passing gate: None
Invalidated gates: None
Current version/status: 0.0.0 scaffold — not runnable, not device ready

## Current blockers

- Swift is absent from PATH; common Swift install locations were not found.
- WSL reports it is not installed; no Docker or GitHub CLI was found on PATH.
- There is no configured GitHub remote or current CI run to supply Swift evidence.
- This Windows environment cannot compile Xcode/iOS targets.
- Gate 0 requires a successful manifest parse and working Swift tooling.
  Those requirements are unverified; Stage 1 must not begin yet.

## Open engineering risks

- AlarmKit APIs, entitlements, limits, sounds and App Intent routing need a real
  current SDK compile spike in Stage 3.
- Personal provisioning and AlarmKit installation must be proven on an iPhone.
- Durable scheduling must handle the crash window between OS success and disk
  acknowledgment; merely storing returned IDs after calls is insufficient.
- Five alarms provide a bounded four-minute backup window, not an indefinite alarm.
- GitHub runner labels and SDK inventories change. Stage 2 must inspect them.
- Empty project generation or a scaffold build must never be called an app build.

## Unverified assumptions

SwiftPM manifest/module build, XcodeGen generation, all app/domain behavior,
public-repository CI execution and device installation remain unverified.

## Device-required validations

Authorization, lock-screen and terminated-app firing, Focus/Silent Mode,
backup chain, cancellation, intent launch, QR camera, sound playback, timezone
changes and free personal provisioning.

## Most recent CI evidence

None. Workflow exists locally and has never run. No remote is configured.

## Next action

Provide a Swift 6+ execution environment or connect this folder to a public
GitHub repository and run the Stage 0 workflow. Record revision/run evidence.
Rerun Gate 0 before beginning Stage 1. Actual Xcode integration begins at Stage 2.

## Latest local structural evidence (2026-09-30)

YAML parsing/structure, exact specification copy, dependency and common-secret
pattern checks passed across 16 files. These do not satisfy the missing Swift
manifest/build checks. Git initialized on main; no remote, commits or CI runs.
