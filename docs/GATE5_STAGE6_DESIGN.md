# Stage 6 design proposal — implementation not authorized

October 28, 2026. Source inspection only. Review this proposal before writing
product code. It is a deliberate management implementation, not a causal repair
claim. The unknown historical missed native input remains an unresolved acceptance
risk; no runtime experiment is necessary to describe this design, and none ran.

## Scope and authorities

Stage 6 implements list/add/edit/delete, enabled switch, weekdays, modes,
challenge configuration/order and sound-selection shell. One application-scoped
MainActor observable AlarmStore composes one Gate 5 AlarmLifecycleCoordinator,
one repository and one injected AlarmScheduling adapter. Create/edit/enable/
disable/delete/retry/startup use those existing coordinator APIs. Views never
call AlarmManager or write disk. Gate 5 persistence-before-effects, CAS,
immutable active-session snapshots, tombstones and lifecycle rollback remain
authoritative. Do not copy the later all-stage store wholesale.

Use standard SwiftUI Toggle with switch style and existing identifiers. Preserve
the editor's enabled row separate from the wheel, borderless explicit edit button,
sheet identity by alarm UUID, and original accessible semantics. No alternative
control or changed interaction is selected. One local editor draft owns unsaved
values; edit commits use coordinator.edit(replacement, expecting: original,...).
Stale/deleted original cannot recreate or overwrite newer data; explicit reload,
error, cancel and delete-confirmation remain. New draft cancel writes nothing.

## Concrete difference from the failed replacement

At preserved cfb37a8, AlarmEnabledInput owns per-view requested state, then
AlarmEnabledBinding creates a Task; AlarmStore.perform claims store.isBusy when
that task runs. Thus synchronous admission is local to a row, not shared with
save/retry/delete/refresh. This source ordering is observable without asserting
that any historical input miss came from it.

Propose a single synchronous store admission entry point for ALL management
commands. It checks stable identity and current loaded/busy state, reserves a
unique in-flight receipt and publishes isBusy plus the optional requested row
value BEFORE creating async work. The task executes an already-admitted command;
it must not re-enter an isBusy-rejecting wrapper and reject itself. There is
exactly one receipt and no unbounded queue. Foreground requests coalesce to one
refresh, run after command reconciliation, and finish before receipt release.
The coordinator's own actor admission and repository CAS remain intact.

The store, rather than a row's State object, owns the pending receipt. Retained
binding getters resolve UUID against current store state each read, overlaying
only that receipt's requested value while pending. Bindings may retain UUID/store,
never a definition snapshot as idle truth. Removed IDs read false and reject
without work. Same-value writes are no-ops. All commands share the reservation;
cross-row and editor commands cannot both claim an idle store in one MainActor
turn. A row disappearing/reordering/recreating does not destroy or replace the
admitted task. The task retains the store until completion. Scene cancellation
does not cancel an admitted persistence/effect transaction mid-command.

This protects a precise admission/lifetime invariant and removes the
per-view pending-to-async-owner handoff. It does NOT demonstrate that SwiftUI
delivers a native input or that the earlier row pending design caused a miss.
If implementation merely recreates AlarmEnabledInput under another name,
reject that implementation against this proposal.

Distinguishing proposed native contracts (not written/executed):
1. Submit row A enable then row B/delete/save before yielding: A owns the sole
   receipt synchronously, B is rejected without pending/effects; A finishes once.
2. Retain/recreate two bindings for A after admission, remove its view and reorder
   rows: both read the same receipt; only one coordinator call; completion clears
   pending even without the original view.
3. Submit refresh after reservation but before task execution: no concurrent
   coordinator call, one coalesced reconciliation, final receipt release exactly once.
4. Assert the admitted operation does not reject its own reservation, and error/
   denied/storage/partial-effect outcomes release it only after authoritative read.

These test structural differences; the unchanged original UI declarations remain
necessary to evaluate actual input. They cannot be replaced by direct setter tests.

## State transitions and recovery

| Input/outcome | Immediate presentation | Final authority and observable result |
| --- | --- | --- |
| Idle valid enable | Reserve receipt, requested On, controls disabled, busy visible synchronously | Coordinator result and fresh authoritative state determine status |
| Authorization denied | Pending On until completion | Off; access error visible; no schedules; busy/pending released; Off after relaunch |
| Write fails before effects | Pending request only | Prior persisted value; error; no invented save/OS effect; explicit new action can recover |
| Scheduling injected failure | One enable accepted | Enabled remains true where durably committed, Needs attention and Retry, never healthy On |
| Explicit product Retry | Reserve separate receipt | Coordinator.retry uses original IDs; On only after confirmed recovery |
| Disable | Pending Off | Persisted disabled; Off unless cleanup outstanding, then Cleanup pending; no invented cleanup success |
| Delete fails cleanup | Reserve, keep definition/draft until result | Error visible; definition retained, Cleanup pending; cancel editor returns retained row |
| Partial effect/ack loss | No guessed success | Reload persisted progress without extra effects; unconfirmed/attention until confirmed reconciliation |
| Duplicate/busy/stale row | Reject synchronously | No second task, no pending leak, no fabricated value |
| Corruption/future schema/read failure | Error, retain last known data as unconfirmed | Never loaded-empty success, never overwrite corruption or cancel foreign alarms |

Idle row state, status and retry availability derive from current repository
state/issues/confirmation. Pending optimism never implies scheduled health.
A failed reconciliation preserves the original error unless a more fundamental
storage error prevents authoritative reading. Release receipt in one completion
path on every returned result; never clear it from onChange/rendering.
No product-level automatic retry; only the existing explicit Retry action.

## File-level implementation boundary for a later task

| File/group | Proposed responsibility |
| --- | --- |
| PuzzleAlarm/App/AlarmStore.swift (new at this base) | Stage 6 facade, admission receipt, exact outcomes, coordinator reports/refresh |
| AlarmEnabledBinding.swift (new) | Thin UUID/live-store Binding; no row-owned pending/task |
| AlarmEditorDraft.swift, AlarmFormatting.swift, AlarmStorePresentation.swift (new) | Stage 6 data editing, labels, truthful status; adapt preserved responsibilities individually |
| ContentView.swift, PuzzleAlarmApp.swift, AppEnvironment.swift, AlarmEditorView.swift, ChallengeConfigurationEditor.swift | Application composition, stable rows/sheets, management controls and configuration only |
| UITestEnvironment.swift and native fixtures | Deterministic existing management scenarios; Debug only, absent Release |
| Core, AlarmKit adapters, OpenOccurrenceIntent | Retain Gate 5 unchanged unless separately justified earlier-gate recursion |
| SoundPreview/AlarmSoundCatalog/resources | Stage 11 deferred; Stage 6 preserves selection shell only |
| Engine, scanning, routing, orchestration files | Stages 7–13 deferred, never bundled into Stage 6 |

No product design decision is presently needed for the standard controls.
Owner review must choose whether this explicit ownership design is sufficient
to authorize implementation with the unknown input risk still unresolved.
A request to assert causal correction or guaranteed input reliability is BLOCKED
on unavailable discriminating evidence; the exhausted budgets supply no route
to gather it here.
