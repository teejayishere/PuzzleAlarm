# Project state

## Active scope — owner-approved controlled Gate 6 reset

**[Controlling decision and frozen validation limits](GATE6_CONTROLLED_RESET.md).**
Replacement development is authorized on `codex/gate6-controlled-reset` from the
Stage 13 closeout. Main, Stage 13 source/tests and historical evidence are preserved.
Gate 6 remains FAILED / HELD; Gates 7–13 INVALIDATED / HELD. Historical budgets
remain EXHAUSTED and the exception REVOKED. Earlier STOP entries remain historical;
the linked decision governs only this replacement. No downstream work is authorized.

Replacement source prepared: standard SwiftUI switches, one observable pending
input owner with live idle store reads, editor input separated from the time wheel,
explicit edit-button/sheet identity. Original management UI assertions/helpers are
unchanged; bridge-specific tests replaced with documented behavioral equivalents.
Four offline budget-wrapper checks and parsed workflow limits/exclusions PASS.
Swift/Xcode/Simulator execution PENDING for the frozen candidate; device NOT RUN.
Dedicated guarded-push workflow allows only two focused Gate 6 jobs; broad CI excludes
this branch and preparation uses record-only skips. No Gates 7–13 replay authorized.

## October 26, 2026 — Stage 13 STOP at Gate 6 input failure

Current stage: 13 implementation candidate, **BLOCKED / NOT ACCEPTED**. Gate 6 is
FAILED / HELD. Gates 7–13 are recursively INVALIDATED / HELD; last unheld gate 5.
Exception reliance is REVOKED for this candidate after a current native-input
assertion failure. Both historical diagnostic budgets remain EXHAUSTED, zero jobs.

Tested/pushed candidate: `2b2c81d2277f05eb5d095beb0285d47e58a73cb4`, on
`codex/stage-13-orchestration` from published `b98b5c516b0bd554107f21786b700b6059c55a92`.
[Run 40445144617](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40445144617),
attempt 1, push: editor prerequisite step **FAILED**; the workflow was explicitly
cancelled to stop further work. Actual final Actions conclusion is **CANCELLED**
(all three jobs cancelled), not SUCCESS. The editor step's recorded failure remains
failure; cancellation does not erase it. No rerun or new diagnostic occurred.

The original independent editor declaration failed at AlarmManagementUITests.swift:181,
188.222 seconds: after On save/relaunch and successful row reopening, its ordinary
On→Off tap left `editor.enabled` at `1` instead of `0`. This is a Gate 6 input
failure, not evidence of a saved-row-opening failure or a proven OS/product cause.
No corrective extra tap, test weakening or speculative source remedy was made.
Four focused binding/native contracts PASS. Four of ten declared switch flows
completed PASS; the fifth started and was interrupted by cancellation. The ten-flow
requirement is incomplete. The dependent validate job had no executed steps.

Source: shared final-sequence handoff plus ten A–J disk/application integration
declarations remain committed and unaccepted. Xcode 26.6 / iPhone 17, iOS 26.5:
Debug app and test targets compiled, including the new integration suite; this
does not establish Stage 13 behavior. Core full regression, ordered broad Gate 6–12,
Gate 13 A–J, Release/SDK/resource/fixture checks and full native/UI regression were
NOT RUN in the dependent job. No Gate 13 success or complete CI pass is claimed.

Complete original logs, run/job/step/artifact metadata and the switch ZIP are in
[the evidence archive](evidence/stage13/README.md). The original failed editor ZIP
is preserved locally under `TestResults/Stage13-40445144617/`, with SHA-256 matching
Actions; its 87 MB ZIP is not published in Git. Artifact retention limits are explicit.
The final documentation-only publication SHA is reported separately from the tested
candidate; record-only skipped CI is not new product evidence.

Main remains `bd069f29c6d045d5bc27fc56212edcbde2090855`, unpromoted. Stage 14 and
UX redesign NOT STARTED. Physical-device acceptance remains DEVICE REQUIRED / NOT
RUN for all previously recorded requirements. STOP at this blocking failure; no
further development, validation, diagnostics or device action is queued.

## Earlier candidate preparation (superseded by STOP above)

## October 26, 2026 — Stage 13 candidate preparation

