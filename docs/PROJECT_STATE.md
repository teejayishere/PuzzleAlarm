# Active restart project state

Owner decision: 2026-10-29 (America/Chicago).
Active/default branch: `codex/restart-gate5-20261029-f8a41c`.
Fixed restart anchor: `862c2d872958c2e08971acbf605bbcf07ee4b3d5`.
Sole anchor parent / Gate 5 baseline: `159b777379ad587a615df56ef24fa273aa29ffe4`.

Current session: Gate 6 behavioral repair — 2026-11-19. Stage 6 implemented;
Gate 6 FAILED / NOT ACCEPTED until repaired final published HEAD passes full CI.
Most recent assessed source HEAD: bebab3bae22662a11d514a1f32b1f6cf97a55e1f.
Exact-HEAD [run 44593570818](https://github.com/teejayishere/PuzzleAlarm/actions/runs/44593570818):
completed/FAILURE, attempt 1. Both UI flows now fail earlier switch value/readiness
assertions (editor enabled and Monday). The combined predicates do not identify
which term failed; actual values/types and gesture targets were not logged.
The async list-binding hypothesis is insufficient: editor bindings use direct
draft state. The Memory selector repair and new list binding were NOT reached by
these flows and remain unverified. Do not describe them as fixed.

Observed partial successes: 123 core tests, coverage 1840/1852 (99.35%), 19 iOS
unit/integration tests (all nine management tests), app/test compilation, failure-
visibility UI and shell UI. Two of four UI tests FAILED; diagnostics review skipped.
No evidence disproves Gates 0–5; Gate 6 still blocks every later gate.
Budget consumed: ONE of two executions, 688 seconds (11m28s) / 3000 allowed runner-
seconds, $0. Stop-on-failure invoked; second run is NOT AVAILABLE for another repair.
No retries, further product edits or new validation after failure. This evidence-only
closeout uses [skip ci] to avoid another automatic execution; its HEAD is UNVALIDATED,
not a CI pass or Gate 6 acceptance. Workflows remain unchanged.

Next action: resume Gate 6 with a newly bounded diagnostic allocation. Capture
switch value AND runtime type, enabled/hittable state, frame/children, screenshot
and hierarchy before/after one gesture; distinguish native hit/automation behavior,
predicate representation, draft mutation and service entry before another app fix.
Compare a simple direct-state switch with the actual editor/list in a focused
Simulator reproduction; retain final persistence assertions. Do not increase waits,
retap blindly, weaken assertions or treat passing service tests as UI success.
Then repair the demonstrated boundary and require full exact-final-HEAD SUCCESS.
Stage 7 Challenge Framework is recommended only AFTER Gate 6 passes and owner
authorization. It remains NOT STARTED. Continue in this Codex chat from GitHub.

The pre-validation plan below is preserved for this failed candidate; its pending
and conditional next-action text is superseded by this observed closeout.

Starting remote HEAD: c6820739f7fcd233a6c289482f7fe2ada2042fca.
Exact-HEAD [run 43653592216](https://github.com/teejayishere/PuzzleAlarm/actions/runs/43653592216):
completed/FAILURE. Its predecessor 1c8e63f failed UI-test compilation in
[run 43650136918](https://github.com/teejayishere/PuzzleAlarm/actions/runs/43650136918).
The selector fix exposed a Memory stepper identifier mismatch and an enabled-state
interaction failure that survived edit/relaunch. These are Gate 6 findings, not
proof of an earlier lifecycle failure. Gates 0–5 remain inherited accepted; no
current evidence disproves them. All dependent gates blocked; Stage 7 NOT STARTED.

Repair: synchronous temporary switch state during async commands, reconciliation
to stored definitions on completion/failure, precise accessible switch hit targets,
and the actual Simulator stepper identifier. Strengthened assertions cover weekday
and Memory-round persistence, disable/edit/relaunch and re-enable/relaunch; fail at
the first broken prerequisite within each flow. See STAGE6_SESSION for diagnosis,
behavioral audit and evidence limits. Core, baseline tests/specifications and the
full workflows remain unchanged. No abandoned implementation imported.

Fresh $0 budget recorded before checks: at most TWO full ios.yml executions,
automatic triggers included; 25 minutes each / 50 aggregate runner-minutes. First
run validates repair plus documentation; second only closes out evidence after
first SUCCESS. Zero retries/unchanged-code reruns; stop on failure or exhaustion.
Clean fetched independent clone, audited external preflight and repository lineage
PASS. Local source/diff audit is separate from Swift/Xcode/Simulator validation,
which remains PENDING for the new candidate. Original dirty checkout at 8deb0dd,
local-only commits, old worktrees and all evidence/quarantine remain preserved.

Next action: validate Gate 6 within this budget, record the observed SHA/run/result,
and STOP at its decision. Stage 7 (Challenge Framework) requires owner authorization;
continue here in Codex from GitHub context without a new generated prompt.
Physical-device, manual VoiceOver and largest-text usability NOT RUN. Real
authorization, delivery, audio and file protection remain DEVICE REQUIRED and
outside Gate 6's hardware-independent acceptance. No device success is claimed.

## Authority and entry points

This active section is the single current-status authority. README files,
CONTRIBUTING, historical logs and evidence summaries defer here; MASTER_PLAN remains
the unchanged specification. Historical status/STOP/next-action statements below
are records for their named revision, not live instructions.

Before interpreting status, fetch origin, verify the active branch and read its
remote PROJECT_STATE.md FIRST, then AGENTS.md. Verify identity, clean checkout,
local/remote refs, fixed anchor/sole parent and every post-baseline commit. Stop
on unexpected divergence or unverifiable provenance. Existing clones, old worktrees,
bookmarks and explicit main/old-branch links can still enter abandoned history.
GitHub default branch was changed through authenticated repository settings during
hardening. All inactive remote branch tips now carry HISTORICAL / ABANDONED notices
in README.md, AGENTS.md and docs/PROJECT_STATE.md; their existing content and commits
are preserved. Local obsolete worktrees are not repaired by remote annotations.
See [branch/worktree inventory](DOCUMENTATION_RECONCILIATION.md) for original/new SHAs
and explicit do-not-use guidance.

All prior Stage/Gate 6–14 implementation, tests, workflows, recovery, promotion and
status paths are abandoned. Do not merge, cherry-pick or copy them. Preserve baseline
product source, tests, specifications and evidence. Old failures are historical
lessons only, not blockers or work queues; no old-history review is prerequisite.

`Scripts/check_restart_lineage.py` requires full history, the fixed anchor with its
sole baseline parent, anchor ancestry and no merge commits after the anchor. Both
branch workflows run it before existing checks. PR CI checks the submitted head,
not GitHub's synthetic merge. Ancestry cannot detect copied/cherry-picked old code;
review all later diffs. Checks can be edited or bypassed, and no server-side branch
protection guarantee is claimed. The fixed anchor must not move with branch HEAD.

## Completed hardening evidence (historical session)

Hardening finished at `7c04baf2bd474df3403a0152835e70c08a27f007`.
Its exact-HEAD [CI run 41001050547](https://github.com/teejayishere/PuzzleAlarm/actions/runs/41001050547)
was rechecked completed/SUCCESS before this reconciliation. The budget and candidate
wording below are preserved completed-session records, not a new work authorization.

- Baseline tree: `a2f058dfd860945a10ea5236a7ad5f4c27e23885`.
- Baseline exact-HEAD CI SUCCESS: `159b777379ad587a615df56ef24fa273aa29ffe4`,
  https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939
- Restart anchor: sole parent verified; only AGENTS.md and PROJECT_STATE.md differ
  from baseline. No anchor CI run exists ([skip ci]); no anchor PASS is claimed.
- Hardening budget recorded before validation: $0, at most TWO complete CI executions
  including automatic triggers, NO reruns, at most 25 minutes each and 50 aggregate
  runner-minutes. Existing validation and public standard macos-26 remain intact.
  Stop on failure or budget exhaustion. No local product tests/builds or device runs.
- Candidate includes these docs before CI. Final hardening SHA, run URL/result and
  actual runner time are verified after publication and reported in the task closeout;
  this candidate text alone does not claim a successful final-HEAD run.
- Local checks are limited to preflight acceptance/rejection and diff integrity;
  CI supplies automated, Xcode and Simulator evidence separately from device evidence.
- Local hardening checks: anchor accepted; pre-anchor baseline and unreferenced
  synthetic merge descendant rejected; diff whitespace check clean; preserved Gate 5
  snapshot unchanged (UTF-8 comparison). No product source/tests/specifications changed.
- Physical-device validation: NOT RUN. Inherited baseline limitations below remain.

## Documentation reconciliation session

Documentation only; Stage/Gate 6 remain NOT STARTED and no gate is newly accepted.
Owner authorization includes retirement notices on all inactive branch tips, solely
superseding the former leave-old-branches-untouched restriction for those notices.
All original content remains underneath; no old implementation enters this lineage.

Budget recorded before changes: $0; at most TWO complete active-branch CI executions,
automatic triggers included; no unchanged-code reruns; 25 minutes each / 50 aggregate
runner-minutes. Stop on failure or exhaustion. No local product validation. Existing
full CI checks remain unchanged. All active docs must precede validation; acceptance
requires SUCCESS for the exact final published HEAD, reported with its run in the
session closeout. This pre-validation text does not claim that result.
See [documentation reconciliation record](DOCUMENTATION_RECONCILIATION.md).

## Standing prerequisites and next implementation scope

The anchor and hardening sessions are complete; their scope restrictions are historical.
Reuse successful CI whose SHA matches an unchanged current HEAD after checking its
actual result. No unchanged-code rerun is required. A parent/baseline run is never
evidence for a changed HEAD. Missing, skipped, pending, failed or blocked CI is not
PASS. Before new validation, record a fresh explicit bounded $0 budget; do not inherit
old session budgets or exceptions.

STOP after this documentation-only session. In a separately authorized implementation
session, verify provenance and exact-current-HEAD SUCCESS, independently rebuild
Stage 6 and satisfy Gate 6 in unchanged MASTER_PLAN.md, then STOP. No Stage 7 or old
Gate 6 repair/recovery/promotion work. Recursive invalidation applies within this
lineage, including inherited Gates 0–5 if disproved; rerun affected gates in order.
Old-lineage failures and budgets are nonbinding and not prerequisite work queues.

## Preserved Gate 5 snapshot

The following PROJECT_STATE content is preserved verbatim from the lineage root
as baseline specifications/evidence context. Its old final-CI/STOP/next-action
wording is historical and superseded by the active restart instructions above.
The verified final Gate 5 run is 37236891939; 37236486724 below is its earlier
implementation evidence, not evidence for a new HEAD.

---

# Project state

Current stage: 5 — implementation PASS; stopped before Stage 6
Last passing gate: Gate 5 (implementation evidence below)
Gates 0–4: replayed and restored
Invalidated gates remaining: None
Blocker: None
Current status: Lifecycle orchestration implemented and tested, not connected to product UI

## Exact implementation evidence

Revision: 8118e44dc007143813edf668cca223459cd97b88
CI: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236486724
Result: SUCCESS, full workflow on free standard macos-26.
123 core + 10 iOS unit/integration + one shell UI = 134 distinct tests.
New since Stage 4: 65 tests (61 lifecycle, two domain recovery, two iOS).
Focused persistence: 32 core; original iOS disk and new lifecycle disk composition pass.
Core coverage: 1840/1852 line counts = 99.35%.
Package validation/build, generated project reproducibility, AlarmKit/AppIntents,
iOS build, usage-description verification and Simulator tests all passed.
No avoidable production warnings. Known UI-test SDK advisory remains:
"Metadata extraction skipped. No AppIntents.framework dependency found."

This is the immutable source/test evidence. A documentation-only follow-up must
also pass its own complete workflow before final task acceptance. The final task
report supplies that exact HEAD/run; no old run substitutes for current CI.

## Architecture and behavior

One actor-isolated AlarmLifecycleCoordinator owns lifecycle effects through the
shared AlarmScheduling protocol. Reentrant commands fail as busy. Repository CAS
retries at most three times; conflicts re-read and preserve newer state.

Schema 2 adds a durable operation journal; schema 1 loads and upgrades on write.
Session/detached ledgers retain primary/backup UUID ownership. Every schedule/cancel
intent precedes the external effect; acknowledgment is separate. Unknown ownership
is never reconstructed from AlarmKit metadata or silently cancelled.

Challenge scheduling persists all five stable IDs, schedules in order and arms only
after acknowledgment and observed presence. Failures roll back every relevant
owned/uncertain sibling; cancellation errors preserve ownership and do not stop
other siblings. Explicit safe retry retains IDs; automatic recovery retries cleanup.

Ordinary weekly alarms use a single relative schedule; one-time uses a fixed date.
Challenge recurrence creates one concrete successor after trusted completion and
cleanup. One-time consumption disables and does not rearm on startup/enable.

Enable, disable, delete, edit and mode changes are idempotent. New replacements
become healthy before old retirement; replacement failure preserves the old target.
Active/ringing session snapshots are protected. Delete waits for cleanup/protected
sessions and retains minimal history/tombstones.

## Recursive findings and coverage audit

Stage 1 required missing-armed and fully-rolled-back retry transitions. Further
review corrected missing presence to degraded, preserving historical acknowledgments.
Due degraded sessions become active, never completed by absence. Gates 1–4 were
invalidated during correction and fully restored by the current passing replay.

The original 771/777 six-count audit is preserved in TEST_MATRIX.md, including the
earlier skipped-local-date defect and regression. New Stage 5 audit tested whole
lines and inline regions. Remaining 12 counts (10 LCOV lines + two completion
autoclosures) are individually justified there. Coverage policy was not weakened.

## Known limitations / device-required items

- One live lifecycle owner per repository. Separate concurrent coordinator processes
  are not supported; future extensions must route through the owner or add a tested
  cross-process effect serialization design.
- No disk/AlarmKit atomic transaction or guarantee of daemon snapshot freshness.
  Replacement may temporarily overlap old/new IDs; real capacity/delivery is unproven.
- Corrupt/lost ownership blocks safe automatic reconstruction. Unknown app-owned
  IDs are reported, never assigned invented parent/session links.
- Sound identifiers map to future .caf resources; no audio files/playback implemented.
- Product UI/startup wiring, engines, camera, final intent routing and Stage 6+ remain
  unimplemented. Tests do not claim these features.
- Device required: authorization, real scheduling/firing, lock screen, Silent/Focus,
  Stop, snapshots/reconciliation, intent delivery, audio and file protection/power loss.
- No paid runner/service, local Windows Swift installation, credentials or signing
  material introduced. Unrelated Investment Dashboard was not modified.

## Next action

STOP after the documentation revision's full CI is green. Do not begin Stage 6.
No user action is required to complete Gate 5.
