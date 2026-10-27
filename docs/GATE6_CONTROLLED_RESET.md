# Owner-approved controlled Gate 6 reset

Approved October 26, 2026 (America/Chicago), by the owner's task instruction.
This decision authorizes deliberate replacement development of alarm list/editor
input and UI state ownership. It is not another historical investigation or a
full rewrite. Prefer standard native controls and fewer custom bridges where
justified. Historical switch/editor causation remains unknown.

Keep this repository, Stage 13 source/tests and all historical evidence. Branch
`codex/gate6-controlled-reset` starts from the Stage 13 closeout branch at
`d65649f612bbc320fe33f369c524d9b35faaf7cd`, verified clean locally and equal to
remote. Exact-HEAD push run [40446680828](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40446680828)
is completed SKIPPED, not PASS. Remote main remains
`bd069f29c6d045d5bc27fc56212edcbde2090855`; do not promote it.

Both historical diagnostic budgets stay EXHAUSTED, zero jobs. The historical-risk
exception stays REVOKED. This authorization supersedes earlier STOP/no-redesign
instructions only for this controlled replacement and its bounded Gate 6 check.
No downstream development until Gate 6 and dependent gates are accepted.

## Required behavior

Preserve one-action correctness, exact state/pending/error outcomes,
save/reopen/relaunch persistence, retained-owner correctness, permission and
scheduling failure recovery, ten ordinary list flows and independent editor
coverage. No corrective extra taps, weakened checks or speculative unrelated
changes. Implementation-specific test changes require documented rationale and
equivalent behavioral coverage. Core/domain, scheduling and Stage 13 remain intact.

## Validation contract — declared before any push

One frozen-candidate focused Gate 6 attempt; at most two free standard macOS jobs,
40 minutes each including setup and preservation. Stop test execution by minute
35; job ceiling minute 40. Tooling failures consume allocations. No reruns,
repair-and-rerun, new diagnostic probes or budget resets. Preparation/publication
uses existing `[gate6-diagnostic] [record-only]` skips to prevent broad CI.
The dedicated reset workflow must exclude downstream gates and broad CI.

Freeze and record the immutable candidate SHA before dispatch. One job covers
owner/input contracts, ten list flows and relevant management behavior; the other
covers the independent editor. Preserve original logs, results, run/attempt/job
metadata and artifact digests on success or failure. Review source and execution
evidence separately. On any failure preserve evidence and STOP. On success report
replacement evidence and STOP: Gates 7–13 require separately scoped ordered replay.
No historical-cause, broad acceptance or physical-device reliability claim.

## Current disposition
## Replacement design and review

Remove the custom UIViewRepresentable/UISwitch target-coordinator bridge. Both
surfaces use explicit standard SwiftUI switch controls. List input has one
observable pending-request owner; no duplicated idle Bool or render-time onChange
reconciliation. A retained binding reads the current store by stable alarm ID when
idle, and command completion drops the pending request after the store reconciles.
Removed rows reject commands; busy/pending input rejects duplicates synchronously.
No persistence/OS authority moves out of AlarmStore. The editor keeps one local
draft, explicitly identifies sheet content, and separates enabled/repeat rows from
the time-wheel section. The list edit button uses standard borderless styling.
These are deliberate layout/ownership choices, not historical causal findings.

Implementation-specific test rationale: the deleted NativeAlarmSwitchTests tested
target wiring/rebinding/disabled-event/teardown mechanics of the removed bridge.
There is no app-owned target or teardown after replacement. Its behavioral duties
are covered by unchanged real native-role UI inputs/exact values, new retained
input/current-owner/removal and busy-owner tests, and the adapted existing
synchronous pending/outcome test. That test retains every original assertion and
adds persistence-write failure/recovery. Original retained-owner and completion
tests remain production-path tests. All original management UI source/helpers,
single taps, exact enabled/hittable/value/status/error and relaunch checks remain
byte-for-byte unchanged. Stage 13/Core/AlarmKit/intent sources/tests are untouched.

Focused execution is partitioned once: list job runs AlarmStoreTests,
AlarmEnabledInputTests, AlarmEditorDraftTests and PersistenceIntegrationTests,
then the original list flow ten times, then the other nine management declarations.
The independent cold editor job runs the original editor declaration once.
The two exclusions in the management invocation avoid duplicating the declarations
already assigned to ten-list/editor; no required case is dropped. No Gates 7–13,
Math/Memory/QR UI suites or broad workflow is dispatched. All push commits carry
the existing record-only skip markers; ordinary ios.yml also explicitly excludes
this branch (push/PR/dispatch), preventing accidental broad allocations. Ten-list
adds only the installed-Xcode-supported `-run-tests-until-failure` stop condition to
the original ten iterations: any failed iteration ends the declaration instead of
continuing repetitions. The option signature is preserved in the historical
`evidence/gate6-repaired-single-editor-39199089437/xcodebuild-help.txt`.
The wrapper enforces an absolute minute-34
test deadline (one minute margin before the owner ceiling), including previous
setup/invocations; timeout shuts down the selected Simulator and fails closed.
Matrix fail-fast cancels the other lane on failure; preservation runs with always().

Self/adversarial source review: retained snapshots are used only for identity at
the existing owner command boundary; idle reads use live state. Pending is claimed
before spawning async work, remains across view rendering, rejects duplicate input
and is cleared on every returned owner outcome. Store removal/external updates
cannot leave a cached idle value. The unstructured command retains the input owner
until completion if its view disappears. No new lifecycle/schema/scheduling owner,
generated probes, test-helper changes, corrective input or waits were introduced.
Windows has no Xcode/Simulator; source review is not execution acceptance.

Offline preparation: four mocked Python wrapper checks PASS (exact SHA/status
preservation, original failure/no retry, already-expired budget/no start, deadline
process-group termination plus selected Simulator shutdown). Initial Windows sandbox
attempt failed on temporary-directory access before exercising the wrapper; the
same unchanged checks passed with normal temporary-directory access. This is local
pre-freeze tooling evidence, zero macOS allocations or product test executions.

## Current disposition

Decision persisted before implementation. Gate 6 remains FAILED / HELD pending
replacement validation; Gates 7–13 INVALIDATED / HELD; last unheld gate 5.
Source/automated/Xcode/Simulator/device evidence will be recorded separately.
