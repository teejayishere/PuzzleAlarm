# Test matrix

## Stage 13 attempt — STOP / Gate 6 FAILED

Exact tested candidate `2b2c81d2277f05eb5d095beb0285d47e58a73cb4`,
[run 40445144617](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40445144617),
push, attempt 1. Required editor step FAILED, then explicit stop/cancellation;
actual workflow and all three job conclusions CANCELLED. No retry or diagnostic.

| Evidence class | Exact observed result |
| --- | --- |
| Source / Windows | Self/adversarial review and static source/workflow-order checks; original Core/native/UI assertions and switches preserved |
| Xcode | Xcode 26.6 / iOS 26.5 SDK; Debug app/test targets compiled, including OrchestrationIntegrationTests; broad Release/SDK/resource checks NOT RUN |
| Focused native contracts | Four existing retained-binding, command completion, synchronous pending/reconciliation and native wiring/teardown tests PASS |
| Independent editor / Simulator | Original declaration FAILED once (188.222s), line 181: ordinary post-relaunch On→Off input left editor.enabled at 1; row reopening had succeeded |
| Ten-flow list requirement | Four executions completed PASS, fifth started/interrupted; all ten NOT completed; no full requirement PASS |
| Ordered broad Gate 6–12 / Core / Gate 13 / full regression | Dependent validate job cancelled with zero executed steps; new A–J declarations compiled, NOT EXECUTED |
| Physical device | DEVICE REQUIRED / NOT RUN; no device acceptance |

Gate 6 FAILED / HELD; dependent Gates 7–13 INVALIDATED / HELD; last unheld gate 5.
Exception reliance REVOKED for this candidate. The current input failure cannot be
waived by historical-risk approval. Causes remain unknown; no assertion proves
product, harness or OS causation. Both historical diagnostic budgets remain
EXHAUSTED with zero jobs available. Source mappings below are not PASS evidence.

[Original logs, artifact hashes, preservation limits and accounting](evidence/stage13/README.md).
No required tests were omitted to pass; downstream execution stopped on a failed
prerequisite. Documentation publication is separate and its skipped CI is not PASS.

## Stage 13 — candidate mapping, validation PENDING

All methods below are in `OrchestrationIntegrationTests`, composed through real
AlarmStore, real challenge engines and DiskRepository with scheduler-only effects.
No previously valid tests/assertions were modified. These are source mappings,
not automated PASS evidence. Exact SHA/run/outcome follows candidate execution.

| Gate 13 | Test method | Required observation |
| --- | --- | --- |
| A | `testAAllFiveScheduleWithOneImmutableOccurrence` | Five exact plans/IDs/session links, disk equality, refresh idempotence |
| B | `testBPartialFailureRollsBackIncludingUncertainOSSuccess` | Third scheduling call fails after effect; rollback all present IDs, no completion/automatic reschedule, attention status |
| C | `testCStoppedPrimaryDoesNotCompleteOrCancelBackups` | Primary absent at due launch; active obligation, four backups, missing-ID issue, no replacement/cancellation |
| D | `testDFirstChallengeLeavesBackupsAndRejectsStaleCallback` | First success only, all backups, no lifecycle refresh, stale callback rejected, disk owner restores second kind |
| E | `testEAllFinalEngineKindsCleanAndCreateExactlyOneSuccessor` | Math/Memory/QR each finish a full three-engine sequence; all cleanup IDs, completion timestamp, immutable snapshot, exactly one future armed chain |
| F | `testFCancellationFailureContinuesAndDefersSuccessorUntilCleanup` | Early cancellation fails, later calls continue, no false success/next chain, explicit product retry only unresolved ID |
| G | `testGCompletionAcknowledgmentLossRecoversFromDiskWithoutRepeatedCancel` | Lost post-cancel acknowledgment leaves durable inFlight; new owner uses OS absence and stable IDs, one successor, repeated refresh idempotent |
| H | `testHSchedulingAcknowledgmentLossReusesDurableIdentity` | Lost first schedule acknowledgment; fresh disk owner adopts OS success, schedules remaining four once |
| I | `testIEditingActiveAlarmPreservesObligationAndReplacesOnlyFutureChain` | Active old snapshot protected, edited time/sound future chain, old completion cannot duplicate successor |
| J | `testJDisablePreservesActiveChallengeButPreventsNextOccurrence` | Disable retains current obligation, solving cleans it, next-day disk launch remains Off without successor |

Existing lower-level suites remain required: lifecycle rollback/recovery/recurrence,
all challenge orders and engine-specific persistence/concurrency failures, calendar,
one-time and ownership regressions; native contracts, ten ordinary switch flows,
independent editor and management-first UI replay remain unchanged. The CI focused
Gate 13 step follows Gate 12 and precedes full native/UI regression. Candidate
validation is one declared attempt, under the owner's Stage 13 exception only.

[Authorization, source review, meaningful uncovered behavior and evidence](evidence/stage13/README.md).
Real Stop/backup/AlarmKit/camera/audio/device behavior remains DEVICE REQUIRED.
G/H inject acknowledgment loss and reopen disk owners; they do not establish
physical process-kill or power-loss behavior. No 100% coverage target or inference.

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

## October 19, 2026 — documentation policy only

Gate 6 FAILED / HELD; Gates 7–12 INVALIDATED / HELD; last unheld gate 5.
Stage 13 NOT STARTED. No acceptance status changes. MASTER_PLAN §§4–6, 47 and
[GATE6_DIAGNOSTICS](GATE6_DIAGNOSTICS.md) define the current policy; historical
proposals below do not authorize execution.

| Policy/evidence boundary | Current requirement |
| --- | --- |
| Classification | Proven stale captured-getter defect and its live-owner binding correction remain distinct from unexplained switch/editor assertion failures and diagnostic tooling/capture failures. No historical cause inferred from later success. |
| Investigation | Two discriminating jobs per unresolved issue, 30 minutes each including setup/capture; stop tests by minute 25. Tooling failures and shared allocations count. Both issues EXHAUSTED; zero jobs remain, no resets or new diagnostic/replay. Historical allocations already exceed this newly adopted ceiling. |
| Mandatory behavior | One tap per intended input; all ten ordinary switch flows; native roles, exact 0/1, enabled/hittable, UI/owner/status/error/pending outcomes, editor reopening, save/relaunch persistence. All existing tests and critical completion/order/persistence/lifecycle invariants retained. |
| Optional diagnosis | Exhaustive ancestry/recognizer capture and native video are optional; preserve original incomplete-capture labels and integrity/loss checks. They do not replace required assertions or excuse failed validation. |
| Historical-risk exception | NOT GRANTED / NOT INVOKED. Separate user approval must name issues, exact candidate HEAD, scope and residual-risk owner. Verify binding correction; complete ordered uninstrumented Gate 6–12 at that HEAD, one declared attempt, no retry-to-green, no skipped valid tests. Preserve failed evidence; stop on failed/blocked validation; recurrence reopens gates and invalidates dependents without resetting budget. |
| Advancement versus acceptance | Any future exception permits only its expressly approved development scope after validation. It cannot waive proven defects/invariants or establish product/device acceptance. Device requirements remain NOT RUN. |

Source review: five Markdown files only; production, Core, native/UI tests, scripts
and workflows unchanged. Automated product tests, Xcode, Simulator and device:
NOT RUN for this documentation task. Documentation diff/consistency reviewed.
Starting local/remote branch HEAD: 72204ff4d4161bae7eb0eec4c5329207f9d8db4c;
exact [CI 39200424193](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39200424193)
completed SKIPPED, all three jobs skipped, not PASS. The final documentation
publication SHA and exact CI outcome are reported at closeout, without another
commit solely to embed its own hash. No diagnostics/replay or gate acceptance.

## Current acceptance — Gates 6–12 held

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

Earlier offline work: [October 18 offline diagnostic repair](GATE6_OFFLINE_REPAIR_2026-10-18.md),
starting HEAD 31ed9af36031dd4cfa28b03b5fffea45c65f989e, clean branch
codex/stage-12-routing. **31 Windows tooling tests PASS**, actual generator applied
to disposable copies; entire original UI flow/assertions preserved. Counted full
gesture enumeration retains global buffer bound and strict loss rejection. Archived
capture still incomplete (24 omission markers). Video PTS gap spans Home/activation;
cause unknown. New lifecycle/audio instrumentation and Swift self-test are NOT
Xcode-compiled/runtime-validated. CI/Simulator/device NOT RUN. No gate acceptance.

Latest single-editor diagnostic: `6966ab56572e7268799d2fc02a04a179e5ed9bb9` /
[39185410894](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39185410894)
attempt 1 **TOOLING_FAILURE / incomplete capture**. Selected-Mac options, 19 tooling
tests, Swift recorder compile/roundtrip/integrity self-checks PASS before boot.
1 allocated job / 1 boot / 1 UI invocation / 1 actual declaration execution, failed
XCTest activation before Save/reopening; 0 captured failing target interactions.
1,374 records, zero overflow/string truncation, 24 gesture omission markers; decoder
rejected completeness. Ordinary CI skipped. Device NOT RUN; no gate acceptance.
[Full original archive and accounting](evidence/gate6-single-editor-39185410894/README.md).

October 18 local review: exact starting HEAD c4b74506ef51aaa53de7e34c41a9329bd9d26571 /
39080917448 SKIPPED. No new CI. Local tooling corrections: 19 focused Python tests
PASS; no Xcode/Simulator/device execution. Original one-tap/native/UI protections
unchanged; both unresolved causes remain unknown. [Review](GATE6_REVIEW_2026-10-18.md).

Latest bounded diagnostic: 6ba4de1dbadff8c1233fed0488a99d1fbe57c335 /
[39080779760](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39080779760)
attempt 1 FAILS selected-toolchain help preflight (`-dry-run` not advertised).
One macOS job; no Simulator boot, UI invocation or actual UI execution. Correct
manifest: TOOLING_FAILURE, capture incomplete/absent, no product failure or success
sample. Seven local accounting and six decoder tests pass; Mac writer validation
not reached. No rerun. [Full evidence](evidence/gate6-buffered-39080779760/README.md).

The requested baseline main 10be76a / run 38923363999 and preserved demo 3a872db /
38972785748 were verified complete SUCCESS. Stage 12 source cc76307 / 39053886103
also passed completely (234 distinct tests), but main bd069f2 / 39058576894 FAILED
an ordinary one-tap list input. That reopens Gate 6 and invalidates dependent 7–12.
The source-level Gate 12 requirement mapping below remains useful historical evidence;
it is not current acceptance. Last unheld prerequisite: Gate 5. Stage 13 NOT STARTED.