Current stage: 13, development authorized under the owner's new MASTER_PLAN §6
historical-risk exception scope for Stage 13 candidates. The owner retains the
unexplained historical switch/editor risks. Source is implemented; Gate 13 and
changed-candidate Gate 6–12 validation are PENDING, not PASS. Last unheld gate
outside the exception remains 5. Original failures/holds remain historical evidence;
recurrence revokes reliance and recursively reopens affected gates. Both diagnostic
budgets remain EXHAUSTED, zero jobs available.

Clean local/remote baseline verified at `b98b5c516b0bd554107f21786b700b6059c55a92`;
branch `codex/stage-13-orchestration` created from it, not main. Baseline exact CI
40444060227 is SKIPPED, not PASS. No unrelated local work was present or discarded.
Remote main `bd069f29c6d045d5bc27fc56212edcbde2090855` is not promoted.

All three engine completion paths share a saved-whole-sequence boundary before
entering existing launch/foreground reconciliation. Intermediate challenge success
preserves backups without requesting lifecycle effects. Existing lifecycle owner,
rollback, cancellation journal, next-occurrence scheduling and recovery are reused.
Ten native disk/application integration declarations cover Gate 13 A–J. CI adds a
focused Gate 13 step after Gate 12 before the unchanged full regression.

Source review only locally; Swift/Xcode/Simulator candidate execution PENDING on
public free CI. Exact candidate SHA will be recorded before its single push-triggered
validation; no rerun, retry-to-green, extra taps, weakened checks or skipped valid
tests. Required failures stop advancement. See [procedure, authorization, review
and evidence](evidence/stage13/README.md) and TEST_MATRIX for test mappings.

Physical-device requirements remain DEVICE REQUIRED / NOT RUN, including real
AlarmKit/Stop/Solve delivery, backups, lock/first unlock, hardware input,
camera/audio and provisioning. No Stage 14, UX redesign, release, main promotion or
device acceptance. Stop after Gate 13 or a blocking failure.

## Earlier evidence (revision-specific)

## October 26, 2026 — documentation-only validation closeout

Published the October 24 evidence below using the existing `[gate6-diagnostic]`
`[record-only]` mechanism on `codex/stage-12-routing`. The tested source commit
remains `3b6c44a98c9553021b8d26d7568765b6aa5e1210`; this documentation
descendant is a separate publication revision, not a newly validated product.
Its immutable SHA is available in Git history and the publication report.

Read-only GitHub REST verification on October 26 confirmed run **40118586010,
attempt 1**, `workflow_dispatch`, completed SUCCESS at that exact tested SHA;
all three jobs and every step succeeded. Existing local archive hashes matched.
No validation was repeated and no runners were allocated by this closeout.
Documentation CI skipped by the record-only mechanism is not product PASS evidence.
Source, tests, assertions and workflows are unchanged; main was not promoted.

The [prior owner approval](evidence/gate6-12-exception-40118586010/APPROVAL.md)
explicitly assigns residual intermittent switch/editor risk to the project owner.
Stage 13 development eligibility exists **solely under that approved exception**,
not ordinary root-cause clearance. Stage 13 is NOT STARTED; this closeout authorizes
publication only and stops here. Future Stage 13 implementation needs a new task
within that exception scope. A changed source candidate needs its own approval
scope and complete ordered validation; a documentation descendant does not extend
the old run's exact-SHA claim.

Historical causes remain unknown; original failures, capture limitations and
dependent product-acceptance holds remain preserved. Both diagnostic budgets remain
EXHAUSTED with zero jobs available. Any recurrence revokes exception reliance,
reopens the earliest affected gate and recursively invalidates dependents without
resetting those budgets. Critical invariants remain binding. Physical-device
acceptance is still DEVICE REQUIRED / NOT RUN, including actual AlarmKit/Solve
delivery, lock/first unlock, Stop, backup firing/cancellation, hardware input,
camera/audio and free provisioning. No release or product/device acceptance.

[Durable evidence archive and preservation limits](evidence/gate6-12-exception-40118586010/README.md).

## October 24, 2026 — approved exception, single validation PASS

The project owner separately approved MASTER_PLAN §6 for the unexplained historical
alarm-switch and saved-editor-opening failures at exact candidate
`3b6c44a98c9553021b8d26d7568765b6aa5e1210`, accepting residual intermittent
input/editor risk solely for possible Stage 13 development. The earlier
NOT GRANTED / NOT INVOKED entries below describe prior tasks and are superseded
only within this exact approval scope.

