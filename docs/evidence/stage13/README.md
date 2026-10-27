# Stage 13 candidate validation

## Authorization and limits — October 26, 2026 (America/Chicago)

The project owner explicitly authorized Stage 13 development and changed-candidate
validation under MASTER_PLAN §6, retaining ownership of the unexplained historical
alarm-switch and saved-editor-opening risks. This authorization covers Stage 13
candidates only, excluding main promotion, release and device acceptance. Exact
changed candidate SHAs must be declared before validation. This is separate from
the earlier approval limited to `3b6c44a98c9553021b8d26d7568765b6aa5e1210`.

The original failures and capture limits remain in the linked historical archives
in PROJECT_STATE and GATE6_DIAGNOSTICS. Their causes remain unknown. Both diagnostic
budgets are EXHAUSTED with zero allocations remaining. Any recurrence revokes
exception reliance, reopens the earliest affected gate and recursively invalidates
dependents. No speculative remedy, new diagnostics or budget reset is authorized.

## Baseline verification

Clean local HEAD and independently queried remote `codex/stage-12-routing` both
equal `b98b5c516b0bd554107f21786b700b6059c55a92`. Remote main remains
`bd069f29c6d045d5bc27fc56212edcbde2090855`. New local
`codex/stage-13-orchestration` was created from the requested published commit.
No unrelated local changes existed or were discarded.

Exact-baseline push [run 40444060227](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40444060227)
is completed SKIPPED, attempt 1, not PASS. The commit-workflow connector returned
an empty list; direct GitHub Actions REST lookup by head_sha found this run.
Historical run 40118586010 applies only to its original tested SHA.

## Declared candidate procedure

Commit the complete reviewed implementation, tests, workflow and pending evidence.
Record that immutable SHA in `candidate.json` before pushing. That push allocates
one ordinary uninstrumented validation attempt at that exact SHA. No dispatch or
rerun in addition to push CI. Keep the candidate frozen while CI runs.

The existing two independent cold prerequisites retain all four binding/native
contracts, ten original switch flows and independent editor persistence. The
dependent job retains ordered Gate 6 management before downstream flows, Core,
Debug/Release, SDK/resources/plists, fixture exclusion, full native/UI regression
and diagnostics. Gate 13's ten integration declarations run after Gate 12 and
again as part of the existing full regression; this is planned focused/full
coverage, never a failed-test retry. Any required failure stops advancement.

## Evidence categories (before candidate execution)

- Source: shared durable-whole-sequence handoff; existing lifecycle implementation
  reused. A–J integration tests and exact effect/durable-state assertions added.
- Automated local: no Swift toolchain available on Windows. Source/diff review only;
  no product test PASS claimed. Candidate automation runs on free public macos-26 CI.
- Xcode: NOT RUN for the new candidate yet.
- Simulator: NOT RUN for the new candidate yet.
- Physical device: DEVICE REQUIRED / NOT RUN. Real Stop, backup delivery/cancellation,
  AlarmKit/Solve launch, lock/first unlock, hardware inputs, camera/audio and free
  provisioning are unverified. An injected OS snapshot is not physical evidence.

## Review and meaningful uncovered behavior

The real AlarmStore, challenge engines and DiskRepository compose in all scenarios.
No test directly mutates session progress/completion to simulate a successful solve.
Boundary fakes store scheduler effects and inject failures, without implementing
reconciliation, rollback, completion or recurrence policy. G/H reopen new repository
and store instances from disk after acknowledgment loss; they model interruption
boundaries, not process-kill or physical power-loss proof.

Three three-engine orders put Math, Memory and QR each at the final boundary. D
checks a stale callback and new-owner restoration at the intermediate boundary.
F checks every cancellation continues, absence of false completion/successor, and
the product cleanup retry. G/H assert stable identity and no repeated successful
OS effect. I protects an active immutable snapshot while the edited future chain is
scheduled; J checks disabled recurrence after completing the retained obligation.

Earlier suites retain all order permutations, one-time consumption, calendar/DST,
ownership/CAS conflicts, denied access, late callbacks, checkpoint failures and
engine-specific behavior. This task does not duplicate those assertions or seek
100% coverage. Arbitrary process termination/interleavings, disk hardware durability,
real AlarmKit daemon behavior and device-only observations remain unverified.

Self-review: no Core framework coupling/schema change, second owner, new timer,
unbounded queue, diagnostic instrumentation, original assertion edits or UX change.
Cleanup is still persistence-before-effects; partial cancellation cannot complete
the occurrence or schedule a successor. Exceptions remain limited to historical
uncertainty; current failures cannot be waived.