| Candidate / run | Focused native / editor | Ordinary list flow | Downstream |
| --- | --- | --- | --- |
| bd069f2 / 39058576894 | 2 / pass | 9 of 10 pass; fifth first-enable stays Off | skipped |
| d973dbf / 39060200894 | 3 / pass | 9 of 10 pass; first enable has no binding setter | skipped |
| 0d9de07 / 39061680552 | 4 / pass | 9 of 10 pass; first enable has no native valueChanged | skipped |
| a763a42 / 39063276440 diagnostic | 4 / pass | 20 instrumented flows pass; no failing delivery captured | superseded by probe-removal replay; no complete-run claim |
| 480df32 / 39064851750 | focused native/editor pass | ten flows pass; historical misses remain unresolved | full regression FAIL: saved-row input does not reopen editor; editor.preview absent on list |
| d9a585b / 39074041807 CI-only diagnostic | no new native-unit run; three audio/editor flows pass | three flows pass, nine event/setter/owner chains; no failed trace | STOP, 6–12 held; no ordered acceptance replay |

The last diagnostic verified positive attachment, active actual window scene,
registered native target and successful touch-to-event-to-owner delivery. It did
not find the earlier miss's cause. Toggle artifact 12112741722 and editor
12112202972 expire October 24, 2026. Its temporary DEBUG probe/subclass is removed;
normal ten repetitions and all original one-tap/exact-outcome assertions remain.
No unchanged reruns are used to establish acceptance. The cleanup publication must
have its own exact-HEAD CI result; even a pass cannot alone clear the known failure.

Current candidate adds two meaningful native contract tests beyond the historical
234 declarations; simulated sendActions covers factory wiring/rebinding/disable/
teardown, not physical gestures. Core selector, app-state/error/race/cancellation
cases and direct perform() event proof remain. No valid assertion was weakened.
Xcode/Simulator evidence is revision-specific; physical device is DEVICE REQUIRED /
NOT RUN. User has no installed build or Mac; that constraint is settled. Interactive
comparison is optional future evidence, not a demonstrated prerequisite for further
CI diagnosis. See GATE6_DIAGNOSTICS for the bounded follow-up and precise stop rule.
The follow-up completed but captured only successful inputs. Public tracking overrides
did not fire even on success; do not count them as recognition evidence. Artifact
12116418876 preserves the actual records. No additional batch is authorized by a
green sample alone; capture of an actual failed boundary remains missing.

## Historical evidence (all pass/pending labels below apply only to their recorded revision)
## Native adapter is insufficient — bounded passive-delivery diagnosis

0d9de07ab6aad617fba7a3ebe894c67cea590ffa / run 39061680552 FAILED first of ten
ordinary list inputs; four focused native event/owner contracts and independent
editor PASS, remaining nine list repetitions PASS. PID 15554 journals launch only,
no UIKit valueChanged, binding setter or owner entry. Hierarchy shows the real public
UISwitch visible/enabled, value 0 at (309,457,61,28). Four focused native tests prove
factory target wiring and sendActions behavior, not actual UI gesture delivery.
This disproves the UIKit adapter as sufficient. Do not claim either implementation
remedy resolved the missing native event. Gate 6 and dependent 7–12 remain held.
Artifacts: toggle 12112061434, editor 12111683709 (seven days); broad job skipped.

Stop production-remedy speculation. Add one bounded diagnostic comparison: DEBUG-
fixture-only UISwitch window/layout lifecycle and target-count records, with passive
window UIGestureRecognizer observing touch phase/timestamp/location, actual window
scene activation and public ancestor control identity/enabled/tracking/value. It
never recognizes, prevents, cancels or delays gestures and uses no private API.
Positive attachment is required before event absence means anything. Trace the
actual control window rather than the former unavailable root-window scene lookup.
Run twenty original single-input flows to collect a failing delivery trace, preserving
all exact outcomes and the existing forty-minute free-runner cap. This is diagnostic
sampling, not retry-to-green or acceptance; a passing instrumented batch alone cannot
clear the known failure. Release must exclude probe types; remove probes after diagnosis.
No new production state/gesture remedy is selected without discriminating evidence.
Device input remains unverified. Stage 13 NOT STARTED.

## Gate 6 control adapter correction — PENDING, dependents held

d973dbf / 39060200894 fails first of ten list inputs; three native contracts and
independent editor pass. Failed PID 8495 records no actual binding setter. The
onChange-only explanation is insufficient. Artifact toggle 12111655975 / editor
12111805296. Gate 6 and dependent 7–12 acceptance remain invalidated.

Public UIKit UISwitch target-action now forwards to the existing synchronous input
binding and owner. Focused real-control test checks target wiring/rebinding, silent
programmatic reconciliation, disabled events and teardown. All ordinary one-tap
Simulator UI/value/status/persistence assertions remain unchanged and required.
No private API, button substitution, skipped tests or claim of hardware/OS causality.
Source IMPLEMENTED; Xcode/native/Simulator PENDING changed exact-source CI.
Device NOT RUN. No redesign or Stage 13 work.

## Gate 6 FAILED on final main — Gates 7–12 INVALIDATED

bd069f29c6d045d5bc27fc56212edcbde2090855 / run 39058576894: cold list 9/10;
iteration 5 first enable fails exact 0-to-1 transition, remains Off. PID 22681 has
launch but no onChange/binding/owner journal entries. Native retained binding and
command completion plus independent cold editor PASS; broad validation SKIPPED.
Artifacts toggle 12110817237 and editor 12110562808 retain evidence seven days.
No current Gate 12 acceptance from the source pass below may override this failure.

Correction under validation: synchronous native input binding setter owns immediate
pending/dispatch, then existing owner completion reconciles; onChange only observes
idle external owner state. Same native Toggle and unchanged ten ordinary single-tap
UI flow/role/exact transition/status/persistence assertions. Added native deterministic
setter contract before repetitions; all invalidated gates require ordered complete
replay. No claim that the missing onChange marker proves absent setter delivery or
that historical framework input causes are solved. Source/automated/Xcode/Simulator
acceptance PENDING at corrected source; device NOT RUN. Stage 13 NOT STARTED.

## Historical Stage 12 acceptance (held by final-main failure above)

## Stage 12 — accepted source; final publication requires exact-HEAD replay

Source cc76307e7890ab29ee73471291485a7c3e59f8f0 / run 39053886103, October 17, 2026:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/39053886103 — complete
SUCCESS, attempt 1, all three required jobs and every step. Gates 0–11 regressions
and Gate 12 PASS at that source. 148 Core + 66 native unit + 20 UI = 234 distinct
tests; focused reruns, ten repetitions and parameterized cases are not extra tests.

| Gate 12 requirement | Executed source evidence |
| --- | --- |
| Active due routing | Native cold intent activates armed due session through existing owner; UI Math/Memory/QR open directly after reconciliation |
| No-session normal UI | Pure empty selector; native no-session intent; normal Add Alarm UI through foreground/relaunch |
| Completed exclusion | Pure terminal/completing selector; native failed-cleanup recovery then repeated completed hint causes no new scheduling/cancellation; completed Math/Memory/QR UI relaunch opens list |
| Interrupted cancellation | Trusted success persisted before injected cancel failure; recreated owner retries existing IDs to completed, no challenge reopening |
| Duplicate/stale events | Concurrent valid/stale/foreground events preserve exact saved checkpoint/session; future UUID stays armed; two foreground/back cycles do not stack destinations |
| Ownership/concurrency | Shared cold startup executes preparation once; event while another owner command is suspended is coalesced until final commit; denial does not prompt/claim confirmation |
| Error recovery | Snapshot failure retains known active obligation and uncertainty; retry keeps same session without new effects; startup failure stays unavailable |
| Deterministic multiple sessions | Date then stable UUID, storage permutations and equal dates; no discarded sessions or requested-ID priority |
| Real integration | SDK inspection, Debug/Release compilation, actual perform() invocation plus injected real intent handoff; system launch remains device-required |
| Earlier gates | Retained-binding/command completion, ten ordinary list failure/retry inputs, independent cold editor input/persistence, management first, then Math/Memory/QR, full native suite |

Source IMPLEMENTED. Automated AUTOMATED PASS. Xcode XCODE COMPILE PASS: 26.6 /
Swift 6.3.3. Simulator SIMULATOR PASS: iPhone 17 / iOS 26.5. No compiler/destination
warnings; broad job has three known SDK metadata advisories and each comparison one.
Seven-day artifacts: native/Routing 12110840666, QR 12110153546, editor 12109067201,
toggle 12108333372; thirty-day eleven-screen gallery 12110352804.
Physical device DEVICE REQUIRED / NOT RUN for actual Solve, lock/unlock/first unlock,
Stop, AlarmKit playback/cancellation/independent backups, camera/audio and provisioning.

Core coverage: 2266/2279; WakeUpRouting 23/23. Existing thirteen uncovered Core
counts retain their prior audit classifications below. The current-challenge guard
is defensive for a validated active session; no invalid session was fabricated to
exercise it. A line pass does not prove every comparator/clock/OS interleaving.
Source app subset: Store 323/329, Environment 43/46. Unexecuted real production
setup/catch, default clock/context, nil state, reportError presentation fallback,
picker/date/default sound fallbacks, iOS 26.0 initializer/probe and actual camera
retain source/device classification; do not add percentage-filler assertions.
The final publication extends the existing coverage report to the intent adapter
and strengthens direct perform() to require a routing event on the identical live
owner, even if SwiftUI already completed startup. These final assertions require
complete exact-final-main CI; no descendant pass is inferred here.

407fca5 / run 39053360539 failed new test compilation on a var/let warning-as-error.
No test assertions, warnings policy or prerequisite requirements were relaxed.
The corrected complete source run above clears that blocked replay. No earlier
production defect was identified; any later failure invalidates the earliest affected
gate and dependents until corrected and rerun in order. Baseline main 10be76a /
38923363999 and preserved demo 3a872db / 38972785748 were separately verified complete
SUCCESS, every job/step. Historical statements below apply to their recorded SHA.

## Historical Stage 11 — accepted source and meaningful coverage audit