[Run 40118586010](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40118586010),
`workflow_dispatch`, attempt 1: complete SUCCESS, all three jobs/every step.
One declared ordered uninstrumented Gate 6–12 validation attempt; no rerun,
retry-to-green, extra taps, weakened assertions, generated probes or source changes.
Local/remote candidate SHA verified; existing exact-SHA push CI 39473575030 was
SKIPPED and was not used as pass evidence.

Source: live-owner retained getter, pending reconciliation, native wiring and
teardown reviewed; original regressions/assertions retained. Automated macOS:
four focused native contracts, ten switch flows, independent editor persistence,
148 Core tests and ordered focused suites PASS. Xcode 26.6 / Swift 6.3.3:
Debug/Release, SDK/resources/plists and Release-fixture exclusion PASS.
Simulator iPhone 17 / iOS 26.5: management before downstream Math/Memory/QR/routing,
then full 68 native + 20 UI regression PASS; final diagnostics/coverage/resources
and evidence uploads PASS. Physical device NOT RUN / DEVICE REQUIRED.

Gate 6–12 execution requirements are satisfied **under the approved exception**
at this SHA, permitting only exception-scoped Stage 13 development eligibility.
Historical causes remain unknown, historical failures and dependent product
acceptance holds remain recorded, and no ordinary root-cause clearance is claimed.
Last unheld gate outside the exception remains 5. Recurrence revokes reliance,
reopens the earliest gate and recursively invalidates dependents; no diagnostic
budget reset. A changed candidate needs its own approval/complete validation.
No main promotion, release, product/device acceptance or Stage 13 implementation.
Stage 13 NOT STARTED. STOP after this validation gate.

[Complete result, original log archive, artifact links/digests and preservation limits](evidence/gate6-12-exception-40118586010/README.md).
The validation task originally left documentation uncommitted to preserve candidate
HEAD; the October 26 documentation-only closeout above publishes that record.

## Previous state before separate owner approval (historical)

Current stage: 12, recursing to the unresolved Gate 6 native-input boundary.
Gate 6 is FAILED; dependent Gates 7–12 are INVALIDATED / HELD. Last unheld gate: 5.
Stage 13 NOT STARTED. A later green run alone cannot clear a known unexplained failure.

## October 19, 2026 — bounded investigation policy, documentation STOP

This revision changes documentation policy only. MASTER_PLAN §§4–6 and 47 now
distinguish proven product defects, unexplained behavioral assertion failures and
diagnostic tooling/capture failures. The deterministic stale captured-getter defect
has a live-owner binding correction and historical regression evidence; later
switch/editor misses remain unexplained. The activation/capture failures establish
no product, harness or platform cause.

The lifetime ceiling is two discriminating jobs per unresolved issue, 30 minutes
each including setup and capture, with tests stopped by minute 25. Tooling failures
consume allocations even before UI starts; shared jobs debit both issues. No resets
for repairs, new hypotheses, branches, sessions or successful samples. Existing
allocations already exceed this new ceiling: both switch and editor investigations
are **EXHAUSTED; zero jobs remain**. Historical authorizations/results are retained,
not retrospectively claimed compliant. See [accounting](GATE6_DIAGNOSTICS.md).

One-tap assertions, ten-flow switch coverage, exact UI/state/status/persistence
checks, critical invariants and recursive gate invalidation remain mandatory.
Exhaustive ancestry/video is optional diagnostic evidence; archived incomplete
captures stay incomplete, and integrity/loss checks and failed evidence remain.

A separately approved narrow historical-risk exception is defined, **NOT GRANTED
/ NOT INVOKED**. Outstanding user product decision: whether to accept the named
historical switch/editor residual risk for an exact candidate HEAD and specified
development scope, with explicit risk ownership. Approval must be separate from
this documentation task and precede any invocation/validation. It requires verified
binding correction and complete ordered uninstrumented Gate 6–12 validation at that
HEAD in one declared attempt, no retry-to-green, preserved failures and recurrence
reopening/invalidation. It cannot waive proven defects or critical invariants.
Any permitted development advancement is distinct from product/device acceptance.

