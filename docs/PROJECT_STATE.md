# Active restart project state

Owner decision: 2026-10-29 (America/Chicago).
Active branch: `codex/restart-gate5-20261029-f8a41c`.
Lineage root: `159b777379ad587a615df56ef24fa273aa29ffe4`.
The restart instructions commit must have that SHA as its sole parent.

Current stage: 6 — Alarm Management UI, NOT IMPLEMENTED.
Current gate: Gate 6 — NOT STARTED.
Last accepted gate: Gate 5; Gates 0–5 are the inherited accepted baseline.
Invalidated gates in the new lineage: None.
Current blockers: None inherited from abandoned Stage 6–14 history.
Status: Instructions-only restart; no product changes or new gate acceptance.
All later stages must be independently rebuilt and gated from this lineage.

## Authority and provenance

AGENTS.md and this active section govern the restart. Preserve the baseline
MASTER_PLAN, DEVELOPMENT_LOG, TEST_MATRIX, architecture, source, tests and workflows.
All previous Stage/Gate 6–14 implementation, recovery and promotion paths are
abandoned. Their failures are historical lessons, not blockers, accepted gates
or queues here. No later code, tests, workflows or status summaries may be merged,
cherry-picked or copied into this lineage. No old-history review is a prerequisite.

## Evidence and limits

- Baseline commit and tree verified against GitHub; original checkout was clean.
  Baseline tree: `a2f058dfd860945a10ea5236a7ad5f4c27e23885`.
- Baseline exact-HEAD CI verified completed/SUCCESS for
  `159b777379ad587a615df56ef24fa273aa29ffe4`, run 37236891939:
  https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939
- Restart source evidence: documentation-only diff and direct-parent ancestry.
  The commit containing these instructions is the restart anchor; resolve its
  exact SHA from git, rather than substituting the baseline SHA as its HEAD.
- Restart automated/product validation: NOT RUN by owner instruction. CI skipped
  with [skip ci]; no exact-HEAD CI pass is claimed for the restart commit.
- Restart Xcode, Simulator and physical-device validation: NOT RUN.
- Open engineering risks, unverified assumptions and device-required validation:
  inherited baseline limitations below remain; no new product evidence is claimed.

## Next-stage instruction

STOP this session after committing, publishing and verifying the restart branch.
A future Stage 6 session must first verify repository/branch provenance, restart
anchor ancestry, clean tree, active state and actual exact-HEAD CI as required by
AGENTS.md. Missing/skipped CI is not PASS. Establish an explicit, bounded, free
validation budget and obtain successful prerequisite CI before implementation.
Then independently implement Stage 6 — Alarm Management UI — and satisfy Gate 6
in MASTER_PLAN. Do not resume an old recovery or promotion path.
Recursive invalidation applies only within this lineage, including any inherited
gate disproved by new evidence; rerun affected gates in order. Historical budgets
and exceptions have no authority. This session's validation budget is zero product
validation runs and zero CI executions; read-only repository/evidence checks only.

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