28869311cc2a4474f412d4eab150205ef0afb799 /
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38879910505 — complete
SUCCESS, attempt 1, all three required jobs and every step, observed 2026-10-16.
Retained-binding contract, ten ordinary list enable/failure/retry repetitions,
independent cold editor initially Off with eleven inputs and On/Off save/relaunch,
ordered management/downstream replay and full native pass clear Gates 6–11
invalidation at this revision. 146 Core / 59 native unit / 18 UI = 223 distinct tests;
repetitions, focused subsets and parameterized cases are not extra tests.
Source IMPLEMENTED; automated AUTOMATED PASS; Xcode XCODE COMPILE PASS; Simulator
SIMULATOR PASS; physical device DEVICE REQUIRED / NOT RUN. Xcode 26.6 / Swift 6.3.3;
no compiler/destination warnings; three broad SDK metadata advisories and one in
each comparison job. Seven-day artifacts: editor 12037896723, toggle 12037882222,
QR 12040981214, native 12040377372.

The captured getter's deterministic four-assertion failure (5fa500a / 38855208213)
justifies reading live authoritative owner state by stable ID. The production native
Toggle remains. Its synchronous local input is pending presentation, then reconciled
to the owner after the existing async command. It never grants healthy/persisted/OS
state. Explicit completion handles coalesced busy changes and rejection; idle input
follows external owner updates. Native command-completion regression covers access
denial, scheduling failure, disable and successful enable. UI denial requires Off,
error, pending released and Off across relaunch, in both focused and full replay.
Concrete-role queries correct a separately observed broad Any-query timeout. One input must still
yield the exact opposite 0/1 state, after the existing owner's bounded busy barrier;
all enabled/hittable/status/failure/retry/persistence outcomes remain enforced.
Earlier missed inputs remain recorded, not discarded or conclusively attributed to
that getter or an OS defect. Complete passes are revision-specific execution evidence,
not proof that an intermittent interaction can never recur or that hardware works.
Temporary UI probes were removed; fixture-only input journal is absent in Release.
Failed main runs f187ade / 38773355992 and f21f469 / 38877456923, plus earlier
83fb473 and 2b11352 source successes, are superseded for current acceptance by this
corrected-source replay. Superseded a6393b5 / 38879858529 was cancelled, not passed.
That historical final-main requirement was resolved by 10be76a / run 38923363999.

| Gate 11 requirement | Executed evidence |
| --- | --- |
| Resources | Deterministic Python byte check; real bundle AVAudioFile decode, frames/rate/channels/headroom for all four original CAF files |
| Selection persistence | All five choices saved/reloaded through DiskRepository; immutable session snapshot survives definition edit; every backup request keeps snapshot choice |
| Fallback/integration | Missing, empty, corrupt, valid zero-frame and overlong assets select default; persisted choice unchanged; real public AlarmKit configuration compiles |
| Preview lifecycle | Replacement, idempotent stop, injected failure, default/missing messages; real AVAudioPlayer start/replace/stop integration; own queued category notification preserved, external/unknown/missing route events stop |
| Editor cleanup | Preview/Stop, selection, pushed navigation, background, Save/Cancel and relaunch UI; source hooks for inactive/dismissal/interruption/media reset |

The native decoded-headroom assertion caught the original CAF flag defect and stayed
unchanged through correction. Coverage is audited for behavior, not manufactured
to meet a percentage. Current Core: 2243/2256 (99.42%), prior classifications below
unchanged. App: Catalog 10/10, Preview 47/47, ConfigurationFactory 52/62, Store 314/319,
Environment 23/27, Draft 84/88, Formatting 86/86, Presentation 72/72, QR scanning 82/82,
QR view 39/40, real camera 0/173. AlarmEnabledBinding 63/65. Total 872/1071 (81.42%); excluding real camera
872/898 (97.10%). The factory's seven iOS 26.0 availability-initializer lines need
that OS; three unused namedSoundConfiguration probe lines are compile-only.
The two uncalled native-input regions are classified, not percentage-filled:
line 7's empty default completion is NON-MEANINGFUL (production command supplies its
completion); line 29's nil-coalescing initial Off closure is DEFENSIVE for a row
constructed synchronously from a present store definition. Removed-ID getter behavior
is separately tested. Do not fabricate a missing parent to inflate rendering coverage.
Pending/coalesced input guards retain source review alongside actual denial/success/
failure UI and owner tests; line execution does not establish all interleavings.
Remaining default closures, generated sharing initialization, error/calendar fallbacks
and camera adapter retain their earlier source/device classifications. Preview/catalog
100% line coverage does not prove every AVAudioSession failure or prepare/play false
branch, audible output, session deactivation success, or alarm playback.
Physical notification delivery, actual hardware routes and lock/Silent/Focus remain
device requirements; injected callbacks and Simulator are separate evidence.
Optional import is probed/deferred; exact system-default foreground preview is not
provided by a documented API. See AUDIO_CAPABILITIES.md and DEVICE_TEST_PLAN.md.

Final publication must have its own exact-SHA full main run; final immutable SHA/run
are recorded in the task report. No Stage 12 work.

## Historical Stage 10 evidence (pending claims superseded above)

## Stage 10 — corrected source PASS; documentation/main replay pending

e5c43ae6d457abff838bcf3fa448b5805b22ffc9 /
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38533688088 — complete SUCCESS,
every required step. Ordered management-first replay and full native replay clear
Gates 6–10 invalidation; earlier required regressions pass. 146 Core / 51 native /
15 UI = 212 distinct tests. Source IMPLEMENTED; automated AUTOMATED PASS; Xcode
XCODE COMPILE PASS; Simulator SIMULATOR PASS; device DEVICE REQUIRED / NOT RUN.
Seven-day artifacts: QR 11882141611; native 11881762952. Actual native Copy remains a
Cell, tapped with dismissal asserted; independent PNG payload decode and opaque quiet
zone remain exact. Completion wait and enabled/hittable checks preserve outcomes.

Meaningful uncovered audit is unchanged: Core 2243/2256 (99.42%), QR reducer 15/15,
QR owner 21/21; prior uncovered invariants retain classifications below. App counts:
Store 308/313, Environment 23/27, Draft 84/88, Formatting 86/86, Presentation 72/72,
QR scanning 82/82, QR view 39/40, real capture 0/173. Total 694/881 (78.77%);
excluding explicitly unexecuted capture 694/708 (98.02%). Generated sharing initializer,
default/error/calendar fallbacks and camera/device boundaries remain source/device
evidence, not reasons to manufacture coverage. No arbitrary percentage gates acceptance.
Xcode 26.6 / Swift 6.3.3; no compiler/destination warnings; three known SDK advisories.
Complete documentation-HEAD CI and exact-final-main CI are still required. Main b52c58c
is not final accepted evidence. Stage 11 NOT STARTED.

### Historical correction evidence (resolved by complete replay above)

1a16f1d / run 38530656775: all five focused QR native and 41 broader application
tests PASS with actual completion waiting. Management edit readiness then fails for
editor.sound. Full retained hierarchy shows the control as Button, on screen, with
no Disabled state (boundary move controls are explicitly Disabled). Initial lookup
was Any while offscreen; accessibility Find retries take 31 seconds. Re-resolve role
after scrolling, observe isEnabled directly before deciding to poll, retain ten
seconds for actually disabled controls, and require enabled/hittable before tap.
All product/save/relaunch assertions stay exact. Earliest cause is Gate 6 helper
measurement; dependent Gates 7–10 held invalid until full ordered replay.
Native artifact 11878925772 retains early native evidence. No production change.

Run 38529408523 at ed39d25 reveals another Stage 10 test measurement assumption:
1,000 yields are not an async completion barrier. The QR permission/stale/duplicate
test observes completing/authorized while cleanup still awaits final persistence.
Require isSubmitting=false under a five-second ContinuousClock deadline, releasing
the main actor with async sleep. Keep completed, idle and five cancellations exact.
All submission/feedback waits share this bounded condition; no production relaxation.
Focused QRStoreTests precede broader app/UI replay; native result retention includes
QRApplication/Application/Management/Shell, so future early failures retain evidence.
The historical acceptance below is invalidated for Gate 10 until corrected full CI.
No earlier product defect demonstrated. Final documentation/main require exact CI.

### Historical Stage 10 source acceptance (superseded by correction above)

Prerequisite main 0b5c261da4eaab2f29317d3e58b23dab7f4ed7bc / run 38354985121
completed full SUCCESS before implementation. Earlier Gate 9 evidence remains valid.
Accepted source abc38481f3c2b1678c6e08db35de608e410bc5d1:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38515725575 — complete SUCCESS.
All required steps passed; partial failed/cancelled runs are not acceptance evidence.

| Capability | Tests / evidence boundary |
| --- | --- |
| Exact matching and restore | QREngineTests: all 11 orders containing QR; wrong/empty/malformed/other token, whitespace/case/escaped/query variants; exact bytes, stale duplicates, foreign/future identities, clock rollback atomicity |
| Ordered owner persistence | QRLifecycleTests: missing session, rejected write, three-conflict limit, CAS competing success revalidation, edited parent token vs protected occurrence snapshot; no external effects before committed sequence success |
| App success and cleanup | QRStoreTests: rejected write/reload, relaunch, duplicate, revoked AlarmKit access, QR→Math, partial cleanup/recovery; no false scheduler confirmation |
| Scanner behavior | QRStoreTests: all permission/status states, duplicate metadata, stopped/replaced callback, interruption/retry, failed commit feedback and stale ordered callback |
| Generated export | QRStoreTests: PNG decode through independent CIDetector matches saved payload; opaque white quiet zone. Printing/optical detection DEVICE REQUIRED |
| Native UI | SIMULATOR PASS: wrong scan, interruption, background, navigation recreation, relaunch, correct completion; denied/unavailable/retry and QR→Math; configuration image, native Copy action and dismissal |
| Compile/regression | PASS: focused QR before full Core; Gates 0–9 regressions, affected Gate 6 management UI before downstream flows, Debug/Release, built camera/Photos/alarm purpose strings, Release fake exclusion and diagnostics |
| Physical camera | DEVICE REQUIRED / NOT RUN: actual prompt/restriction/revocation, AV metadata/notifications/hardware unavailable, preview/orientation/resource lifecycle, optical scan, save/print and accessibility |

Meaningful source audit added stopped-before-permission guard, generation-bound capture
notifications, truthful inactive-session presentation, failed/stale scanner feedback and
edited-parent snapshot tests. No coverage assertion or valid earlier test was weakened.
Core adapter/persistence architecture is unchanged; no earlier defect found so far.
AVFoundation branches cannot be inferred from fake coverage. Stage 11 NOT STARTED.