Starting local and remote codex/stage-12-routing HEAD independently verified:
72204ff4d4161bae7eb0eec4c5329207f9d8db4c, clean worktree. Its exact
[CI 39200424193](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39200424193)
completed SKIPPED, all three jobs skipped, not PASS. Remote main remains
bd069f29c6d045d5bc27fc56212edcbde2090855; no promotion. Final documentation SHA/run
will be reported at closeout. Publication uses existing record-only/diagnostic
markers to avoid allocating runners; skipped CI is not validation evidence.

Source: five Markdown files reviewed; product/Core/native/UI sources, tests,
diagnostic tooling and workflows unchanged. Automated product tests, Xcode,
Simulator and physical device: NOT RUN in this task. No diagnostic/replay,
exception invocation, gate-status change, main promotion or Stage 13. STOP after
documentation publication. Earlier future-execution proposals below are closed;
only the current policy and separate future authorization can govern new work.

## Latest authorized diagnostic — closed, STOP

October 18 (America/Chicago): authorized experiment source
`7bfeca92401a577f770a97bc074bf40124f1f66f` /
[run 39199089437](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39199089437),
attempt 1: **INCOMPLETE_CAPTURE / Actions FAILURE**. The one original audio/editor
declaration executed once and passed (230.991s). No retry or further experiment.

Accounting: 1 allocated macOS job, 1 explicit boot requested/completed, 1 UI
invocation, 1 actual execution/completed passed case; separate preboot compile
invocation executed no test. One post-save target row tap plus the original
post-relaunch restored-row tap, each with touch/action/draft/sheet/editor records;
0 captured failed target interactions. Job duration 11 minutes under 30-minute cap.
Repair publication and ordinary workflow jobs all skipped with no runners.

Source / Windows: 31 focused checks PASS; original product/Core/native/UI sources
and one-tap assertions preserved. Selected Xcode 26.6: option checks, 31 tooling
checks, actual Swift writer/decoder roundtrips and generated app/UI-runner compilation
PASS before boot. Simulator iPhone 17 / iOS 26.5: original declaration PASS once.
Physical device NOT RUN. This is no gate or broad CI pass.

Two unique raw PIDs contain 2,586 + 455 committed records, valid byte structure/
checksums/sequences and zero overflow/truncation. All 622 counted gesture lists
validate, zero gesture omission markers. **Capture incomplete:** first PID has
2 ancestor-depth omission markers; exported attachment manifest empty and no usable
exported video. Fallback raw copies are identical duplicates. Complete original ZIP,
both xcresults, raw buffers and full Actions log are
[durably archived](evidence/gate6-repaired-single-editor-39199089437/README.md),
with independent integrity and correlation review. ZIP digest matches GitHub.

Home/activation and audio-stop return boundaries are observed in this successful
sample, followed by successful saved-row chains. This establishes no historical
cause or remedy. Both historical input/editor failures and prior activation failure
remain unresolved. Gate 6 FAILED / HELD; Gates 7–12 INVALIDATED / HELD; last
unheld gate 5. STOP after evidence-only closeout: no repair/rerun, production remedy,
main promotion, gate replay, redesign or Stage 13. No further execution queued.

## Earlier offline tooling repair

October 18 (America/Chicago): started clean on `codex/stage-12-routing` at
`31ed9af36031dd4cfa28b03b5fffea45c65f989e`. No CI trigger, commit/push, Simulator
boot or product change. Latest archive only: activation cause remains unknown;
native video has a 142.777-second decoded-frame PTS gap spanning Home/activation,
with an invalid timestamp warning. Neither video nor TOOLING_FAILURE establishes
app, harness, instrumentation or platform causation.

CI-only generated tooling now records entire gesture snapshots under the unchanged
fixed recorder capacity, with declared counts/indexes checked by the decoder.
Overflow/truncation fail-stop and omission-marker rejection remain intact. New
passive lifecycle, editor/audio stop boundaries and test-side Home/activation
timestamps cover the previously silent boundary. Original flow and assertions
remain intact. Archive recount confirms **24**, not 26, gesture omission markers.

