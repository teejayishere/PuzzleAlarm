# Architecture

Current architecture is described in the Stage 5 section below. Earlier sections
are the historical stage record; their deferred-work statements are superseded
by Stage 5. Exact passing implementation evidence is in PROJECT_STATE.md.

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

## Stage 3 platform capability boundary

See [ALARMKIT_CAPABILITIES](ALARMKIT_CAPABILITIES.md) for observed Xcode 26.6 /
iOS 26.5 signatures, the validation status and device limits.

One iOS-layer AlarmScheduling protocol is implemented by AlarmManagerService.
The service forwards authorization, single-ID schedule/cancel, registered-ID
snapshots and asynchronous updates. Injectable operation closures isolate tests
from Apple's daemon without adding another protocol or singleton.
No scheduling service is created by the shell.

AlarmRequest selects an existing PlannedAlarm by ID from WakeUpSession.
OccurrenceMetadata contains only session ID, parent ID and ordinal; primary vs
backup derives from the existing core ordinal. A traditional fixed configuration
uses that exact date and ID. Relative/weekly conversion is a separate capability
probe, not recurrence orchestration. Named sound construction is compile-only.

OpenOccurrenceIntent conforms to the SDK-required LiveActivityIntent. Its sole
String parameter contains the session UUID; supportedModes requests foreground.
It performs no routing, persistence, cancellation or completion. There is no
custom Stop intent. The alert uses the iOS 26.1 system-owned Stop UI and a guarded
26.0 initializer for compatibility.

Snapshots expose ID/state, not custom metadata. They can reconcile membership
against the future persisted session ledger; absence never proves challenge
completion. No reconciliation or persistence implementation exists yet.
ActivityKit supplies only the required sound type, with no Live Activity/widget.

The observation method borrows the caller's task and creates no producer Task.
A future owner must retain/cancel its observation task. Runtime update-delivery
and cancellation behavior are device-required, distinct from compilation.
Core and the title-only shell remain unchanged. Stage 4+ is not started.

## Stage 4 persistence and source-of-truth ownership

PuzzleAlarmRepository saves one cohesive schema-1 Codable document containing
definitions, PersistedSession records and detached ownership records.
DiskRepository and InMemoryRepository are actor-isolated implementations.
The Foundation-only disk adapter compiles into the existing SwiftPM product on
Apple platforms; pure state/codec/memory repository types remain platform-neutral.
No SwiftUI, AlarmKit, AppIntents, ActivityKit or camera dependency enters core.

| Fact | Authority |
| --- | --- |
| Definition configuration, weekdays, sound and timestamps | Persisted AlarmDefinition |
| Session snapshot, challenge index/counters, lifecycle, scheduling/cancellation acknowledgments | Persisted WakeUpSession |
| Session last checkpoint timestamp and engine resume input | PersistedSession wrapper |
| AlarmKit UUID ownership and intended occurrence | Persisted session plan plus operation arrays, or detached ownership when no session exists |
| Whether a UUID currently exists and its OS state | Successful AlarmKit snapshot; not the local intended status |
| Challenge completion | Controlled session transitions; never OS absence, Stop, app opening or a resume checkpoint |

ownershipLedger() derives each session's five entries from its stored plan and
operation arrays. It never persists a second copy that could disagree. Entries
include UUID, session UUID, parent UUID, ordinal, intended date and both operation
statuses. Primary/backup derives from ordinal. Detached records support ordinary
alarms without sessions and retained ownership after missing session data.
A detached record may not refer to a session already present in the document.
Duplicate UUID ownership across all sources, definitions and sessions is rejected.

PersistedSession adds updatedAt to the existing createdAt and validates it against
recorded progress/completion dates. It does not replace or reset WakeUpSession.
Optional ResumeCheckpoint belongs to the current active challenge index. Math
stores the exact problem ID, prompt and answer; progress remains in the session.
Memory stores round ID, digits, generated/visible/hidden/failed/completed phase,
and an explicit deadline only for visible state. Reload preserves phase and
deadline exactly. A future engine must evaluate elapsed time before rendering;
hidden/failed/completed must never default to visible. These are data contracts,
not challenge engines or verified future UI behavior. QR uses the saved config
token and persists no camera state. Schema evolution must precede incompatible
future checkpoint changes.

### Atomic storage and concurrency

Production location: Application Support/PuzzleAlarm/state.json.
There is no database, network, paid service or dependency. State is not wired into
the shell or startup yet. One iOS test exercises a unique Application Support
subdirectory and cleans it up.

Each commit requires the version returned by load (missing or revision UUID).
The repository rereads and validates current bytes before compare-and-swap.
A stale version returns conflict instead of overwriting newer state. The UUID is
a storage revision token, never an AlarmKit identifier. Actors serialize calls;
NSFileCoordinator exclusively covers the read/check/write transaction across
cooperating repository instances and processes. No await occurs inside it.
Only repository-coordinated access is supported; external file editors do not
participate in the protocol.