### Stage 10 acceptance and uncovered-behavior audit

First final-main attempt: b52c58c passed complete documentation branch run
38521348992, then main run 38526380709 failed before two management tests could
reach product assertions (Xcode launch timeout, then PID 0 background assertion).
The other six management tests passed, including the previous readiness failure.
Dependent UI gates were not executed; missing Shell coverage is a consequence.
Launch diagnostic bundle: artifact 11877480716 (seven days). No product assertions
or timeouts are relaxed. Connector rerun is unavailable (403); a documentation-only
revision provides a legitimate new full workflow trigger, followed by exact-main
replay. This failed main attempt is not accepted; final task report must identify a
completed matching main run. Source/automated acceptance below names its own revision.

Source IMPLEMENTED; automated AUTOMATED PASS; Xcode XCODE COMPILE PASS; Simulator
SIMULATOR PASS; physical device DEVICE REQUIRED / NOT RUN. Toolchain Xcode 26.6 /
Swift 6.3.3 on free standard macos-26. No compiler/destination warnings; three known
SDK metadata advisories. Four QR Core declarations execute 14 cases; five application
and three UI declarations add 12 tests since Stage 9. Full 146 + 51 + 15 = 212 distinct
tests PASS; focused reruns and argument cases are not counted again.

Core 2243/2256 (99.42%), QREngine 15/15, QRLifecycle 21/21. Prior 13 uncovered counts
(10 merged LCOV lines plus closure counts) retain their earlier classifications.
The important inline identity, clock, competing CAS, changed parent snapshot and
failed-write behaviors are exercised; validated invariants are not broken for coverage.

Application counts at this exact source: AlarmStore 308/313, AppEnvironment 23/27,
AlarmEditorDraft 84/88, AlarmFormatting 86/86, AlarmStorePresentation 71/72,
QRCodeScanning 82/82, QRCodeView 39/40, AVFoundationQRCodeScanner 0/173.
Total 693/881 (78.66%); excluding the explicitly unexecuted physical capture adapter,
693/708 (97.88%). This subtotal does not turn adapter mocks into production evidence.
Store/environment/draft default, error and closed-enum/calendar fallbacks retain prior
source/device classifications. The existing status fallback count varies (71/72 here,
72/72 in failed 8d01038); status regressions remain green and no percentage decides
acceptance. QRCodeView's uncalled _sharing initialization is a compiler-generated
State initialization count; actual native sheet creation and Copy/dismissal execute.
Image allocation/failure presentation is source-reviewed, not deliberately faulted
to seek 100%. AV permission, input/output/device/QR availability, start/stop, observer
generation, metadata and preview/resource branches are compiled/source-reviewed;
real execution, OS prompts and optical behavior remain DEVICE REQUIRED.

Five risks challenged: wrong/normalized/other-alarm token (exact-byte/order matrix),
late or duplicate metadata (attempt-bound controller), failed write/competing CAS
(owner rejection/revalidation), edited parent token (immutable occurrence snapshot),
and export/capture boundaries (independent PNG decoder plus native Copy; hardware
capture/save/print remains unverified). The most damaging architectural assumption,
one live lifecycle owner with durable success before effects, remains explicit and
is revalidated by CAS/write/cleanup tests. No schema or framework coupling added.
No coverage assertion, real product requirement or readiness assertion was weakened.

Run 38438577131 at c37a67a failed the Button-only Copy lookup. Run 38512236768 at
8d01038 confirms Copy is Cell actionGroupCell and passes focused/full QR, but fails
one existing management enabled predicate amid slow snapshots. Dependent Gates 6–10
were held invalid pending replay. Diagnostic/order commits preserve the original
enabled expectation/10-second limit; management passes both focused and full at the
accepted source before closeout. Runner/accessibility latency is an inference, not a
proven production cause. f431239's superseded run was cancelled, never counted PASS.
Accepted-source artifacts: QR 11873133286, Management/Shell 11873746573 (seven days).
Final documentation HEAD and final main must each pass the complete matching workflow;
the task report provides final immutable SHA/run without a self-reference commit.

Observed 2026-10-01 America/Chicago (CI timestamps 2026-10-02 UTC).

## Gate 0 — PASS

Revision: 92faaf89716a4f4d030e8cff4abe1021a07dd558
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36943963689).
Manifest parsing, core compilation and Foundation/Swift Testing smoke test passed.
Local YAML structure, coherent source layout, free-dependency review and common
secret-pattern scan passed. No claim of an exhaustive secret/security audit.

## Gate 1 — PASS

Revision: cb5797f133993183e5dcf6082598182dc25450a9
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945373495).
26 test functions; parameterized cases are reported separately in the log.
Swift 6.3.3 / Xcode 26.6 on standard macos-26. Warnings are errors.

| Capability | Status | Evidence |
| --- | --- | --- |
| Definition creation/edit/enable/disable, modes, weekdays, sounds | AUTOMATED PASS | ModelTests; replacement preserves identity; no OS effects claimed |
| Unique ordered configuration, add/remove/reconfigure/reorder | AUTOMATED PASS | ModelTests + all 15 allowed session sequence permutations |
| Config validation and Codable round trips | AUTOMATED PASS | ModelTests, DecodingTests; malformed values rejected |
| Next occurrence | AUTOMATED PASS | 13 explicit cases: weekday/weekend, exact time, midnight, month/year/leap boundaries, Chicago DST gap/repeat, Kathmandu offset |
| Weekly schedule invariants | AUTOMATED PASS | Seven weekdays across 370 instants (2,590 checks), strictly future with correct wall time/day |
| Five-alarm plan | AUTOMATED PASS | Exact offsets/unique IDs, crossing midnight, decode corruption |
| Session lifecycle | AUTOMATED PASS | No false armed state; activation time checks; strict success order; finalization invariant |
| Partial scheduling/unknown outcomes | AUTOMATED PASS | All five failure positions; in-flight round trip; concurrent unknown outcome retained |
| Cancellation model | AUTOMATED PASS | Each failure position, continue after failure, retry, restore and duplicate acknowledgments |
| Immutable session snapshot | AUTOMATED PASS | Definition edits/disable preserve occurrence; future-edited snapshot creation rejected |
| Future retirement | AUTOMATED PASS | Cancellation required; cancelled is not completed; active retirement rejected |
| Counter checkpoints | AUTOMATED PASS | Matching types, bounds, monotonicity and restoration |
| Corrupted lifecycle data | AUTOMATED PASS | False armed/completed states, ledger shapes, invalid progress/dates/IDs rejected |
| Core line coverage | AUTOMATED PASS | 439/444 lines = 98.87%; does not imply full branch/behavior coverage |
| SwiftUI shell / generated Xcode project | XCODE COMPILE PASS | See Stage 2 evidence below |
| AlarmKit / App Intent SDK compilation | XCODE COMPILE PASS | Stage 3 evidence below; physical effects unverified |
| Disk persistence / atomicity / disk failures | AUTOMATED / SIMULATOR PASS | Stage 4 evidence below; real disk and injected interruption tests |
| Actual scheduling/rollback/edit/disable/delete effects | NOT STARTED | Stage 5; current evidence covers model transitions only |
| Challenge coordinator and answer validation engines | NOT STARTED | Stages 7–10; success events currently supplied by tests |
| Memory hidden-state restoration and camera QR matching | NOT STARTED | Stages 9–10 |
| Audio resources / previews / real alarm sounds | NOT STARTED | Stage 11 |
| Native shell launch on iPhone Simulator | SIMULATOR PASS | One launch/title test; product flows still NOT STARTED |
| Physical firing/camera/audio/provisioning | DEVICE REQUIRED | No device observations |

Production coverage by source: Challenges 100%; Models 100%; Scheduling 97.10%;
WakeUpSession 98.77%. Coverage reporter excludes tests and generated SwiftPM sources.

## Failed evidence and replay

[First Stage 1 run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945010757)
at eb03c50 failed test compilation; production build passed.
Root cause: missing inner try in #require. Test requirements were unchanged.
[Corrected run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945155823)
at 76420f1 passed 21 tests before the final adversarial expansion.

Local Windows Swift remains absent by choice; CI supplies actual execution evidence.
No paid service/tool was introduced.

## Gate 2 — PASS (observed 2026-10-02)

Revision: 7d619f480c99b8868cbb7bfc7a776132deb104db
[Actual corrected CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37035827761).
Environment: standard macos-26, macOS 26.6.2, Xcode 26.6, Swift 6.3.3.
XcodeGen 2.44.1 installed from its checksum-pinned official release.

| Capability | Status | Evidence |
| --- | --- | --- |
| Clean project generation | AUTOMATED PASS | Project, shared scheme and generated Info.plist reproduced byte-for-byte |
| Core package regression | AUTOMATED PASS | Manifest/build; all 26 tests; 439/444 production lines = 98.87% |
| Native iOS app compilation | XCODE COMPILE PASS | xcodebuild BUILD SUCCEEDED, iOS 26.5 Simulator SDK |
| Core linked as SwiftPM product | XCODE COMPILE PASS | Dependency graph and compiler log reference Package.swift; no duplicated core sources in app |
| Dynamic iPhone destination | AUTOMATED PASS | Discovered iPhone 17 / iOS 26.5; no fixed model/UUID, native architecture selected |
| Native shell launch | SIMULATOR PASS | ShellLaunchTests.testLaunchDisplaysNativeShell; 1 XCTest UI test, 0 failures |
| Xcode diagnostic review | AUTOMATED PASS | No compiler/destination warnings; 2 explicit no-AppIntents SDK metadata advisories |
| Earlier gate invalidation | None | Stage 1 source and tests unchanged; core regressions replayed |
| AlarmKit and all Stage 3+ features | NOT STARTED | Scope explicitly stops after Gate 2 |
| Physical installation/behavior | DEVICE REQUIRED | No device claims |

Initial shell run at 373fa89 also passed generation/build/launch:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/36946854457
Audit found ARM/Intel destination ambiguity and corrected the CI destination.
The corrected run above confirms that warning is gone. The remaining metadata
advisory is an Apple tool message because this stage intentionally has no AppIntents.
No warnings were hidden and no excluded functionality was added to silence it.

Local focused checks: five Simulator-discovery cases and four diagnostic-classifier
cases passed; YAML structure and Python syntax checked. These do not substitute
for the real Xcode and Simulator results above.

