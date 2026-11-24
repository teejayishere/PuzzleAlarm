# PuzzleAlarm approved completion plan

Owner decision: **2026-11-23 (America/Chicago)**. Approved: autonomous completion,
all-three-challenge Appetize delivery first, four milestones, diagnostic probes
separate from product acceptance, and bounded parallel challenge implementation
after shared contracts stabilize. This replaces the former checkpoint work order;
it does not accept historical gates or weaken functional requirements.

## Delivery and scope

First delivery: configure an alarm, start a simulated due occurrence, solve Math,
Memory and QR in saved order, resume after relaunch, and succeed only after the
complete sequence. Scheduling and QR camera input are visibly simulated. Use the
same domain/session/coordinator path as the device app, with preview injection
unavailable in device builds. A Math-only increment is feedback, not completion.

Final V1 retains both alarm modes, persistent configuration, all three engines,
QR generation/sharing/scanning, default and bundled sound preview/fallback,
AlarmKit occurrence routing, primary plus four backups, cancellation recovery and
next-occurrence scheduling. Actual OS/hardware behavior requires physical evidence.
Remain $0: no paid service, backend, sync, subscriptions, redesign or imported-audio
detour. Keep restart lineage, existing code and architecture; no old-lineage imports.

## M1 — Trustworthy alarm management and stable contracts

Finish create/edit/cancel/enable/disable/delete, challenge settings/order and
relaunch, asserting stored state and injected service effects. Investigate QR Save
with one reproducible journey and repair confirmed defects. Current implementation
slice is the native wheel time-picker UX improvement; functional management is
next, followed by coordinator/contracts and engines.

Freeze challenge commands/results, stable session/problem/round identity,
snapshots, clock/randomness and scanner inputs. Reuse WakeUpSession and
ResumeCheckpoint; one integration owner controls persistence and lifecycle.
Exit: management journeys work, contracts compile with focused invariant tests,
and remaining failures have reproducible impact/classification. Keep the failed
native activation-point probe FAILED/diagnostic-only; demonstrate equivalent real
editor/list interactions before accepting those product requirements.

## M2 — Playable Appetize version

Implement ChallengeCoordinator and one host, then Math, Memory and QR against
existing configuration/snapshot models. Use deterministic engines, explicit wrong
answer behavior, idempotent submissions and specified interruption/restart policy.
Hide answers and post-display Memory digits, including accessibility text.

Add preview-only Run Now and labelled QR simulation using the camera adapter's
exact-match logic. Deliver usable increments, prioritizing the complete three
challenge sequence. Exit: focused engine tests; all allowed order permutations;
duplicate/wrong-index rejection; restore tests; and create → run → solve → success
UI journey. Publish .app ZIP with exact source SHA/run. Mark Appetize interaction
verified or not verified separately. A short demo may fit free sessions without
weakening normal engine validation.

## M3 — Real alarm integration

Finish bundled sounds, preview cleanup/fallback, intent/foreground occurrence
routing, cancellation recovery and next-occurrence scheduling. Verify transactional
five-alarm scheduling with partial-failure rollback. Stopping primary or solving
one challenge cannot complete the occurrence. Duplicate callbacks/interruption
cannot cancel backups early or schedule duplicates. Exit: real-adapter compilation,
focused lifecycle/integration regressions and Simulator journeys with injected
platform services. No real ringing claim from Simulator evidence.

## M4 — Device verification and handoff

Investigate free installation/signing early; availability is unresolved. On the
owner's iOS 26+ iPhone verify permission deny/allow, locked/background firing,
intent launch, camera matching, sounds, backups/cancellation and relaunch. Repair
observed failures with focused regressions. Run the relevant full release suite
once integration stabilizes; preserve artifact, evidence and known limitations.
Exit: device checks pass, or identify the exact external blocker and label delivery
DEVICE READY — NOT DEVICE VERIFIED. An unsigned artifact is not installable.

## Operating and validation policy

- Proceed autonomously across milestones; update the owner on meaningful changes,
  completed milestones or blockers. Ask only for product decisions, authentication,
  external blockers and device actions. No routine milestone approval required.
- Integration owner owns shared contracts, persistence/session/schema, composition,
  navigation, workflows and acceptance. Once contracts stabilize, at most two
  workers implement disjoint challenge files; QR follows or uses a freed slot.
  Give compact contracts, file ownership and exit cases. Review completed milestones
  and critical platform/cancellation boundaries; parent verifies integration.
- Before validation record checks and an explicit bounded $0 allocation, including
  local checks and automatic triggers. Default development ceiling: one candidate
  plus one changed correction, at most 25 minutes/run and 50 aggregate runner-minutes;
  zero unchanged failing retries. Stop the slice after the second failure or budget
  exhaustion, preserve a reproducer and record a new hypothesis before further work.
  This plan itself allocates no executions.
- Core tests establish rules, representative complete UI journeys establish user
  flows, and physical checks establish OS/hardware behavior. Preserve real identity,
  readiness, timeout, error, storage, service-effect and relaunch assertions. Failed
  diagnostics remain failed with evidence; they do not block unrelated functional
  work. A demonstrated core/session/scheduling defect blocks its dependents.
- Trace defects to the earliest affected requirement and invalidate/rerun affected
  dependent evidence in order, including Gates 0–5 if disproved. Do not invalidate
  unrelated unchanged algorithms or accept historical gates wholesale.
- Build/package before optional Simulator diagnostics, in bounded separate steps.
  Keep source, automated, Xcode, Simulator launch, Appetize interaction, manual
  accessibility and device evidence distinct. Source acceptance requires successful
  relevant CI for the exact published source SHA; a parent run never passes a new
  source revision. Reuse matching unchanged-source success.
- Include planned documentation before source validation. A later documentation-only
  revision receives documentation review and links the assessed app SHA/run; no app
  CI loop is required merely to restate that result, and no exact-new-HEAD app pass
  is claimed. Preserve provenance, requirements and raw historical evidence.
- Keep PROJECT_STATE concise and current, TEST_MATRIX as acceptance/evidence map,
  and link logs/history rather than repeating narratives. Read relevant engineering
  lessons before repairs; record proven cause separately from unresolved trigger.

## Starting evidence and remaining owner input

Preview source `758ccc61256836bf7c36756e6b0f266126b6215f`, workflow
[45294551508](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45294551508)
SUCCESS, artifact `14877015172`: compiled/installed/launched Simulator preview,
not full product acceptance or verified Appetize interaction. Prior diagnostic
run `45252354273` on `a7b5fa869f68ab4d6558354c6324b4b6e98ded8d` remains FAILED.
Original QR Save cause remains unresolved. No milestone is accepted by this plan.

Only pending owner information: available iPhone/iOS version and existing free
development-build installation method. No completion date is promised before
integration work establishes the remaining effort.
