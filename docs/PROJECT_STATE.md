# Project state

Current stage: 12, recursing to the unresolved Gate 6 native-input boundary.
Gate 6 is FAILED; dependent Gates 7–12 are INVALIDATED / HELD. Last unheld gate: 5.
Stage 13 NOT STARTED. A later green run alone cannot clear a known unexplained failure.

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

The diagnostic positively attached a passive public window recognizer and recorded
actual app/scene activation, touch coordinates, public control ancestor, target
identity/count and control state. All observed inputs succeeded; no failing trace
was collected. Successful samples show touch began/ended on an attached enabled
UISwitch in active app/scene, followed by valueChanged, binding and owner completion.
This is not evidence of the earlier miss's cause, nor proof of an OS defect.
Temporary probe/subclass are removed and the original ten-flow check restored.
An uninstrumented pass after removal still cannot alone establish root-cause correction.

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

## Next action and scope

Correct the earliest demonstrated cause, invalidate affected evidence, then replay
Gate 6 and dependent Gates 7–12 in order. Publish only with complete exact-final-HEAD
CI; the final task report must state immutable SHA/run and the actual gate outcome.
A blocked gate is not a pass. Historical records are retained in DEVELOPMENT_LOG
and TEST_MATRIX, not mixed into this current-state summary.

MASTER_PLAN records the requested roadmap: Stages 12–13 finish functional routing /
orchestration; after Gate 13, schedule a dedicated UX pass for simpler alarm creation
and list hierarchy, challenge navigation, large focused Math/Memory/QR layouts and
clear countdown/progress/feedback. Cosmetic polish is deferred. No redesign or
Stage 13 implementation belongs in this task.