The disk adapter first atomically writes state.json.pending, then uses Foundation
Data.write(options: .atomic) to replace state.json. The same directory keeps writes
on the same filesystem. The pending file is an interrupted-write signal, not an
automatically promoted backup. Failure before replacement retains prior committed
bytes. After replacement, cleanup failure leaves a diagnostic flag, not a false
claim that the successful commit rolled back. Success means the filesystem API
accepted the atomic commit; physical power-loss durability is not proven.

Foundation behavior:
[Atomic writes](https://developer.apple.com/documentation/foundation/nsdata/writingoptions)
and [replacement coordination](https://developer.apple.com/documentation/foundation/nsfilecoordinator/writingoptions/forreplacing).
No manual truncate-and-rewrite or best-effort fallback to empty data exists.

### Recovery outcomes, not recovery actions

- Missing local file returns missing explicitly. It does not mean there are no
  AlarmKit alarms; Stage 5 must inspect a successful OS snapshot before recovery.
- A valid committed empty document differs from a missing one.
- A pending initial write with no committed document throws interruptedInitialWrite.
- A valid committed document with a pending file returns its known-good snapshot
  and interruptedWrite=true. The pending data is never silently accepted.
- Empty bytes, malformed/truncated JSON, invalid domain values and unsupported
  schema versions throw. Existing bytes are retained; commits cannot overwrite
  unreadable/unsupported state. Startup must handle this error as recovery-required.
- Reads/writes/coordination errors propagate; no failed operation reports success.
  After an ambiguous write error, reload and inspect OS state before retrying.
- InMemoryRepository also stores encoded bytes, validates on read, supports injected
  read/write errors and accepts corrupt initial bytes for tests.

ReconciliationInventory is a read-only classification against explicitly supplied
app-scoped AlarmKit IDs: recognizedPresent, persistedMissing, stalePresent,
staleMissing and potentiallyOrphanedOwned. Missing parent/session, terminal
session or confirmed cancellation makes a retained entry stale. Unknown IDs in
the app-scoped OS snapshot are potentially orphaned, not assigned invented owners.
Duplicate observed IDs are rejected. A failed OS snapshot must not be passed as [].
No scheduling, cancellation, completion, repair, cleanup or routing runs here.

If the app dies after an OS effect but before acknowledgment, the persisted
inFlight entry preserves ownership and uncertainty. Stage 5 must persist this
intent BEFORE the effect. If no local entry exists, classification can detect an
untracked app-owned UUID but cannot recover the lost session relationship from
AlarmKit metadata. Recovery policy and user-facing repair are deliberately deferred.

### Stage 4 review and limitations

Existing Stage 1/3 models are unchanged; the previously documented engine-input
gap is filled additively at the persistence boundary, not hidden by a workaround.
All ten existing session phases can round-trip, including uncertain operations.
Parent edits/deletions leave retained session snapshots and ownership intact.
Repository commits are storage operations, not permission to delete armed state:
Stage 5 must enforce business-level edit/delete/retirement rules.

Tests cover actor and separate-instance races, injected post-staging interruption,
real filesystem write failure, malformed data, unsupported schema, snapshots and
ownership invariants. They do not simulate sudden power loss, filesystem damage,
iPhone file protection, multiple real OS processes or live AlarmKit reconciliation.
A lost entire document cannot reconstruct ownership; no backup/migration framework
or automatic destructive repair is introduced. Full device acceptance remains required.

Stage 4 validation: revision 40501452d1aaf7e7e3fa03ba54d153574d560fde,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144990239.
66 tests pass, including 32 persistence tests; core coverage 99.23%.
No earlier gate invalidation. Stage 5 recovery actions remain deferred.

### Coverage-audit correction and current evidence

The coverage audit exposed a Stage 1 recurrence assumption: a timezone can omit
an entire selected weekday. OccurrenceCalculator now searches two weekly cycles
and still requires the requested weekday and local time. Failure stays explicit
if the bounded calendar search cannot produce an occurrence.
This changes no persistence schema, lifecycle, ledger or source-of-truth ownership.
Three regression tests cover skipped-date recurrence, reloaded primary/backup roles
and terminal-session late events. Gates 1–4 were invalidated and fully replayed.

Implementation: b9c87ab56df0e0e7928578d978d1c03304faa5ce
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37182114469
69 tests PASS (33 persistence), core coverage 774/779 = 99.36%.
Known platform/device limitations above remain; Stage 5 is not started.

## Stage 5 lifecycle architecture (validated implementation)

AlarmLifecycleCoordinator is the application service above the single
Foundation-only AlarmScheduling boundary and PuzzleAlarmRepository. The Apple
AlarmManagerService remains a thin translator/forwarder. Commands, recovery and
external effects are separated into source files; occurrence calculation remains
solely in OccurrenceCalculator. No UI, engine, timer, background producer or daemon
call is attached to app startup.

### Durable commands and schema

Schema 2 adds one LifecycleOperation per parent: generation UUID, immutable target
configuration snapshot, context, action (ensure/disable/delete), pending/ready/failed
outcome, target session or ordinary UUID, retiring IDs, one-time consumption and
failure reason. Parent configuration is still authoritative for current user intent;
the operation snapshot describes the generation being applied. Session and detached
ledgers remain the sole UUID ownership authority, not the command record.

Schema 1 loads with an empty operation journal and upgrades on the next successful
write. Schema 2 requires its journal key; missing/corrupt data does not become a
successful empty state. Older binaries reject schema 2 instead of discarding newer
commands. No database, server, paid service or general migration framework.

### Scheduling and rollback

An enabled challenge definition owns one concrete future session with five stable
IDs at T through T+4 minutes. The entire plan is persisted first, then each inFlight
intent before its OS call, followed by a separate acknowledgment. All five must be
acknowledged and observed before armed. A write failure after an OS success leaves
inFlight; it is not mislabeled as a schedule failure.

Failure rolls back every possibly existing owned sibling. Each cancellation has
durable intent, a fresh successful snapshot after storage awaits, then an OS cancel
if present, followed by acknowledgment. Individual OS cancellation errors do not
stop later siblings. Persistence/snapshot errors stop with uncertainty intact.
Successful absence can reconcile cancellation; it cannot complete challenges.

Explicit retry reuses the same future occurrence IDs only after full rollback.
Automatic recovery retries cleanup, not an endlessly failing schedule generation.
A clock crossing the intended wake time during scheduling fails visibly instead
of blindly scheduling an elapsed chain.

### Recovery and presence

startup loads state before requesting a snapshot. Missing differs from committed
empty; corruption/unsupported schema propagates without repair or overwrite.
Snapshot failure never becomes an empty array. inFlight + present reconciles a
scheduling acknowledgment; inFlight + absent retries the same ID when safe.
A previously armed missing chain becomes degraded, preserving its historical
scheduling acknowledgments. Future degraded chains retire conservatively; due
armed/degraded chains become active with missing-alarm issues, never completed.
Active challenge progress/snapshots remain mandatory even if every OS ID disappears.

Stale terminal ownership is retained as history; if observed again it is reported,
not assigned a new session or destructively guessed away. App-owned IDs absent from
the ledger are reported as orphaned. Foreign scope is untouched; conflict between
foreign scope and known ownership is an explicit error. Duplicate snapshots and
duplicate ledger ownership fail before OS effects. Actual Apple snapshots are
app-scoped; no custom occurrence metadata is read from them.

### Recurrence and one-time behavior

Ordinary selected-weekday alarms use one relative weekly AlarmKit schedule and
detached ownership, without a WakeUpSession. Ordinary one-time alarms use one fixed
date. The selected sound identifier reaches configuration; .caf names are a future
resource contract, not evidence of bundled files or audible playback.

Challenge recurrence remains concrete, one next occurrence at a time. After trusted
domain success enters completing, cleanup confirms every sibling before completed;
only then can next-occurrence recovery create a successor using the current calendar
context. No lifecycle API accepts an arbitrary challenge-success/complete flag.
Empty weekdays are one-time: terminal consumption durably disables the definition
and repeated startup/enable cannot accidentally rearm it. An explicit configuration
edit can create a new generation. Timezone changes affect the next occurrence,
not an already-persisted session snapshot.

### Commands and replacement safety

Enable is idempotent; existing target IDs are retained. Disable persists disabled
configuration plus retirement intent before cancellation. Delete retains the disabled
definition and all ownership until future cleanup succeeds; active sessions defer
deletion. Completed sessions and acknowledged ownership remain minimal safety history.

Edit persists desired configuration and replacement intent. It schedules the new
representation before cancelling the old future representation. A replacement
failure is visible and rolls back only the new target, leaving the old schedule.
Old-cleanup failure retains the healthy replacement and retryable old ownership.
Both mode changes follow this protocol. Due/active challenge snapshots are isolated
and excluded from ordinary edit/disable/delete retirement. A retirement already
durably initiated while future is allowed to finish; it never counts as solving.

### Concurrency, idempotency and limits

Use one live coordinator per repository for all lifecycle commands. Actor reentry
is explicitly rejected as busy across async effects. This isolates alarm lifecycle
work only, not the entire app. Storage CAS retries at most three times, reloading and
reapplying a change rather than replacing newer state. Configuration-changing
conflicts are surfaced; startup prepares the current generation. OS acknowledgments
merge into their known ledger, preserving uncertainty on persistence failure.

Semantic no-ops skip commits, UUID allocation and timestamp changes. Repeated recovery
does not schedule confirmed IDs again or recancel acknowledged cleanup. Fresh OS
snapshots are requested after storage awaits; no implementation can make disk and
AlarmKit atomic or prove daemon snapshot freshness. Separate concurrently executing
coordinator processes are outside this single-owner application boundary; future
extensions must route commands through the owner or introduce a tested OS-effect
serialization mechanism before shipping.

Device-required: authorization, actual scheduling/limits, snapshot freshness and late
OS effects, real reconciliation/Stop, lock-screen/Silent/Focus firing, intent delivery,
sound resources/playback, file protection and power loss. Simulator tests exercise
production disk + adapter composition using injected operations, never the daemon.
