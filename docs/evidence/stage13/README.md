# Stage 13 candidate validation

## Final outcome — STOP at failed Gate 6 prerequisite

Candidate `2b2c81d2277f05eb5d095beb0285d47e58a73cb4` was declared in this task
and `candidate.json` before its successful push. One push run
[40445144617](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40445144617),
attempt 1, ran at that SHA. The editor prerequisite test step FAILED. Remaining
work was explicitly cancelled: actual workflow and all three job conclusions are
**CANCELLED**, with the editor step still **FAILURE**. No rerun/dispatch occurred.
The final documentation-only descendant is a separate publication revision, never
substituted for this tested candidate. Its exact SHA belongs in the final task
report/Git history; existing record-only markers avoid a second validation attempt.

Exception reliance is **REVOKED** for this candidate. Earliest affected Gate 6 is
FAILED / HELD; Gates 7–13 recursively INVALIDATED / HELD; last unheld gate 5.
Both diagnostic budgets remain EXHAUSTED, zero jobs. No current failure is waived.
No further development, diagnostic experiment, validation or device action queued.

The independent editor declaration
`testEditorEnabledTogglePersistsAfterRepeatedNativeInput` failed once, 188.222s,
at AlarmManagementUITests.swift:181. Its original eleven initial inputs, On save
and On after relaunch reached the later row-opening step. That row opened. Its
single declared post-relaunch On→Off tap left the native `editor.enabled` value
at `1`; the existing expectation for `0` timed out. No remedial tap or assertion
change. The expected input outcome was missed; no current product, harness or OS
cause is established. This does not demonstrate saved-editor-opening recurrence.

| Evidence category | Actual result at candidate |
| --- | --- |
| Source / local static | Shared final-sequence handoff and A–J integration coverage reviewed; source/workflow-order static checks PASS; no Windows Swift product test execution |
| Xcode | Xcode 26.6, SDK iOS 26.5; Debug app/native/UI test targets compiled, including new integration tests. No broad Debug/Release/SDK/resource/fixture gate pass |
| Native contracts | Four existing tests PASS: retained owner binding, command completion, synchronous pending/reconciliation, native wiring/rebinding/disabled events/teardown |
| Simulator independent editor | iPhone 17 / iOS 26.5, one declaration FAILED as above |
| Simulator ten-flow switch invocation | Iterations 1–4 completed PASS; iteration 5 started and was interrupted by cancellation; requirement incomplete |
| Broad ordered Gate 6–12 / full Core / Gate 13 / full relevant regression | Dependent validate job has no executed steps; NOT RUN, no PASS |
| Physical device | DEVICE REQUIRED / NOT RUN; all original acceptance requirements retained |

New A–J behavior is meaningfully mapped in TEST_MATRIX but unexecuted. No coverage
result for the candidate exists; the earlier source audit below is not execution
proof. The failure is at the input prerequisite, before new challenge orchestration
is exercised. Source review is insufficient to assert causation or clearance.

## Preserved evidence and accounting

`run.json`, `jobs.json` and `artifacts.json` retain exact source/run/attempt,
final job/step conclusions, artifact IDs/digests/sizes/expiry. Complete original
`editor.log` and `switch.log` and the original switch ZIP are published here.
The original failed editor ZIP is preserved locally at:

`TestResults/Stage13-40445144617/editor-toggle-simulator-evidence.zip`

Its 87,264,090 bytes are not published in Git. This local original and the Actions
artifact retain the failed xcresult; do not describe that ZIP as Git-archived or
permanently hosted. Both original ZIP hashes match Actions digests:

| Artifact | SHA-256 | Preservation |
| --- | --- | --- |
| [Editor 12707858472](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40445144617/artifacts/12707858472) | `d18b45c7a02e1f6398c103409eeee04267d04b74c071ded9dedeaa09b5ee36ff` | Exact original local ZIP + Actions, expires November 2 America/Chicago (November 3 UTC) |
| [Switch 12708960232](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40445144617/artifacts/12708960232) | `cb8daf82cc376ede662afbb242c9298e09ce5f132717e01e17e84e08067aa851` | Exact original ZIP in this Git archive + Actions, same expiry date |

Two macOS prerequisite jobs were allocated. The dependent job has zero executed
steps; no broad runner execution is claimed. Existing ordinary fixtures/journals
only, no generated probes. Four completed switch UI executions plus a fifth
started/interrupted; one completed failed editor execution; four focused native
contract executions PASS. No agent-initiated test invocation/resume after stop;
the in-flight fifth execution was interrupted by cancellation. No rerun.
Optional raw ancestry/video completeness is not claimed. Local logs were saved
with original terminal escapes after gh's initial output refusal; that evidence
download repair did not execute tests or allocate a runner.

Initial direct Git publication failed because its configured temporary gh helper
was absent; connector blob publication returned 403 before any object was created.
Official free gh 2.102.0 was restored in a temporary directory and existing keyring
authentication reused with a per-command helper override. Candidate source/commit
never changed and only one successful push triggered validation. No credentials,
tokens or signing material were stored in the repository or printed unmasked.

## Preparation record (historical; pending labels below superseded)

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