Windows automated: **31 focused tooling tests PASS**; latest original capture
still rejected as incomplete. Product/Core/native/UI sources unchanged. Updated
Swift writer self-test and UIKit instrumentation compile/runtime **UNVALIDATED**;
Xcode, Simulator, physical device NOT RUN. No CI pass for this worktree is claimed.
[Review, tested limits and exact one-execution proposal](GATE6_OFFLINE_REPAIR_2026-10-18.md).
Proposal is prepared only; no experiment is authorized or queued. Gates unchanged.

## Latest authorized single-editor diagnostic — STOP

October 18 (America/Chicago): source `6966ab56572e7268799d2fc02a04a179e5ed9bb9`,
[run 39185410894](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39185410894),
attempt 1: **TOOLING_FAILURE / incomplete capture**. Exactly one original audio/editor
declaration executed once. XCTest timed out at `app.activate()` after Home, before
Save or the target saved-row reopening. No captured failed target interaction and
no product cause established. No retry, repair-and-rerun or additional experiment.

Accounting: 1 macOS job allocated; 1 explicit Simulator boot requested/completed;
1 xcodebuild UI invocation; 1 actual test execution/completed failed case; 1 XCTest
activation failure; 0 target saved-row taps and 0 fully correlated failed target
interactions. Ordinary run 39185410899 has all three jobs skipped, no allocated runners.

Source/Windows: original product/native/UI sources unchanged; existing corrections
preserved; 19 focused tooling tests and ephemeral instrumentation application PASS.
Xcode: selected 26.6 option-name check, 19 tooling tests, Swift recorder compilation
and writer/decoder integrity self-checks PASS before boot; Debug instrumented app/test
runner compiled. Simulator: iPhone 17 / iOS 26.5, declaration FAILED on activation.
One raw PID has 1,374 committed records, zero overflow/string truncation, but 24
bounded gesture omission markers: decoder correctly rejects complete capture.
Earlier 14 touch pairs correlate with XCTest events; initial sheet presentation
recorded. No target row/action/binding/owner chain exists because it was not reached.
Physical device NOT RUN. This is no gate or broad CI pass.

Full original ZIP (including xcresult/video/raw), complete decoded Actions log,
integrity and reviewed accounting are [durably archived](evidence/gate6-single-editor-39185410894/README.md).
Both historical failures remain unresolved. STOP: no further diagnostic, production
remedy, main promotion, downstream replay, redesign or Stage 13 is queued.

## Earlier evidence-only review

October 18 evidence-only review: exact starting HEAD c4b74506ef51aaa53de7e34c41a9329bd9d26571
has latest CI 39080917448 SKIPPED, not PASS. Original input/editor logs were reexamined;
neither unresolved failure has a proven current application root cause. Local tooling
removes unsupported dry-run assumptions and product-blame accounting, retains observed
starts across export failure, and separates raw integrity from capture completeness.
19 focused Windows tooling tests PASS; Xcode/Simulator/device NOT RUN. No CI triggered,
commit, push or production change. See [review](GATE6_REVIEW_2026-10-18.md) for proven
facts, missing evidence and the smallest proposed experiment; none is queued.

## Verified starting point and publication