## Gate 3 — compile/integration PASS at recorded implementation

Revision: 6e750fdbe510a4dc2174fc222e62f05548b96eae
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095598366).
Installed SDK observed before implementation in
[run 37095284734](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095284734).

| Evidence | Result |
| --- | --- |
| Gate 0–2 regression | PASS: reproducible generation; core manifest/build; 26 tests; 439/444 lines (98.87%); app build; shell launch |
| AlarmKit + AppIntents | XCODE COMPILE PASS in real app; metadata extraction completed |
| Permission configuration | AUTOMATED PASS: actual built .app/Info.plist has nonempty NSAlarmKitUsageDescription |
| Platform adapter tests | AUTOMATED PASS: 7 tests, no daemon or permission calls |
| Metadata identity/role | Five planned IDs, UUID/ordinal mapping, Codable minimal keys, foreign ID rejected |
| Relative schedule | All 128 weekday subsets and boundary wall time; never/weekly mapping |
| Presentation/intent | Alert only; custom Solve action; occurrence ID; foreground mode |
| Fake adapter boundary | Stable scheduling/cancellation ID; snapshot/update forwarding; error propagation |
| Diagnostic review | No compiler/destination warnings; one unchanged SDK advisory in UI-test bundle |
| Physical AlarmKit effects | DEVICE REQUIRED; no firing, permission, lock-screen, Focus/Silent, intent launch or playback claim |

Exact API-by-API matrix and scope limits:
[ALARMKIT_CAPABILITIES](ALARMKIT_CAPABILITIES.md).

The final follow-up strengthens the empty-update assertion and corrects diagnostic
wording. It requires its own exact-HEAD successful run; the run above is evidence
only for its named revision. No earlier gates invalidated. Stage 4+ NOT STARTED.

## Gate 4 — persistence implementation PASS at recorded revision

Revision: 47c96dc9bb9b5c122e4ac0fd6f240eec1b784461
[Actual full CI](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144199020).
27 focused persistence tests; 53 full core tests; seven platform tests;
one iOS disk integration test; one native shell launch test.
62 distinct test functions, excluding focused repeats/parameterized invocations.
Core coverage: 772/779 lines (99.10%).

| Requirement | Observed evidence |
| --- | --- |
| Empty/missing, save/load/update/delete, multiple definitions | AUTOMATED PASS; explicit missing differs from a committed empty document |
| Weekdays/modes/order/sounds/timestamps | AUTOMATED PASS; configuration permutations and schema round trips |
| Session lifecycle/progress/index/parent/snapshot | AUTOMATED PASS; all ten phases, inFlight schedule/cancel and partial failures preserved |
| Ownership ledger | AUTOMATED PASS; all five IDs/ordinals, detached records, duplicate UUID and competing authorities rejected |
| Math/Memory/QR data | AUTOMATED PASS; exact math problem, five Memory phases/deadline, QR token; no engines/camera state |
| Corruption/schema | AUTOMATED PASS; empty/truncated/malformed bytes, invalid enum/configuration, schema 0/2/99 rejected; bytes retained |
| Atomic failure | AUTOMATED PASS; injected failure after staging preserves prior document and reports interruption |
| Initial interrupted write | AUTOMATED PASS; missing committed document plus pending file never becomes a valid empty state |
| Real filesystem errors | AUTOMATED PASS; staging-path write failure and blocked storage directory surfaced |
| Concurrency | AUTOMATED PASS; stale revisions rejected; one winner across simultaneous memory writes and separate disk actors |
| Reconciliation representation | AUTOMATED PASS; recognized/persisted-missing/stale/orphaned ownership inventory; no recovery actions |
| Production iOS persistence | SIMULATOR PASS; real Application Support create/save/reload |
| Gates 0–3 | PASS; original 26 core tests, generated build, AlarmKit/AppIntents, seven platform tests, shell launch retained |
| Diagnostics | PASS; no compiler/destination warnings; known UI-test metadata advisory remains |
| Physical durability/AlarmKit | DEVICE REQUIRED |

Final follow-up adds four adversarial tests: invalid commit retains good bytes;
invalid ownership/timestamp decoding; cancelled ID still present classified stale;
real disk read error distinguished from missing. Concurrent losers must specifically
report conflict. It also removes redundant schema decoding. Final acceptance
requires a full successful CI run for that exact follow-up revision.
No earlier gate invalidated. Stage 5+ remains NOT STARTED.

## Gate 4 — final implementation PASS

Revision: 40501452d1aaf7e7e3fa03ba54d153574d560fde
[Actual final implementation CI](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144990239).

- Total: 66 distinct tests (57 core, eight iOS unit/integration, one UI).
- Persistence: 32 tests (31 core, one iOS Application Support integration).
- Core coverage: 771/777 production lines = 99.23%.
- Four additional adversarial checks above passed; concurrent losers specifically
  report conflicts. Source/test assertions were not weakened.
- Production persistence, AlarmKit and AppIntents compile; all Gates 0–3 regressions
  pass in the same run, with no compiler/destination warnings.
- The known UI-test metadata advisory remains documented and unchanged.
- Earlier gates invalidated: none. Stage 5+ NOT STARTED.

Subsequent documentation-only revisions also run the complete workflow.
Acceptance of the current checkout requires its matching successful GitHub run;
this named run is the immutable evidence for the final implementation.

## Coverage audit — baseline 771/777, six missing line counts

Baseline source: cdd45d57477d8f2cbc492dbc9535ff76a28f8ecf.
Raw evidence (same production sources): a5f7a28385141accf9e3131a788f5c2257f81982,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181404906.
LLVM LCOV merges source lines and lists four zeros; SwiftPM's JSON also counts
two uncalled nil-coalescing autoclosures as separate uncovered line counts.
This accounts for all six, without confusing line coverage with branch coverage.

| Baseline location/function | Behavior | Classification and disposition |
| --- | --- | --- |
| DiskRepository.swift:23, applicationSupportDirectory | Throw when Foundation returns no user Application Support URL | PLATFORM-DEPENDENT. No production injection seam for the system search-path result. Normal macOS and iOS lookup and real read/write failures are tested. Track unavailable storage/file protection under platform/device integration; do not swizzle Foundation for a coverage number. |
| RepositoryState.swift:20, AlarmOwnership.isPrimary | Derive primary versus backup from persisted ordinal | CRITICAL BEHAVIOR. Add restored-ledger regression verifying exactly one primary/four backups, stable IDs/owners, and a detached ordinary primary. |
| Scheduling.swift:16, ScheduleContext.calendar | Reject a timezone that disappears after successful validation | DEFENSIVE/UNREACHABLE BRANCH under a stable timezone database. Immutable context init and decode reject unknown identifiers before calendar construction. No unchecked context or broad mock added; platform database replacement remains an environmental limitation. |
| Scheduling.swift:55, OccurrenceCalculator.next | Throw when no occurrence exists within the search horizon | CRITICAL BEHAVIOR. Not safely dismissible as unreachable: skipped-date regression exposed the seven-day assumption. Recurse to Stage 1 and fix the horizon, then replay dependent gates. |
| WakeUpSession.swift:200, finalizeCompletion | Nil fallback to wake date when deriving last challenge success timestamp | DEFENSIVE/UNREACHABLE BRANCH. Prior full-sequence guard plus nonempty challenge-required configuration guarantees last exists. Existing malformed-completion tests prove rejection; new terminal-reload late-event regression protects idempotency without manufacturing an invalid session. |
| WakeUpSession.swift:262, validate | Same nil fallback while validating a completed session's timestamp | DEFENSIVE/UNREACHABLE BRANCH. Earlier decode validation requires the full nonempty sequence. Corrupt missing/empty challenge completions already fail before this line's autoclosure. No test bypasses the invariant. |

No coverage threshold changed; no production code removed merely to raise coverage.
Zero-count inline regions also appear on covered lines; the retained JSON evidence
makes clear that 99% line coverage is not exhaustive branch coverage.

### Reproduction and correction pending full validation

