# Architecture

## Implemented through Stage 1

PuzzleAlarmCore contains Foundation-only Codable/Equatable/Sendable values and
controlled state transitions. There are no SwiftUI, UIKit, AlarmKit or AVFoundation
imports, global mutable state, wall-clock reads or uncontrolled randomness.

Dates, timezone/calendar context and UUIDs are supplied by callers. This is enough
injection for the current pure functions; clock/random protocols will be added only
when real engines or orchestration need them. Dates outside Foundation's distantPast
through distantFuture range are rejected before calendar calculations.

AlarmDefinition is an immutable configuration. Edits produce validated replacements
with the same ID and creation time. A WakeUpSession owns an immutable copy, so later
parent edits/disable do not change an existing occurrence. Updating a definition
does not itself perform scheduling/cancellation: those side effects belong to Stage 5.

Annoying-only definitions require an empty challenge sequence. Challenge definitions
require 1...3 unique Math/Memory/QR configurations in order. Sequence editing provides
append, remove, replace and index-based move operations. Configuration settings are
bounded (Math count 1...20; Memory length 2...12, duration 1...30s, rounds 1...20).
Sound enums identify intended resources; Stage 11 must supply and verify them.

## Calendar contract

Use explicit Gregorian calendar and timezone identity. Alarm time is local wall
time, not a UTC offset. The next occurrence is strictly after the input instant.
Selected weekdays recur; an empty weekday set means a one-time alarm.
A later orchestrator must disable/finish one-time definitions rather than rearming them.

During a DST gap, nextTime selects the first valid time after the gap. During a
repeated hour, only the first occurrence is eligible; if it is already past, choose
the next eligible day. Tests cover both policies with America/Chicago dates.
These are Foundation domain semantics; AlarmKit timezone behavior remains unverified.

BackupPlan owns five unique caller-supplied IDs with absolute offsets 0, 60, 120,
180, 240 seconds. Roles derive from ordinal (0 primary, 1...4 backup).
They remain independent across midnight/DST. There is no backup timer.

## Session and operation state

Normal path: planned → scheduling → armed → active → completing → completed.
Additional states: schedulingFailed, cancellationPartiallyFailed, cancelling, cancelled.

Each planned ID has a scheduling status (planned/inFlight/scheduled/failed) and
cancellation status (notRequested/inFlight/succeeded/failed). A planned or in-flight
OS operation is not a confirmed success. All five scheduling acknowledgments are
required before armed. Partial failure never becomes armed.

Future orchestration must persist the inFlight transition before an OS call and
reconcile its stable ID after interruption. Restoring this model preserves uncertainty;
it does not itself query the OS or prove disk durability. Rollback may reconcile all
planned IDs, including those whose outcome is unknown. SDK feasibility awaits Stage 3.

Challenge success events require the current index. Earlier repeated events are
idempotent; future events are rejected. Only the last success enters completing.
A trusted future challenge engine/coordinator must verify answers before supplying
these events; views must not manufacture them. Counter checkpoints support Stage 1
restoration. Actual Math problem and Memory reveal/hidden round snapshots must be
added with their engines in Stages 8/9 before claiming challenge relaunch support.

Cancellation failures retain retryable IDs; other IDs can still be attempted.
Completion requires the full success sequence AND confirmation that all five
occurrence IDs are canceled/absent. completedAt is then persisted, and repeated
finalization is harmless. Completing/cancellationPartiallyFailed captures the crash
window after solving but before cleanup. Scheduling the next occurrence is Stage 5.

Retirement of a future occurrence uses cancelling → cancelled, never completed.
An active session cannot be retired through this API. Decoder validation enforces
the same structural lifecycle invariants and rejects malformed counts, incompatible
progress, false armed/completed states and inconsistent dates.

## Deferred platform and persistence responsibilities

Stage 3: real SDK compile spike and AlarmScheduling adapter feasibility.
Stage 4: versioned local atomic persistence and actual disk-failure tests.
Stage 5: transactional side effects, reconciliation, recurrence, edit/disable/delete.
Stages 7–10: engine-validated sequencing, Math/Memory and exact QR matching/camera.
Stage 11: generated sound resources, preview cleanup and AlarmKit sound integration.

Nothing in Stage 1 establishes actual OS scheduling, durable disk writes, camera,
audio, intent routing, Simulator success or physical-device readiness.

## Stage 2 native shell and build boundary

PuzzleAlarm/App contains PuzzleAlarmApp and ContentView. The screen displays only
PuzzleAlarm; no domain state is modified and there is no feature UI. project.yml
links the existing PuzzleAlarmCore SwiftPM product from path '.', rather than
including core sources in the app target. CI logs confirm compilation from
Package.swift as a separate dependency. Core implementations/tests are unchanged.

XcodeGen 2.44.1 is fetched from its official release with pinned SHA256 verification.
project.yml generates an iPhone-only iOS 26 app, Info.plist and shared scheme,
plus a minimal XCTest UI launch target. Package.swift explicitly declares iOS 26
alongside its macOS host-testing minimum. No signing identity is required for CI.

Each clean CI checkout regenerates the project twice and compares the project,
scheme and Info.plist bytes. Generated files, DerivedData and local xcresult
bundles are ignored. There is no manual pbxproj source or committed generated project.
Core tests/coverage remain independent and execute before Simulator compilation.

Simulator discovery reads actual simctl device/runtime JSON, rejects unavailable
or pre-iOS-26 runtimes and non-iPhones, then deterministically selects a compatible
device. xcodebuild also prints supported destinations. Build and test explicitly
select the host architecture to avoid ARM/Intel ambiguity for one device UUID.

Swift/C warnings are errors. A post-test log check rejects new Xcode warnings.
The specific appintentsmetadataprocessor advisory about skipped metadata with no
AppIntents.framework is reported explicitly; no compiler diagnostic is suppressed
and no Stage 3 dependency was added to hide the advisory.

Simulator shell launch proves native app startup and accessible title rendering.
It does not prove core business behavior on iOS, alarms, device signing/install,
AlarmKit permissions, camera, audio or physical-device reliability.
