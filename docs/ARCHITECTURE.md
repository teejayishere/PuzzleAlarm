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

Stage 2: SwiftUI shell and generated Xcode project.
Stage 3: real SDK compile spike and AlarmScheduling adapter feasibility.
Stage 4: versioned local atomic persistence and actual disk-failure tests.
Stage 5: transactional side effects, reconciliation, recurrence, edit/disable/delete.
Stages 7–10: engine-validated sequencing, Math/Memory and exact QR matching/camera.
Stage 11: generated sound resources, preview cleanup and AlarmKit sound integration.

Nothing in Stage 1 establishes actual OS scheduling, durable disk writes, camera,
audio, intent routing, Simulator success or physical-device readiness.
