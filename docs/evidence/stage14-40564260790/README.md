# Stage 14 attempt — STOP at Gate 6 failure

Frozen tested candidate **`62c8953fdcd915ebdac8cb5838799e0b2f64389e`** on
`codex/stage-14-resilience`, preserving accepted source `f01abf42` and its record-only
descendant `2cb81a6`. [Run 40564260790](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40564260790),
push, attempt **1**, completed **FAILURE**. Exact run identity is in [run.json](run.json)
and the [pre-push freeze](candidate.json). This is not a CI PASS.

[Stage scope, audit and pre-execution contract](../../STAGE14_RESILIENCE.md).
No product/Core/UI source, original assertion, retry allowance or diagnostic budget
was changed. Six Stage 14 boundary declarations were added after auditing existing
coverage. Source/tests remained frozen throughout this single attempt.

## Observed failure and recursive disposition

The first of ten declared ordinary list executions failed:
`AlarmManagementUITests.testEnableDisableAndFailureRetryAreHonest`, 87.936 seconds,
`AlarmManagementUITests.swift:181`. The original helper tapped the concrete `"0"`
switch once and awaited the expected `"1"`; its predicate timed out, and the
failure hierarchy still showed row status **Off**. The unchanged ordinary fixture
journal records launch only. Those observations establish an input assertion
failure; they do **not** identify a product, harness or OS root cause.

The remaining nine list executions did not run because the original batch stops
on first failure. The matrix's fail-fast cancelled the independent editor lane
before a completed test result; it is **CANCELLED / INCOMPLETE**, neither PASS nor
a demonstrated editor assertion failure. Original partial output is preserved.
The dependent validate job was **SKIPPED with no steps**, not an allocated Mac job.
No Stage 14 test execution or complete regression occurred.

**Gate 6 FAILED / HELD; Gates 7–14 recursively INVALIDATED / HELD. Last unheld gate 5.
Stage 14 BLOCKED / NOT ACCEPTED. STOP.** Historical switch/editor diagnostic budgets
remain **EXHAUSTED, zero jobs**; historical-risk exception remains **REVOKED**.
No new diagnostic, speculative source repair, extra tap, assertion relaxation,
failed-test rerun, retry-to-green or further CI allocation was performed.
The earlier Gates 6–13 acceptance at `f01abf42` / run 40521565094 remains immutable
historical evidence; it cannot clear this candidate's new failed prerequisite.

## Evidence classes

| Class | Exact candidate result |
| --- | --- |
| Source | Nine requested failure categories audited; six missing boundary declarations and focused CI selection added. Product/Core/OS adapters/schema and original tests/assertions retained. |
| Local automated | Workflow YAML parse, original required-step/order equality, original test-body equality, product/Core/UI source equality and authored whitespace checks PASS; four existing mocked budget/failure/no-retry checks PASS. No local Swift toolchain. |
| Xcode | Xcode 26.6 / 17F113, Swift 6.3.3, macOS 26.6.2. Debug app and test targets compiled, including all six additions. Release, broad SDK/resource/plist checks and final warning audit NOT RUN. Compilation does not establish new test behavior. |
| Simulator native | iPhone 17 / iOS 26.5: all **37** existing focused owner/input/draft/persistence contracts PASS. |
| Simulator UI | List iteration 1 FAILED as above; iterations 2–10 NOT RUN. Independent editor cancelled without a result. No dependent Gate 6 management replay, Gates 7–13, focused Gate 14, full Core/native/UI regression or coverage acceptance. |
| Physical device | **DEVICE REQUIRED / NOT RUN**. No real AlarmKit delivery, Stop/Solve, backup, lock/first unlock, hardware input, camera/audio, process-kill or reliability acceptance. |

## Allocation and original preservation

[Jobs and steps](jobs.json); [reviewed summary](reviewed-summary.json).
Two free standard public `macos-26` jobs were allocated:

| Job | Result | Actual including preservation | Ceiling |
| --- | --- | --- | --- |
| list 122401177541 | FAILURE | 11m15s | 40m |
| editor 122401178201 | CANCELLED | 12m21s | 25m |

The list command failed with original exit 65 before its absolute +34-minute
deadline. The editor was cancelled before its +19-minute command deadline; its
interrupted command has no final wrapper JSON or completed result claim. The
dependent 85-minute lane was skipped. No unused-allocation rollover or additional
attempt is claimed. [Original list command records/logs](list/acceptance-steps/)
and [editor partial output](editor/acceptance-steps/) remain unchanged.

Both full original Actions job logs ([list](list-actions.log), [editor](editor-actions.log)),
run/job/step/artifact metadata, toolchains, ordinary fixture journals, command
bodies/logs/available completion records and **both original ZIPs are published in
Git**. [SHA-256, byte sizes, CRC checks and expiry manifest](integrity.json).

| Original artifact | Bytes | Original SHA-256 | Actions expiry (UTC) |
| --- | --- | --- | --- |
| [acceptance-list 12762358001](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40564260790/artifacts/12762358001) | 52,345,939 | `9ce45a99545494272d35ca02af488150e783b7016d106321c45f521b226e23a2` | November 26 19:05:11 |
| [acceptance-editor 12762682631](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40564260790/artifacts/12762682631) | 3,321,746 | `f399ead8468b323d538c3338db865cefda3d6557a86bf7769b8024316aec3ab1` | November 26 19:05:58 |

The editor ZIP contains cancellation-time staging/diagnostics and partial output;
it is not a successfully finalized editor xcresult. Both ZIP digests match the
Actions metadata and CRC checks pass. Local originals/extractions also remain in
`TestResults/Stage14/`. Initial Windows editor extraction exceeded ordinary path
length; extraction using the Windows extended-path prefix succeeded without
changing the ZIP. This was local archive handling, not a test rerun or Mac job.

Evidence-only publication is a separate record-only descendant. Its skipped CI is
not new product evidence. Main remains `bd069f29c6d045d5bc27fc56212edcbde2090855`,
unpromoted. No Stage 15, UX redesign or device acceptance. **STOP after closeout.**
