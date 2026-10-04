# Project state

Current stage: 4 — Persistence and Recovery Architecture; coverage audit complete
Current gate: Gate 4 — PASS at the implementation revision below
Last known passing gate: Gate 4 at b9c87ab
Invalidated gates: None remaining; Gates 1–4 invalidated and replayed during this audit
Current blockers: None
Current version/status: Native shell plus persistence and unconnected AlarmKit adapter

## Observed current evidence

Revision: b9c87ab56df0e0e7928578d978d1c03304faa5ce
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37182114469
Result: PASS. Focused persistence: 32 tests; focused domain audit: two tests.
Full core: 60 tests. iOS: seven AlarmKit capability tests, one disk integration,
one UI launch. Total: 69 distinct tests; persistence total: 33.
Core coverage: 774/779 line counts = 99.36%.
Xcode 26.6 / iOS 26.5; standard free macos-26 runner.
Package, generation, iOS build, usage-description and diagnostic checks pass.
No compiler/destination warnings; one known UI-test SDK metadata advisory.

This immutable run proves the final source/test implementation. Documentation
follow-ups also require successful full CI for their own SHA before acceptance;
the final task report links that exact-HEAD run.

## Coverage audit and recursion

Baseline 771/777 is fully accounted for in TEST_MATRIX.md: four wholly uncovered
lines plus two unreachable nil-coalescing autoclosures counted separately by SwiftPM.
Three meaningful regressions were added: restored primary/backup ownership,
completed-session late-event replay, and recurrence across a skipped local date.
The last exposed a Stage 1 seven-day horizon defect. Gates 1–4 were invalidated,
the horizon corrected to two weekly cycles, and all affected gates replayed.
No persistence schema, lifecycle or ownership authority changed.
The error fallback remains fail-closed; no coverage threshold was changed.

## Persistence and recovery status

A schema-1 document persists definitions, session snapshots, resume inputs,
timestamps and ownership. Session ledger entries derive from persisted plans/status
arrays; detached records retain ownership where no session exists. Duplicate UUID
ownership is rejected.

DiskRepository and InMemoryRepository use actors and revision compare-and-swap.
Disk commits coordinate read/check/write, stage an interruption marker and atomically
replace the Application Support document. Corruption/future schema blocks overwrite.
Missing state does not prove that AlarmKit contains no alarms.

Read-only reconciliation represents recognized/missing/stale and potentially orphaned
app-owned IDs. No scheduling, cancellation, completion or repair actions are wired
into the app. Math/Memory resume data is stored; engines and product UI do not exist.

## Prior gate evidence

Gates 0–3 replayed in the current full run, including Stage 1 tests plus new domain
regressions, generated iOS build, AlarmKit/AppIntents, platform tests and shell launch.

Original Gate 3 base: 6be4415148445f83a1879d2a219d3667327bcffc
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37096261777
Original Gate 4 implementation evidence remains historical, not a substitute for
the recurrence correction's current run.

## Known limitations and device requirements

- Stage 5 scheduling, reconciliation actions and business-level deletion rules
  remain NOT STARTED. Persistence is not connected to startup/product UI.
- Lost/corrupt state cannot reconstruct ownership from AlarmKit metadata.
- Memory phase persistence does not prove engine timing/rendering.
- Atomic tests cover staged interruption and I/O errors, not physical power loss.
- Concurrency covers separate actors/instances, not real separate processes.
- Application Support unavailability/timezone database replacement cannot be
  forced through the existing production APIs without artificial platform mocks.
- Recurrence search is bounded to two weekly cycles; unexpected calendar failure
  throws rather than substituting a weekday or reporting a successful schedule.
- iPhone file protection/storage availability, authorization, firing, lock screen,
  Focus/Silent, intent delivery, live reconciliation and sound remain DEVICE REQUIRED.
- No paid tools, large Windows toolchain, dependencies or signing material added.

## Next action

STOP after the final documentation revision has matching green full CI.
Stage 5 requires a new instruction.
