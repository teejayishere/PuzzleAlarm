# Project state

Current stage: 4 — Persistence and Recovery Architecture
Current gate: RECURSE to Stage 1 — recurrence horizon correction pending CI
Last known passing gate: Gate 4 at 4050145 (evidence below)
Invalidated gates: Gates 1–4 pending coverage-audit regression replay
Current blockers: None
Current version/status: Native shell plus persistence and unconnected AlarmKit adapter

## Observed Stage 4 evidence

Revision: 40501452d1aaf7e7e3fa03ba54d153574d560fde
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144990239
Result: PASS. Focused persistence: 31 tests. Full core: 57 tests.
iOS: seven AlarmKit capability tests, one disk integration test, one UI launch test.
Total: 66 test functions (focused repeat and parameterized cases not double-counted).
Core coverage: 771/777 lines = 99.23%.
Xcode 26.6 / iOS 26.5; standard free macos-26 runner.
All generation, package, iOS build, usage-description and diagnostic checks passed.
No compiler/destination warnings; one known UI-test SDK metadata advisory.

Persistence total: 32 tests (31 core plus one iOS integration).
Final adversarial additions passed, including exact conflict assertions.
The recorded revision is the final source/test implementation. Documentation-only
follow-ups also require matching successful full CI before acceptance; inspect
the current HEAD run rather than assuming the named run covers later changes.

## Architecture and recovery status

One schema-1 document persists definitions, session snapshots, engine resume
inputs, timestamps and ownership. Session ledger entries derive from persisted
plans/status arrays; detached records retain ownership where no session exists.
One UUID cannot have multiple ownership records.

DiskRepository and InMemoryRepository use actors and revision compare-and-swap.
Disk commits coordinate read/check/write, stage an interruption marker and
atomically replace the document in Application Support. Corruption/future schema
blocks overwrite. Missing state is explicit and never treated as proof that
AlarmKit contains no alarms.

The read-only reconciliation inventory represents recognized/missing/stale and
potentially orphaned app-owned IDs. It performs no scheduling, cancellation,
completion or repair. Math/Memory resume data is persisted; no engines or UI exist.

## Earlier gates

Gate 0–3 revalidated in the Stage 4 run above, including all 26 original core
tests and seven AlarmKit tests. Original Stage 1 domain files and Stage 3 adapter
are unchanged. The persistence wrapper extends the intentionally deferred
checkpoint data; no earlier model assumption was disproved.

Gate 3 exact starting revision:
6be4415148445f83a1879d2a219d3667327bcffc
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37096261777

Gate 2: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37035827761
Gate 1: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945373495
Gate 0: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36943963689

## Known limitations and device requirements

- Shell remains unchanged; persistence is not connected to startup/product UI.
- Stage 5 scheduling, reconciliation actions and business-level deletion rules
  are NOT STARTED. No alarm daemon or permission calls execute in tests.
- Missing/corrupt entire state cannot reconstruct ownership from AlarmKit metadata.
  Errors must lead to future recovery UX, never silent reset.
- Memory phase preservation is tested; engine timing/rendering is deferred.
- Atomic tests cover injected post-staging interruption and real I/O failures,
  not physical power loss or filesystem damage.
- Concurrency is tested across actors/instances, not real separate processes.
- iPhone file protection, authorization, firing, lock screen, Focus/Silent,
  intent delivery, live reconciliation and sound playback remain DEVICE REQUIRED.
- No paid tools, large Windows toolchain, dependencies or signing material added.

## Next action

STOP after Gate 4 once the current documentation-only HEAD has matching green CI. Stage 5 requires a new instruction.
See ARCHITECTURE.md, TEST_MATRIX.md and DEVELOPMENT_LOG.md for contracts/evidence.
