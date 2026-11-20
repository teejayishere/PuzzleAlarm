# PuzzleAlarm restart authority

Owner decision: 2026-10-29 (America/Chicago).
Active lineage: `codex/restart-gate5-20261029-f8a41c`, created directly from
`159b777379ad587a615df56ef24fa273aa29ffe4` (Gate 5 baseline).
Baseline exact-HEAD CI: SUCCESS, run 37236891939:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939

Gates 0–5 are the inherited accepted baseline. Current gate status and next scope
belong only to docs/PROJECT_STATE.md. Stages 6–14 must be independently rebuilt
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

## Standing validation rules

Historical CI budgets and completed session restrictions neither authorize nor block
new work. Reuse an existing successful CI run when its SHA matches the unchanged
current HEAD; no unchanged-code rerun is required. A parent/baseline run cannot
validate a new HEAD. Before any new validation, record an explicit bounded $0 budget
identifying checks, maximum executions/retries and runner time. Stop on failure or
budget exhaustion. Include all documentation before final validation and verify
SUCCESS for the exact final published HEAD. Keep evidence categories separate.

Run `python3 Scripts/check_restart_lineage.py` with full history; CI runs it before
existing validation. It checks anchor parentage, ancestry and absence of later merges.
It cannot detect copied/cherry-picked old code, altered checks or stale entry points;
manual review of every post-baseline commit remains required. PR CI checks the
submitted head, not GitHub's synthetic merge. No branch-protection guarantee is claimed.
Preserve baseline specifications and source/tests. The single current-status authority
is the active restart docs/PROJECT_STATE.md; other summaries defer to it.
The next implementation scope is independently rebuilding Stage 6 and stopping after
Gate 6: no Stage 7 or old recovery/promotion work.

Owner-authorized Codex operating loop (2026-11-19): manage planning, implementation,
debugging, documentation and next-stage instructions directly in Codex using GitHub
as durable memory. After each stage, update PROJECT_STATE and relevant evidence
records with assessed SHA, actual CI result, gate decision, remaining risks and next
action. Include documentation before final full validation; the published HEAD's
Actions result is authoritative for that final revision. Stop at the authorized gate;
obtain authorization before the next stage, without requiring a new generated prompt.
Ask only for product decisions, authentication, external blockers or device actions.
Preserve the original dirty 8deb0dd checkout, local-only commits and all quarantine
evidence. Use a separately verified clean checkout; non-force fast-forwards only.
An explicitly authorized repair of a failed current gate may change that gate's
candidate without rerunning unchanged failing code first. It does not waive earlier
prerequisites, recursive invalidation or exact-final-HEAD full CI SUCCESS.

## Stage 6 checkpoint operating policy - owner-approved 2026-11-19

Owner-authorized 6A sequential repair loop (2026-11-20): after a failed focused
execution, preserve evidence, diagnose the earliest cause, repair that cause and
validate the changed candidate until focused 6A succeeds within a fresh bounded
$0 allocation. This supersedes stop-after-first-failure for that allocation only;
no unchanged failing reruns, assertion/timeout weakening or later-checkpoint work.
Stop on exhaustion, external blocker or success. Record each assessed SHA/run/result
and include documentation before validating the final published HEAD. Focused
success still does not accept Gate 6 or authorize 6B/Stage 7.

Stage 6 uses ordered checkpoints 6A-6F in docs/MASTER_PLAN.md, with scenario
contracts in docs/TEST_MATRIX.md. This additive owner-approved refinement preserves
the original master-plan requirements and gate order; prior references to an
unchanged MASTER_PLAN do not forbid this refinement. PROJECT_STATE remains the
single status authority. Start with the earliest unresolved checkpoint; do not
promote a later checkpoint past a failed prerequisite. Map existing evidence by
revision rather than declaring checkpoints passed from historical summaries.

Independent focused scenarios and diagnostic checks may be planned under a fresh
explicit bounded $0 allocation, including automatic triggers. No execution is
allocated by this policy or the planning-only session. Focused success never
substitutes for full exact-final-published-HEAD Gate 6 SUCCESS. Preserve functional
assertions/timeouts, storage/service contracts and evidence categories. No Stage 7
work, source reset, old-lineage import or wholesale rewrite is authorized here.

## Completed sessions and documentation-only scope

The anchor's instructions-only session and the hardening session are complete.
Their zero-CI/[skip ci], hardening-only and STOP restrictions were session-specific,
not standing prohibitions on separately authorized future work. Hardening exact-HEAD
CI SUCCESS: 7c04baf2bd474df3403a0152835e70c08a27f007, run 41001050547.
Original records remain in Git history and the preserved project-state snapshot.

Owner-authorized documentation reconciliation (2026-10-29 America/Chicago): active
branch documentation only, plus prepended retirement notices on every inactive
branch, including main. This solely supersedes the prior leave-old-branches-untouched
restriction for those notices. Preserve all old content and use separate single-parent
commits with [skip ci]; accept no new gate. No merges, branch deletion, force pushes,
product/test/workflow/check changes or implementation. Publish with expected-SHA checks.
Do not delete, reset, rename or switch dirty worktrees; report obsolete entry points
as do-not-use and do not claim inaccessible clones repaired.

Session budget recorded before changes: $0; at most TWO full active-branch CI executions,
automatic triggers included; no unchanged-code reruns; 25 minutes each and 50 aggregate
runner-minutes on standard public runners. Stop on failure/exhaustion. No local product
validation. Include all active docs before validation; require exact-final-HEAD SUCCESS.
STOP after documentation reconciliation. Stage/Gate 6 remain NOT STARTED. See
[reconciliation inventory](docs/DOCUMENTATION_RECONCILIATION.md) for session evidence;
these session limits do not become a future implementation budget.

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