The requested main baseline 10be76a4b071c7c32b7f8e1938a0883f78d9e66e / run
[38923363999](https://github.com/teejayishere/PuzzleAlarm/actions/runs/38923363999)
was independently verified complete SUCCESS, all jobs and every step. The preserved
visual-demo descendant 3a872db6b0334a1a921f8415fa8c55d2f39b4e10 / run
[38972785748](https://github.com/teejayishere/PuzzleAlarm/actions/runs/38972785748)
also passed completely. Earlier pending-main documentation is superseded.

Main currently contains Stage 12 at bd069f29c6d045d5bc27fc56212edcbde2090855,
whose exact run [39058576894](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39058576894)
FAILED Gate 6: one of ten ordinary list-switch inputs stayed 0/Off. Independent
editor and retained-owner binding checks passed; downstream validation skipped.
Do not describe current main or Gate 12 as accepted. Further investigation is on
codex/stage-12-routing; do not promote it until the cause is corrected and all
required gates replay in order at the exact publication HEAD.

## Stage 12 source implemented

The real LiveActivityIntent hands off to AppEnvironment.live, shared with SwiftUI.
One startup task waits for preparation/reconciliation. The existing store owner
coalesces foreground events during commands, then publishes routing after accepting
authoritative state. Foundation-only selection requires active, due, unfinished
sessions, ordered by scheduled date then UUID. Intent IDs are untrusted hints:
stale/unknown/completed hints cannot activate future sessions or override a due
obligation; malformed IDs are ignored.

Cold presentation waits for startup. The destination follows the saved current
challenge and order. Foreground reasserts the obligation without stacking duplicate
destinations or resetting progress. A presented solved sequence shows completion
or pending cleanup; completed cold launch uses normal UI. Persistence schema,
immutable snapshots, lifecycle ownership and challenge engines remain intact.

The candidate also retains synchronous native input submission and a public UIKit
UISwitch adapter, with contract tests for pending state, owner reconciliation,
current binding, target-action, disabled callbacks and teardown. Neither change
has explained or resolved the intermittent single-tap failure. These are unaccepted
candidate changes, not a verified Gate 6 fix. Original product UI assertions and
one ordinary tap remain. No retry taps, relaxed assertions, skipped valid tests,
button replacement or UX redesign were introduced.

## Evidence and unresolved prerequisite

| Evidence | Exact observation |
| --- | --- |
| Historical complete Stage 12 source | cc76307e7890ab29ee73471291485a7c3e59f8f0 / [39053886103](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39053886103): all three jobs/every step SUCCESS; acceptance subsequently held by final-main failure |
| Setter-boundary candidate | d973dbf5dc31460cfd583d35d29147408b3d828d / [39060200894](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39060200894): focused native contracts/editor pass, first list input fails, no actual binding setter; broad skipped |
| Native-control candidate | 0d9de07ab6aad617fba7a3ebe894c67cea590ffa / [39061680552](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39061680552): four focused native contracts/editor pass; first list input fails, no valueChanged/binding/owner entry; broad skipped |
| Bounded diagnostic | a763a420d0c1de0f34db261a0074c953b9395779 / [39063276440](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39063276440): twenty instrumented list flows and independent editor pass; unfinished broad job superseded by cleanup replay; no complete-run claim |
| Cleanup candidate | 480df32f58b82f6320d90739fcb74a8b6e72acd5 / [39064851750](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39064851750): focused switch/editor and initial management pass, full native regression FAILS reopening saved editor; list remains visible, editor.preview absent |

The diagnostic positively attached a passive public window recognizer and recorded
actual app/scene activation, touch coordinates, public control ancestor, target
identity/count and control state. All observed inputs succeeded; no failing trace
was collected. Successful samples show touch began/ended on an attached enabled
UISwitch in active app/scene, followed by valueChanged, binding and owner completion.
This is not evidence of the earlier miss's cause, nor proof of an OS defect.
Temporary probe/subclass are removed and the original ten-flow check restored.
An uninstrumented pass after removal still cannot alone establish root-cause correction.
The editor-reopening failure is independently unresolved. The failed input has no
row-action/draft/sheet trace; it does not establish an audio fault or the switch's
cause. See GATE6_DIAGNOSTICS for the bounded CI-only follow-up and stop rule.

Bounded follow-up d9a585bd3d17a93a6512dff031a21345296a8f4a /
[39074041807](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39074041807)
completed diagnostic SUCCESS: three switch and three editor/audio flows PASS,
no failing sample. Nine switch event/binding/owner chains and successful row/draft/
sheet chains are recorded. Public tracking overrides produced zero callbacks even
on success and are ineffective evidence of recognition. Artifact 12116418876 expires
October 24. No production source changed; the probes were generated only in the
runner's ephemeral checkout. This does not clear either failure or accept any gate.
STOP: remaining cause cannot be distinguished by the bounded available samples.
The precise missing failure records and minimum external capture are documented
in GATE6_DIAGNOSTICS.md. No more unchanged sampling, main promotion or downstream
replay is queued; no Mac/device setup is requested.

Source / automated: Gate 12 mappings and adversarial cases are in TEST_MATRIX;
the historical source passed 148 Core, 66 native and 20 UI declarations. The final
real perform() test additionally requires an actual routing revision on the same
live owner, rather than merely observing startup readiness. Candidate tests also
cover the native switch contracts. Current acceptance remains held.

Xcode / Simulator (historical complete source): Xcode 26.6, Swift 6.3.3, iPhone 17 /
iOS 26.5. Debug/Release, public SDK inspection and actual App Intent compilation,
resources/plists, Release fixture exclusion and full ordered regression passed.
Core coverage 2266/2279; routing selector 23/23. Existing uncovered boundaries are
audited in TEST_MATRIX; no arbitrary 100% target or physical inference.

Physical device: DEVICE REQUIRED / NOT RUN. User confirms no installed iPhone build.
Actual Solve delivery, lock/first unlock, Stop, backup firing/cancellation, native
hardware input, camera/audio and free provisioning remain unverified. Windows has
no local Xcode or interactive iOS Simulator. An interactive Mac input comparison is
not yet shown necessary to discriminate the remaining delivery boundary. User
confirms no Mac is available; no iPhone build is installed. This is settled.
See GATE6_DIAGNOSTICS.md for the separate latest editor failure, one bounded CI-only
diagnostic and its stop rule. CI/mocks do not establish physical observations.

## Previous buffered experiment — STOP

Buffered tooling source `4b0e1c126bec45723e30481cd6eab59a40fe2fa9` /
[39079559751](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39079559751),
attempt 1, FAILED on tooling invocation before either UI declaration executed.
Actual Swift recorder/decoder validation passed before Simulator boot. The agent
supplied unsupported `-test-iterations 1`; xcodebuild exited 64 and requires more
than one iteration when that option is present. No observed product input, no
editor attempt, no rerun. One Simulator job consumed; stop rule applied.

The complete original artifact and Actions log, generated ephemeral patch, toolchain/
runtime, empty invocation xcresult, self-test raw/decoded records and corrected
outcome manifest are archived in
[buffered evidence](evidence/gate6-buffered-39079559751/README.md).
Product capture is absent/incomplete; no negative conclusion is permitted. The
original runner manifest counts an invocation as one execution and calls it a
relevant failure; the reviewed manifest records zero actual UI test executions
and classifies tooling failure. Gates 6–12 remain HELD. No further experiment queued.

## Latest corrected bounded experiment — STOP

User authorized one corrected experiment. Source
`6ba4de1dbadff8c1233fed0488a99d1fbe57c335` /
[39080779760](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39080779760),
attempt 1, FAILED toolchain preflight before Simulator boot or UI execution.
Unsupported `-test-iterations 1` was removed, with no increased iterations.
The added preflight assumed `-dry-run`; selected Xcode 26.6 help does not advertise
it, so the check fail-stopped. No repair-and-repeat. One macOS job allocated,
zero Simulator boots, zero UI invocations, zero actual test executions.
The corrected manifest classifies TOOLING_FAILURE and incomplete/absent capture;
zero captured product failures and zero successful samples. Final invocation
remains unvalidated; no tooling or product pass is claimed.

Seven Windows accounting tests and six existing decoder tests PASS. Selected-Mac
writer/decoder/accounting checks were not reached after preflight failure.
Full original artifact, help/toolchain, accurate manifest and complete job log are
[archived](evidence/gate6-buffered-39080779760/README.md). No xcresults, decoded
product traces or integrity counters were generated; missing counters do not mean
zero loss. Gates 6–12 stay HELD; both historical failures remain unresolved.
STOP: no further experiment, production remedy, main promotion, downstream replay,
Stage 13 or redesign is queued. A green batch alone cannot clear historical failures.

## Future scope after this stopped experiment

The default route remains correction of the earliest demonstrated cause, recursive
invalidation and ordered Gate 6–12 replay. The only historical-risk alternative is
the separately approved exception in MASTER_PLAN §6; none is granted or invoked.
The exhausted budget authorizes no new execution. Product publication requires
complete exact-final-HEAD CI and its actual outcome; this documentation-only branch
publication reports skipped CI separately and does not promote or accept a product.
A blocked gate is not a pass. Historical records are retained in DEVELOPMENT_LOG
and TEST_MATRIX, not mixed into this current-state summary.

MASTER_PLAN records the requested roadmap: Stages 12–13 finish functional routing /
orchestration; after Gate 13, schedule a dedicated UX pass for simpler alarm creation
and list hierarchy, challenge navigation, large focused Math/Memory/QR layouts and
clear countdown/progress/feedback. Cosmetic polish is deferred. No redesign or
Stage 13 implementation belongs in this task.
