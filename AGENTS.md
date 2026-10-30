# PuzzleAlarm restart authority

Owner decision: 2026-10-29 (America/Chicago).
Active lineage: `codex/restart-gate5-20261029-f8a41c`, created directly from
`159b777379ad587a615df56ef24fa273aa29ffe4` (Gate 5 baseline).
Baseline exact-HEAD CI: SUCCESS, run 37236891939:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939

Gates 0–5 are the inherited accepted baseline. Stage 6 (Alarm Management UI)
is the next unimplemented stage. Stages 6–14 must be independently rebuilt
and gated in the order specified by the unchanged docs/MASTER_PLAN.md.
All prior Stage/Gate 6–14 implementation, recovery and promotion paths are
abandoned. Their failures are historical lessons only: not current blockers,
accepted gates or work queues. Do not merge, cherry-pick or copy later source,
tests, workflows or status summaries from main, recovery or Stage 6–14 branches.

Before every future stage session:

- Fetch origin and verify `codex/restart-gate5-20261029-f8a41c` before interpreting
  any status. Read its remote docs/PROJECT_STATE.md first, then its AGENTS.md.
  GitHub's default branch is this restart branch; stale clones may still select main.
- Verify repository identity, clean working tree, branch, HEAD and ancestry.
  Require fixed anchor `862c2d872958c2e08971acbf605bbcf07ee4b3d5`, whose sole
  parent is the baseline above; reject all merge commits after it. Inspect every
  post-baseline commit; baseline ancestry alone does not exclude old descendants.
  Stop on conflicting lineage, unexpected changes or unverifiable provenance.
- Read this file and active docs/PROJECT_STATE.md, then the baseline specifications,
  evidence and relevant source/tests. These restart sections supersede inherited
  stop/next-action instructions and any abandoned-lineage status.
- Inspect actual CI for the exact current HEAD and record SHA, run and result.
  A baseline/parent run is not a current-HEAD pass. Missing, skipped, pending,
  failed or blocked CI is not PASS; obtain successful exact-HEAD prerequisite
  evidence before stage implementation or promotion under an explicit budget.
- Apply recursive invalidation to evidence in this new lineage only, including
  inherited Gates 0–5 if new evidence disproves them. Trace the earliest cause,
  invalidate dependent gates and rerun them in order; never advance past a
  failed or blocked prerequisite. Old-lineage failures do not invalidate this one.

Historical CI budgets and exceptions neither authorize nor block new execution.
Before any new validation, record an explicit, bounded, $0 budget identifying
checks, maximum runs/retries and runner time; stop at its limit and report results.
The anchor's instructions-only session is complete; its zero-CI scope and [skip ci]
instruction are historical, not a reusable exception. Hardening only is authorized
for this session: at most two complete CI executions, automatic triggers included,
no reruns, 25 minutes each and 50 aggregate runner-minutes, $0 standard public runners.
Stop on failure or budget exhaustion. Include documentation before validation and
verify SUCCESS for the exact final published HEAD. No local product validation.
Run `python3 Scripts/check_restart_lineage.py` with full history; CI runs it before
existing validation. It checks anchor parentage, ancestry and absence of later merges.
It cannot detect copied/cherry-picked old code, altered checks or stale entry points;
manual review of every post-baseline commit remains required. PR CI checks the
submitted head, not GitHub's synthetic merge. No branch-protection guarantee is claimed.
Preserve baseline specifications and source/tests. STOP after hardening; Stage 6
is NOT STARTED. The next implementation scope is independently rebuilding Stage 6
and stopping after Gate 6: no Stage 7 or old recovery/promotion work.
Original engineering rules follow unchanged.

# PuzzleAlarm engineering instructions

Read docs/MASTER_PLAN.md, docs/PROJECT_STATE.md, docs/DEVELOPMENT_LOG.md,
current source/tests, and git status/diff before substantial work.

Follow the ordered gates in MASTER_PLAN. A blocked gate is not a pass.
Do not advance past a failed or blocked prerequisite. Trace later failures
to their earliest cause, invalidate affected gates, and rerun them in order.

Use only free tools and public Apple APIs. Keep credentials and signing material
out of this repository. Core must not depend on SwiftUI, UIKit, AlarmKit or
AVFoundation. Never invent AlarmKit signatures: inspect SDK and compile a spike.

Record source, automated, Xcode, Simulator and physical-device evidence separately.
Never report a CI pass without a run for the exact revision being assessed.