Regression-only revision: 1356491831105c34768d56632a122d4a83e25a96.
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181948057
Actual failure: weeklyOccurrenceSurvivesSkippedLocalCalendarDate throws
"No occurrence found in calendar horizon"; other 59 core tests pass.
Earliest affected stage: 1; Gates 1–4 invalidated pending complete replay.
Samoa skipped Friday 2011-12-30 (IANA historical timezone data:
https://lists.iana.org/hyperkitty/list/tz%40iana.org/2011/9/?count=10&page=8).
A Friday alarm after the prior Friday must advance to 2012-01-06 local, not fail
or silently select Saturday. Search two weekly cycles to allow an omitted weekday.
Keep the fail-closed fallback for unsupported calendar outcomes. Stage 5 not started.

### Coverage audit — corrected implementation PASS

Revision: b9c87ab56df0e0e7928578d978d1c03304faa5ce
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37182114469
60 core + eight iOS unit/integration + one UI = 69 tests PASS.
Persistence: 32 core + one iOS = 33. Coverage: 774/779 (99.36%).
The primary-role getter is now covered. The two added source comments also appear
in LLVM's line-region denominator; coverage was not the reason for those comments.
Remaining five counts: DiskRepository:23; Scheduling:16 and now :57;
WakeUpSession:200 and :262 autoclosures. Platform/unreachable justifications remain
as above. The horizon fallback is retained after the real recurrence defect was
fixed and meaningfully tested; no injected calendar failure just to make it execute.
Gates 1–4 restored after full replay; Gate 0 also rechecked. Stage 5 NOT STARTED.
No threshold changed. Final documentation-only acceptance requires exact-HEAD CI.

## Stage 5 acceptance matrix

Stage 5 adds deterministic lifecycle tests plus two iOS composition/translation
tests. Parameterized cases count as one Swift Testing test declaration in the
reported totals; focused reruns are not counted twice. Final evidence is recorded
in PROJECT_STATE.md and the final acceptance entry in DEVELOPMENT_LOG.md.

| Requirement | Meaningful evidence |
| --- | --- |
| Five-alarm transaction | LifecycleTests checks ID/date order, durable inFlight at each effect, no premature armed/completed state, and final five acknowledgments. |
| All five failures / rollback | Parameterized failures at positions 1–5 include an OS side effect followed by an error; assert exact cancellation IDs, empty OS state and retained five-entry ownership. Cancellation errors must not stop siblings. |
| Every external-effect crash window | LifecycleRecoveryTests restores partial plans at positions 0–5, all acknowledgments before arming, missing/present inFlight IDs, failed acknowledgment writes, partial cancellation and failure after actual OS removal. |
| Missing / failed / stale snapshots | Snapshot errors propagate; known missing alarms do not solve challenges; unknown owned IDs are reported; stale terminal positives do not repeat cancellation. |
| Recurrence | Ordinary weekly uses one ID without sessions; challenge completion creates one successor only after cleanup. Calendar tests cover midnight, month/year, DST and Pacific/Apia's skipped local date. |
| One-time | Fixed ordinary occurrence and challenge terminal consumption disable the definition; repeated startup/enable cannot silently rearm. Deadline crossing during storage or OS awaits is tested. |
| Enable / disable / delete | Both modes, repeated commands, partial cleanup, write failure before/after effects, retained ownership, deferred active deletion, tombstone ID reuse rejection. |
| Edit / mode change | Seven cases cover time, weekdays, sound, challenge settings/order and both mode directions. Assert new target healthy before old retirement, old preserved on replacement failure, stable retry IDs, active snapshot isolation. |
| Ringing protection | Already-alerting snapshots protect a session even before the local clock reaches its date; alerting during replacement blocks old retirement without cancelling the healthy new target. |
| Conflicts / await races | Bounded three-attempt CAS; unrelated writes merged; newer definitions and operation generations preserved; reentrant commands rejected; snapshots refreshed after intent writes. |
| Schema / corruption | Schema-1 upgrade, schema-2 journal requirement, invalid operation ownership/status and duplicate UUID rejection before effects; all existing persistence corruption/atomicity tests rerun. |
| Domain completion | Degraded state preserves scheduling history; active/completed guards, late scheduling/cancellation acknowledgments and full challenge sequence requirements remain enforced. |
| Platform | Production disk + coordinator + injected AlarmManagerService integration, native recurrence/presentation/sound translation, original seven capabilities, disk integration and native shell launch. |

### New coverage gaps investigated

The first passing expanded run (6924c81, run 37208755043) had 107 core tests and
1800/1848 lines (97.40%). The audit prompted behavioral regressions for duplicate
create, partial acknowledged-chain disappearance, final-snapshot disappearance,
elapsed planned and ordinary inFlight occurrences, scheduling-failure/crash state,
future degraded rollback, completed rollback with pending journal, missing ordinary
ownership, and cancellation throwing after OS removal. The cleanup loop was
corrected so a single recovery pass does not make redundant cancellation attempts.

Passing c48aeb7/run 37209286645 had 117 core tests and 1835/1852 (99.08%).
Inline-region inspection, not just whole-line coverage, then prompted tests for
deleted identity reuse, weekly retries after their original date, unknown commands,
ringing protection (including during replacement), generation supersession, and
invalid late domain acknowledgments. No test fabricates an impossible valid state
or merely asserts execution.

Remaining locations below refer to the Stage 5 production sources (unchanged by
the final test-only revisions). SwiftPM counts closure regions independently,
whereas LLVM LCOV merges line numbers; these are different denominators.

| Location / behavior | Classification / justification |
| --- | --- |
| AlarmLifecycleCoordinator.swift:30, default clock closure | NON-MEANINGFUL COVERAGE. Production delegates directly to Date(); deterministic behavioral tests inject their clock. |
| AlarmScheduling.swift:31, request for ID outside session plan | ERROR/RECOVERY BEHAVIOR. Already tested by the iOS capability suite using the shared production request type; core-only coverage excludes that executable. Do not duplicate solely for percentage. |
| DiskRepository.swift:23, no Application Support URL | PLATFORM-DEPENDENT. Foundation environment lookup has no realistic injected failure; normal lookup, real I/O errors and iOS disk integration are tested. Device storage/file protection remains required. |
| LifecycleEffects.swift:228/235, session/ownership lookup absent | DEFENSIVE/UNREACHABLE BRANCH within the supported single lifecycle owner. Validated journal/ledger references supply these IDs and history is retained. Invalid ownership is rejected at repository boundaries; helpers do not invent records. |
| LifecycleOperation.swift:89, absent detached record during update | DEFENSIVE/UNREACHABLE BRANCH for validated targets and retained history. No public command removes ownership before acknowledgment. |
| LifecycleRecovery.swift:175, journal target session absent | DEFENSIVE/UNREACHABLE BRANCH after repository validation. Corrupt journal references are tested as rejected input. |
| LifecycleRecovery.swift:179, failed target with neither target ID | DEFENSIVE/UNREACHABLE BRANCH for coordinator-produced failed scheduling operations: allocation persists a target before any effect/failure outcome. Keeping empty cleanup safe does not authorize creating or deleting anything. |
| Scheduling.swift:16, validated timezone becomes unavailable | DEFENSIVE/UNREACHABLE BRANCH with stable system timezone database. Init/decode reject invalid zones. |
| Scheduling.swift:57, no date in two-week search horizon | DEFENSIVE/UNREACHABLE BRANCH for tested supported Gregorian dates/zones. Retained fail-closed fallback after the real Apia defect was fixed and regression tested; no fabricated calendar to inflate coverage. |
| WakeUpSession.swift:200/282, nil last-success fallback closures | DEFENSIVE/UNREACHABLE BRANCH. Nonempty full sequence validation precedes completed state; malformed completion and terminal replay are tested. |

Additional zero-count inline guards were reviewed:
- DiskRepository's coordination-error/missing-callback guards and failed removal
  of an interrupted-write marker are PLATFORM-DEPENDENT. Real write/read failures,
  interruption detection and preservation are covered; no Foundation swizzling.
- LifecycleEffects' active early return duplicates ensureTarget's active guard
  (DEFENSIVE/UNREACHABLE through public commands).
- Token checks in failure/final-retirement and allocation's already-target guard
  are defensive against unsupported competing journal writers. Generation
  supersession is tested through the public scheduling path; ordinary parent
  edits/conflicts are independently tested. No claim of multi-process OS atomicity.
- Allocation's disabled-definition nil occurrence is defensive: disabled parents
  use retirement actions, and checkedOperation rejects a changed parent.
- Internal updateSession's missing-ID guard is defensive under the same validated,
  retained-history invariant. Public unknown-parent/operation commands are tested.
- Scheduling's calendar calculation and missing-primary inline guards are
  defensive for validated Gregorian inputs and a validated five-entry plan.

The existing meaningful-coverage policy is unchanged. The final percentage is
evidence of exercised lines, not a claim of exhaustive branches or device behavior.

### Test quality and recursive final review

Five principal remaining risks and their evidence:
1. Disk/OS disagreement after process death: persisted phase matrices, injected
   acknowledgment failures and before/after-effect OS failures assert stable IDs.
   Real daemon freshness and power loss remain device work.
2. Replacement cleanup destroying a healthy target: assert exact old/new sets,
   retry behavior, both mode changes and ringing during the replacement await.
3. Stale writers overwriting intent: CAS conflicts preserve unrelated/newer data,
   bounded conflict exhaustion throws, and superseded generation stops old work.
4. Completion or recurrence bypass: due missing/degraded sessions retain challenges,
   failed cleanup blocks completion/next occurrence, repeated one-time recovery
   cannot create another occurrence.
5. Ownership ambiguity: malformed/duplicate journals fail before OS calls; foreign
   and orphan IDs are untouched; retained history prevents identity reuse.

Most damaging prior assumption: missing AlarmKit presence could invalidate the
historical schedule acknowledgment and accidentally bypass a due session.
Stage 1 was corrected to retain acknowledgments in degraded state; domain,
persistence and lifecycle regressions directly exercise that assumption.
All dependent gates require current replay, not the original Stage 4 run.

The fake records requests/IDs/effects and injects errors, including errors after
effects. It does not implement occurrence calculation, rollback or reconciliation.
Assertions would fail for wrong order, early arming, stop-on-first-cancel-error,
duplicate schedules, foreign cancellation, overwritten state or non-idempotent
recovery. Mock and Simulator evidence does not prove real AlarmKit delivery.

### Final Stage 5 implementation evidence

8118e44dc007143813edf668cca223459cd97b88:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236486724 — SUCCESS.
123 core + 10 iOS unit/integration + one shell UI = 134 distinct tests.
New Stage 5 work: 65 tests including the two Stage 1 recursion regressions.
Core: 1840/1852 (99.35%). Ten merged uncovered source lines plus the two
WakeUpSession completion autoclosures account for all 12 missing counts.
All prior gates pass in this same run. Final documentation HEAD must also pass.
No numeric/meaningful coverage threshold was lowered.

## Stage 6 test matrix — PASS (acceptance evidence below)

Prior 123 core tests and 10 platform unit/integration tests are preserved. The
existing shell-launch test evolves to verify the real list/empty state using injected
effects. New tests must pass alongside these before Gate 6 acceptance.

| Area | Test evidence under validation |
| --- | --- |
| Draft/domain boundary | AlarmEditorDraftTests: new one-time state/defaults, edit round trip/identity, challenge uniqueness/order/QR stability, configured Math/Memory and ranges, wall-clock conversion, sound/repeat labels. |
| Application CRUD | AlarmStoreTests: create/edit/enable/disable/delete through the real coordinator, stable owner, explicit fixed context, deterministic sorting. |
| Authorization | Injected four-state mapping, no startup prompt, intentional request, denied save without OS effects, revoked-access refresh removes healthy claim. |
| Honest failure/retry | Failed scheduling retains configuration and stable retry ID; snapshot failure marks status unconfirmed; failed delete retains ownership; one-time cleanup retry never rearms. |
| Storage safety | Missing vs committed empty, corrupt/future-schema rejection, write failure before OS effect, failed acknowledgment after OS success, recovery without duplicate scheduling. |
| Concurrency/staleness | Paused external effect tests duplicate Save suppression and coalesced foreground refresh; stale expected-original save cannot overwrite newer configuration and explicit reload succeeds. |
| Protected sessions | Store deletion preserves active session and all challenges; no completion/control API in product views. |
| UI create/persistence | Empty → time/weekday/mode/sound → Save → row → actual process relaunch. |
| UI challenge configuration | Memory/Math/QR → configure → accessible reorder → Save → relaunch → exact order/settings restored. |
| UI mutations/errors | Enable failure → needs attention → Retry → healthy; off/on; identity-preserving edit; confirmed/cancelled delete; failed cleanup keeps row. |
| UI one-time/authorization/accessibility | Empty weekdays remain Once after relaunch, Cancel discards draft, injected permission states, large-text toolbar controls. |
| Release | Separate Release compile; executable scan rejects DEBUG UI-test switch/fake scheduler/storage marker. |
| Coverage | Unchanged core report plus separate xccov application-behavior report. No arbitrary SwiftUI-body line target. |

All app tests use real AlarmLifecycleCoordinator. External effects are the fake
boundary; some unit tests seed legitimate persisted phases to test recovery.
No real AlarmKit prompt, scheduling, sound, camera or physical device is required
by UI tests. Fixed date/context and isolated durable test directories keep relaunch
behavior reproducible. Test switches compile only in DEBUG.

### Stage 6 self-review / adversarial findings

- Most damaging UI misunderstanding: enabled is only intent. Status requires a
  successful report and healthy persisted ownership; errors remove certainty.
- Cancel discards draft only; a Save that already persisted state is reported as
  saved-with-attention, not rolled back by dismissing the sheet.
- Superseded drafts require explicit reload; successful partial-save adoption uses
  the full authoritative definition, including any one-time disabled state.
- One-time next date uses durable ownership, never a newly calculated tomorrow.
- Cleanup retries remain available for disabled/deleting one-time definitions,
  while consumed one-time scheduling does not automatically restart.
- Conflicting controls are disabled during async work and the store independently
  suppresses duplicate actions. Foreground refresh is bounded/coalesced.
- Code inspection finds no view repository writes, direct AlarmKit effects or
  challenge completion actions. DEBUG fixtures are isolated from Release.
- Device-only uncertainty (snapshot freshness, real access prompt, intent delivery,
  sound and file protection) remains separate from these tests.

Gate 6 implementation passed the full workflow; final uncovered-behavior audit is recorded below.

### Stage 6 uncovered-behavior audit and final risk review

Run 37258084975 at 4f15ac440e0ab7b0dcb88f5508262efff6e827df provided
actual app coverage despite three failing native interaction tests. The gate was
not accepted. Core remained 1840/1852 (99.35%); no core source changed from the
accepted Stage 5 base. The earlier six-count audit and subsequent recurrence fix
above remain applicable historical evidence, not a new 771/777 result.

| Location/behavior | Classification and action |
| --- | --- |
| AlarmStore.nextOccurrence, challenge session date lookup/expiry | CRITICAL BEHAVIOR. Add a real-coordinator regression comparing the displayed date with the persisted session, then advance the clock and require no invented future date or session mutation. |
| AlarmStore.perform, coalesced refresh throws | ERROR/RECOVERY BEHAVIOR. Inject a snapshot failure after a paused schedule while foreground refresh is queued; retain configuration and uncertainty, issue one schedule only. |
| AlarmStore.requireAccess, enabled Save requests undetermined authorization | CRITICAL BEHAVIOR. Intentional Save requests once; unchanged subsequent edit neither prompts nor schedules again. |
| AppEnvironment.start, repeated startup and throwing preparation | ERROR/RECOVERY BEHAVIOR. Inject preparation failure and assert no readiness, repository load, scheduling or leaked technical payload. Successful repeated start prepares once and leaves a fresh installation empty. |
| AlarmStore.newToken / AlarmFormatting challenge summary | CRITICAL BEHAVIOR. The complete native challenge flow must execute token creation and restored ordered labels after the menu interaction correction; draft tests independently assert stable QR identity through repeated reorder/edit. |
| AlarmStore default Date/current timezone closures; AppEnvironment.make production construction/failure | PLATFORM-DEPENDENT. Deterministic tests inject clock/context and external effects. Production paths compile in Debug and Release; disk/adapter integration tests run separately. Real Application Support availability, current device timezone, permission and daemon behavior remain device integration items. |
| AlarmStore.reportError from failure constructing the fixed valid new draft | DEFENSIVE/UNREACHABLE BRANCH for current valid defaults. Domain validation tests reject malformed configurations; no invalid production initializer or artificial exception added to cover this UI fallback. |
| AlarmEditorDraft SoundChoice lookup fallback and fixed Gregorian picker nil fallbacks | DEFENSIVE/UNREACHABLE BRANCH for the closed sound enum and valid hour/minute inputs. Tests cover every supported sound and midnight wall-time round trip. No fake calendar or invalid time is introduced to execute an impossible picker fallback. |
| AlarmStore.status guards for absent state, mismatched/absent ready target, missing session/ledger | DEFENSIVE guards. A valid ready report validates its target and ownership; public UI obtains rows from that state. Real missing snapshots, stale edits, authorization revocation, partial writes, failed scheduling and protected sessions have behavioral regressions. Guards stay fail-closed; no unchecked repository state is fabricated. |
| Trivial SwiftUI rendering and empty default preparation closure | NON-MEANINGFUL COVERAGE. Native flows assert visible behavior; no line-coverage target for generated body/accessor code. |

No coverage threshold is reduced and no superficial 100% target is introduced.
Final exact-HEAD counts must come from the passing gate, not this intermediate run.

Five remaining integration risks and their checks:
1. A saved enabled flag mistaken for a healthy schedule: failure/retry, revoked
   access, read/snapshot failure and persisted-date expiry tests assert uncertainty.
2. Stale or repeated commands overwrite current intent: expected-original tests,
   deleted-editor regression and paused-effect Save/disable/delete/retry suppression.
3. Startup/foreground overlap duplicates effects: one composition owner, startup
   idempotence, bounded queued refresh, and injected queued-refresh failure tests.
4. UI navigation/selection loses configuration: full native create/edit/challenge
   flows verify identity, exact settings/order and durable process relaunch.
5. Cleanup erases protected ownership: failed-delete UI and active-session store
   tests retain alarm/session/ledger; no product action can declare challenge success.

Most damaging earlier assumption to misunderstand: enabled configuration is intent,
not proof of an armed alarm. The presentation layer requires confirmed lifecycle
state and keeps unresolved ownership visible. No new Stage 1–5 defect was found.
External-effect fakes do not replace the real lifecycle coordinator. Real daemon
freshness, VoiceOver interaction, Settings and alarm delivery remain device work.
### Stage 6 acceptance — full workflow PASS

73971f054d4e74949e6aa0eb32aa026d0d6dc93d:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37728785501 — SUCCESS.
173 distinct tests: 123 core + 41 iOS unit/integration + 9 native UI.
39 new Stage 6 tests: 25 store/composition + 6 draft + 8 UI; the existing shell
launch test now verifies the functional list/empty state. No skipped mandatory flow.
All prior gates, Debug/Release, AlarmKit/App Intents, usage description, Release
fixture exclusion and diagnostics passed in this run. Core source is unchanged
from the accepted Stage 5 base; no earlier gate was invalidated by Stage 6.

Final core coverage is 1840/1852 (99.35%). Five application-behavior files total
431/445 (96.85%): store 167/172, environment 23/27, draft 84/88, formatting 86/86,
status/occurrence presentation 71/72. The meaningful audit regressions all passed.
Remaining uncovered production construction, default closures, closed-enum/calendar
fallbacks and fail-closed status guards have the classifications above. No threshold
changed; no artificial invalid state or superficial coverage-only test was added.
The native challenge test verifies exact Memory/Math settings and order after save
and process relaunch. CRUD, confirmation cancellation, failed cleanup, enable/retry,
Once, authorization and large-text toolbar tests all pass. UI automation explicitly
waits for navigation and Save completion and scrolls the displayed form away from
picker wheels; assertions were not weakened to obtain a green result.

Physical VoiceOver, Settings, daemon behavior, firing, sound and file protection
remain DEVICE REQUIRED. Final documentation HEAD must pass its own complete CI;
its matching run is supplied in the final task report. STOP after Gate 6.
## Stage 7 challenge framework — evidence pending

ChallengeCoordinatorTests adds 34 executions: 15 complete/restored ordered sequences,
15 invalid-identity/order matrices, and four focused adversarial tests (progress and
checkpoint restoration, atomic timestamp rejection, inactive sessions, repository
failure/relaunch). Existing 173 tests remain unchanged. Success moves to completing;
five cancellation IDs remain until the existing lifecycle cleanup confirms them.

Risks reviewed: stale occurrence callback, future index, duplicate callback after
relaunch, checkpoint carrying into the next challenge, failed durable write. Tests
bind identity, assert no mutation on failure, restore exact input, clear checkpoints
on success and discard failed candidates. No earlier model defect was identified.
Focused suite and full exact-HEAD CI pending. Device behavior and engines untested.

### Stage 7 acceptance — full workflow PASS

c35f2c339fb11c42b76db4febb7bae903aa06f8f:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38161005452 — SUCCESS.
Six new Swift Testing declarations exercise 34 cases, including every one of the
15 allowed sequences in ordered/restored completion and rejection matrices.
129 core + 41 iOS unit/integration + 9 UI = 179 distinct reported tests. The prior
173 are preserved; parameter cases/focused reruns are not double-counted.
Coordinator coverage 58/58 (100%); core 1898/1910 (99.37%). The earlier 12 uncovered
counts are unchanged; their existing classifications still apply. Application
behavior coverage remains 431/445 (96.85%). All Xcode/Simulator regression and
diagnostic checks passed; three known SDK metadata advisories remain reported.

The coordinator imports only Foundation and has no engine/UI/platform/effect
implementation references. The last success leaves five cancellation IDs pending
and completedAt nil; only confirmed lifecycle cleanup can finalize completion.
No earlier-stage defect found or gate invalidated. No engine/device claims added.
Final documentation-only HEAD requires its own full CI, supplied in the final report.

## Stage 8 Math test mapping

- MathEngineGenerationBoundsAndIndependentAnswers: three seeded difficulty cases,
  1,000 generated problems each, reproducible stream, operand/operator bounds and
  independently evaluated answers. No property-testing dependency.
- MathEngineInvalidWrongAndSignedAnswers: blanks, syntax, Unicode, overflow, wrong
  answers, negative and explicit positive integer input; no mutation on rejection.
- MathEngineThresholdRestoreAndDuplicate: thresholds 1/2/20, exact JSON checkpoint
  restoration between answers, idempotent preparation, duplicate old problem,
  checkpoint clearing, threshold completion without premature backup cleanup.
- MathEngineRejectsForeignIdentityBadNextAndRegressingTimeAtomically: identity,
  missing/current next UUID, atomic timestamp rejection and Math-to-QR boundary.
- MathEngineOwnerPersistenceFailureAndConflictReplay: failed commit discards progress,
  reload/CAS replay, durable duplicate/final duplicate, foreign/wrong-kind rejection,
  no scheduling/cancellation effect from answer verification.
- MathEngineConflictReplaysAgainstAlreadyAcceptedProblem: concurrent writer commits
  the answer before CAS; replay preserves its next problem and returns stale.
- MathStoreTests: failed initial/answer write, retry, restoration, wrong/duplicate,
  pending cancellation errors, recovery and final cleanup of all five IDs.
- MathChallengeUITests: native typed-answer smoke, blank/wrong rejection, progress,
  durable process relaunch with exact next problem, final completion and no revival.

Focused Math core/application/UI checks run before full core/native regression
checks. Parameterized case executions and focused reruns are not counted as new
unique test declarations. Automated/compile/Simulator acceptance and uncovered
behavior audit will be recorded after the complete required workflow. Device NOT RUN.

### Stage 8 acceptance and uncovered audit — PASS

e42bdaeea8c2a47d0cabe3d1700b323b01172347:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38278057686 — SUCCESS,
every required workflow step. Xcode 26.6 / Swift 6.3.3. Six new core declarations
execute ten cases (including 3,000 generated problems), plus two application tests
and one UI smoke test: nine added declarations, 135 + 43 + 10 = 188 distinct tests.
All prior tests are retained; focused reruns and argument cases are not added again.
Focused Math/core/application/UI checks preceded full regression validation.

Core: 2038/2051 (99.37%). MathEngine 79/80; MathLifecycle 61/61. Prior 12 uncovered
counts retain their classifications. The single new count is Swift's generated
UnboundedRange closure at MathEngine input[...]; unsigned inputs are independently
exercised in wrong/correct/threshold tests. The zero inline Math-kind throw cannot
be reached after restoration plus current-identity validation; no unsafe mutation
hook or redundant test was added to force it. Owner-level wrong-kind and missing
session rejections, and CAS replay over an already-accepted problem, are meaningful
behaviors and now tested. No new uncovered whole core source line remains in LCOV.

App: 478/492 (97.15%): AlarmStore 214/219, AppEnvironment 23/27, AlarmEditorDraft
84/88, AlarmStorePresentation 71/72, AlarmFormatting 86/86. Production Math factory
wiring is now exercised, including revoked permission and unconfirmed external
state while a due challenge succeeds. The original 14 uncovered app counts retain
prior classifications (clock/timezone composition, environment setup/error/default
closures, picker formatting and protected-session presentation); no new whole-line
behavior count is uncovered. Foreign/stale UI identity guards are source-reviewed
and enforced/tested in the owner. SwiftUI rendering is not exhaustively line-covered:
Start Math and error/unsupported-next-kind messages are source-reviewed; preparation,
failed commits and Math-to-QR transitions have behavioral tests. Hardware keyboard,
VoiceOver, largest text and real alarm presentation remain device-required.

Generation, Debug/Release, public SDK/platform compilation, usage description,
fixture exclusion and diagnostics PASS; no compiler/destination warnings, three
known SDK metadata advisories. Simulator smoke/relaunch/completion and all existing
native regressions PASS. Physical device NOT RUN. No earlier defect/invalidation,
coverage-policy relaxation or arbitrary 100% target. Stop after Gate 8 and exact-HEAD
closeout; no Stage 9 implementation. Final documentation HEAD needs its own full CI.

## Stage 9 Memory test mapping

- MemoryEngineDeterministicGeneration: three seeded difficulty cases, exact stream,
  lengths, all digits 0...9 and invalid digits/length rejection.
- MemoryEngineDeadlineHidingRestoreAndNoLeakage: strict reveal boundary, leading zero,
  pre-deadline submission rejection, idempotent prepare, JSON restore, interruption hide,
  hidden restore without answer presentation and no clock-regression reveal.
- MemoryEngineWrongInvalidAndFreshRoundAtomically: wrong recall changes digits/UUID,
  invalid ASCII/length syntax, missing fresh digits and wrong-length next candidate
  rejection without partial progress, stale old submission.
- MemoryEngineThresholdAndOrderedContinuation: 1/2/20 rounds restored between answers,
  exact progress, threshold clears checkpoint, Memory-to-Math preserves active sequence.
- MemoryEngineRejectsForeignIdentityLengthAndTime: foreign identity, invalid preparation
  length, atomic time regression rejection.
- MemoryEngineOwnerFailureConflictDuplicateAndCleanupBoundary: failed hide retains the
  committed round; conflict replay over accepted final recall does not double count;
  completing still owns five cancellation IDs and has no external effects.
- MemoryEngineOwnerClockRollbackStaleTimerAndForeignSession: conservative owner hide
  despite clock reversal, stale timer does not affect a new round, missing session guards.
- MemoryStoreTests: failed prepare/hide/answer writes, safe resume, bounded coincident
  generation, wrong/new round, stale timer/submission, restored progress, failed cleanup,
  production factory and revoked access without prompt or scheduler confirmation.
- MemoryChallengeUITests: initial reveal, timed hiding, wrong/fresh recall, progress,
  process relaunch, completion, home/foreground interruption and navigation recreation
  without re-reveal. DEBUG fixture uses real reducer/owner/disk and injected effects.

Focused Memory checks precede full required core/native regressions in ios.yml.
Acceptance and coverage audit are recorded below. Physical device NOT RUN.

Stage 9 run 38329292490 at 77ac2012eabc0b30cf74eaf77bd3ee53a3461c27 failed
foreground resume UI. The recall flow passed; interruption assertion remains intact.
Root cause/correction are in DEVELOPMENT_LOG. Added busy-owner/coalesced-refresh
regression; late hide after success now verifies a no-op. Full native gate and app
coverage were not reached. Corrected revision must replay the complete workflow.

Final concurrency audit strengthens the busy-owner test to four simultaneous safe
resume hides. Store availability uses FIFO one-waiter handoff (eight pending cap)
to prevent all callbacks racing again after a wake-up. Overflow is source-reviewed
fail-closed concealment/retry; no artificial UI fault hook or 100% target is added.
Run 38332331062 passed focused Math and both Memory UI flows at 4ae35d8 before this
source audit; final FIFO revision still requires the complete matching workflow.

### Gate 9 acceptance and uncovered audit — PASS

017218e893a72125b85402336adebb1c965b00ea:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38334048094 — SUCCESS,
every required step. Xcode 26.6 / Swift 6.3.3 on free standard macos-26.
Seven Memory declarations execute 11 cases; three new application tests and two
UI tests add 12 distinct declarations since Stage 8. Full 142 core + 46 iOS + 12 UI
= 200 distinct tests. Focused repetitions/argument cases are not counted again.

| Evidence layer | Status | Result |
| --- | --- | --- |
| Source | IMPLEMENTED | Pure Memory reducer, existing checkpoint/schema/owner, exact ordered success and protected backup cleanup |
| Automated | AUTOMATED PASS | Deterministic generation, deadlines, hiding, wrong/fresh round, failed writes, CAS, duplicates, thresholds, restoration, revoked access, four competing safe resumes |
| Xcode | XCODE COMPILE PASS | Reproducible project/package, Debug/Release, SDK/platform, usage description, fixture exclusion; no compiler/destination warning |
| Simulator | SIMULATOR PASS | Initial reveal, timed hiding, leading-zero recall, wrong/fresh round, progress, home/foreground, navigation recreation, relaunch, completion; full native regressions |
| Physical device | DEVICE REQUIRED / NOT RUN | No real delivery, audio, camera, OS snapshot, power-loss/file-protection or hardware accessibility observations |

Core: 2207/2220 (99.41%), MemoryEngine 89/89, MemoryLifecycle 80/80. Prior 13
uncovered counts remain unchanged (10 LCOV source lines plus generated/default
closure counts), with prior classifications retained. No new whole core line or
SwiftPM executable count is uncovered. Validated Memory-kind defensive throws are
unreachable after current-identity/restoration validation; do not manufacture an
invalid engine state to drive these inline guards. Meaningful owner missing/stale
identity, timer, late-completion hide and concurrent acceptance paths are tested.

Application behavior: 557/570 (97.72%): AlarmStore 292/297, AppEnvironment 23/27,
AlarmEditorDraft 84/88, AlarmFormatting 86/86, AlarmStorePresentation 72/72. The
protected-session presentation fallback is now exercised. Remaining 13 counts:
store default clock/timezone and reportError adapter; environment default preparation
and production construction/error paths; draft closed-enum/calendar picker fallbacks.
These retain prior source/device classifications. All new Memory whole application
behavior lines are exercised. Source-reviewed inline queue-overflow/exhausted-contention
returns stay concealed with explicit retry; artificial queue saturation is not added
solely for coverage. Four realistic concurrent scene/timer hides now pass, along with
production Memory generation, failed commits and revoked access without prompting.
SwiftUI is not exhaustively line-covered: safe-resume/error/unavailable presentation
is source-reviewed and write rejection is behavior-tested; hardware timing, keyboard,
VoiceOver, largest text and OS snapshots remain device-required.

The initial foreground-resume failure was traced to Stage 9's caller assuming the
valid busy store was immediately available. Its unchanged UI assertion passed after
correction; the final FIFO audit prevents waiting callbacks stampeding on availability.
No earlier architectural defect identified. One correction run failed at Xcode app
launch before Math assertions; identical source passed full replay on an isolated
validation ref (Actions 38332331062). No skipped/cancelled check is counted as passing.

Final source generation, Debug/Release, all focused/full tests, fixture exclusion
and diagnostics PASS. Three known SDK metadata advisories reported. Coverage policy
and valid tests were preserved. Final documentation HEAD still requires its matching
complete workflow; final task report supplies that immutable SHA/run. Stage 10 NOT STARTED.

## Historical Stage 11 initial implementation — pending claims superseded above

At initial implementation, prerequisite exact-main 95d781f / run 38587030123
attempt 2 was verified SUCCESS, every step;
this supersedes Stage 10 pending closeout text above. Gate 11 source IMPLEMENTED.
Generator byte reproducibility: local PASS. Native resource/fallback/persistence/
preview tests and management audio UI: PENDING exact-source CI. Xcode/Simulator:
PENDING. Device: DEVICE REQUIRED / NOT RUN. Imported audio deferred by separate probe.
Coverage reporter includes catalog, preview and AlarmKit configuration factory;
review uncovered outcomes after full native coverage. Prior core coverage policy
and classifications remain. No fake-percentage target or discarded assertion.
