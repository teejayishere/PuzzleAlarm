# Gate 6 recovery plan after Stage 14 recurrence

Updated starting-point decision: the owner's later request selected a Gate 5 branch
strategy for planning. [GATE5_REBUILD_PLAN.md](GATE5_REBUILD_PLAN.md) and
[CODEX_NEXT_STEPS.md](CODEX_NEXT_STEPS.md) now control the proposed next task.
The evidence, held gates and exhausted-budget restrictions below remain in force.
No rebuild, branch creation or runtime work was executed by that planning request.

Recorded October 27, 2026. This is a planning and existing-evidence review, not
authorization for implementation, diagnostic jobs, validation replay or device work.

## Current state to remember

- Working branch: `codex/stage-14-resilience`; reviewed publication HEAD:
  `cfb37a86e63049f2f1326b8187f7d7fdf2d93ba2`.
- Accepted historical source: `f01abf42c7b4e7a7ed10bb926bb736ebaa8e77bc`,
  run 40521565094, attempt 1 SUCCESS within its automated/Simulator scope.
- Failed candidate: `62c8953fdcd915ebdac8cb5838799e0b2f64389e`,
  run 40564260790, attempt 1 FAILURE. The publication is a separate record-only
  descendant; skipped publication CI is not product acceptance.
- Gate 6 FAILED / HELD; Gates 7–14 INVALIDATED / HELD; last unheld gate 5.
  Stage 14 BLOCKED / NOT ACCEPTED. Six Stage 14 additions compiled but did not run.
- Both historical switch/editor diagnostic budgets EXHAUSTED, zero jobs.
  Historical-risk exception REVOKED. No new allocation or implicit budget reset.
- Preserve this branch/history, original tests, six additions and all evidence.
  Main stays unpromoted. Stage 15, UX redesign and physical-device acceptance
  are outside this plan. Device behavior remains DEVICE REQUIRED / NOT RUN.

## Red-team findings

| Weakness in “go back and restart Gate 6” | Correction |
| --- | --- |
| Sounds like rerunning from the first red test could clear the hold. | A new green sample cannot explain or erase the observed failure. Start with existing evidence, not another run. |
| “Separately authorized recovery scope” could imply diagnostic allocations can be replenished. | Scope authorization does not override the lifetime cap. No branch, renamed issue, new session, replacement or fresh hypothesis resets it. Any proposed policy change must be explicit and separately reviewed by the owner; it is not granted here. |
| The old historical-risk exception might look like an available shortcut. | It is revoked, and its rules cannot waive a current assertion failure or a critical invariant. Do not propose simply invoking it again. |
| Another speculative control rewrite could repeat the same cycle. | The controlled replacement already passed and then failed again. No source change or replacement is justified by that sequence alone. A replacement would require a concrete design and explicit product scope, rather than being called a diagnosis. |
| Native unit success could be mistaken for UI-input reliability. | The 37 contracts passed, but they do not prove native event delivery. The original UI failure remains binding. |
| Cancellation could be interpreted as an editor failure or pass. | The independent editor is CANCELLED / INCOMPLETE. Preserve its partial evidence; do not assign a behavioral conclusion. |
| Retrying all downstream work before resolving Gate 6 wastes allocations and risks misleading evidence. | Keep dependents held. Only after legitimate prerequisite clearance may the authorized ordered replay proceed. |

## Existing-evidence pass executed for this plan

Read PROJECT_STATE first, current development log, relevant MASTER_PLAN budget/
invalidation rules, the controlled replacement decision, Stage 14 archive and current
input owner/helper/source. Verified a clean worktree at the reviewed HEAD before
these planning edits. Compared accepted `f01abf42` with failed `62c8953`: no changes
in `PuzzleAlarm`, `PuzzleAlarmCore` or `PuzzleAlarmUITests`. This narrows the source
change set; it does not prove an environmental cause or exclude timing effects.

The [original failed command output](evidence/stage14-40564260790/list/acceptance-steps/ten-unchanged-ordinary-list-flows.log)
records one tap of the concrete `0` switch, followed by the unchanged helper's
timeout at `AlarmManagementUITests.swift:181`. The failure hierarchy shows inner
and outer switch values `0`, with row status `Off`.

This is the first action of `testEnableDisableAndFailureRetryAreHonest`, whose
`enableFailure` fixture intentionally makes scheduling fail after a valid enable
request. The next expected row status is `Needs attention`, followed by the existing
explicit product retry. It is not a test that should bypass the injected scheduling
failure and immediately claim healthy `On`.

The ordinary journal contains a launch entry, without recorded binding/owner
entries. Current `AlarmEnabledInput.binding` has guards before the downstream
binding trace, and the trace writer is conditional and uses best-effort file I/O.
Consequently missing entries do not prove that the native callback never arrived,
identify a guard outcome, or locate an OS/harness/product defect. The source review
and archived trace do not establish a deterministic root cause or a defensible fix.

**Planning result: no proven cause found; Gate 6 remains held.** No product source,
test assertion or workflow was changed; no test, diagnostic, CI or device action
was run for this planning pass.

## Ordered next steps

1. On resumption, read PROJECT_STATE and this plan, verify branch/HEAD/worktree and
   latest relevant revision-specific evidence. Do not discard local work or reset
   to main. Keep the current failure and original accepted run distinct.
2. Continue only read-only analysis of already captured artifacts and source if a
   specific unresolved question can be answered from them. State that question and
   the observation that would answer it before reviewing more material. Do not
   repeatedly inspect the same evidence without a new discriminating question.
3. If that evidence proves a defect, record the causal chain, earliest affected
   gate and smallest proposed correction with exact file references. Check whether
   the change and validation are authorized before implementation. A source-level
   finding must not be promoted to runtime proof.
4. If evidence remains insufficient, stop with that finding. Prepare a concrete
   owner decision only if needed: a scoped replacement with a reviewed behavioral
   contract, or an explicit proposed policy change if runtime investigation is
   indispensable. Neither is automatically approved by this plan. A generic
   “continue” must not silently become budget renewal, risk acceptance or redesign.
5. Before any separately authorized runtime work, declare the exact scope,
   allowable allocations, free runner type, absolute deadlines, required original
   declarations, preservation and failure-stop rules. Respect all still-applicable
   caps. Guard preparation/record-only pushes against accidental runner allocation.
   Freeze the exact candidate SHA before the single authorized validation push.
6. Gate 6 must satisfy its original native owner/input, ten ordinary list flows,
   independent editor and full management obligations without extra taps, weakened
   assertions, diagnostic waits, selective omissions or retry-to-green. A failure
   stops progression and preserves original evidence; an unexplained recurrence
   cannot consume another exhausted diagnostic allocation.
7. Only after legitimate Gate 6 clearance, and within the separately authorized
   scope, replay affected Gates 7–13 in dependency order, then Gate 14 and required
   full regressions/build/resource checks at the exact candidate revision. Any
   earlier newly demonstrated defect reopens its earliest gate and dependents.
   Preserve original A–J and all six Stage 14 additions. Stop after Gate 14 PASS or
   a documented blocker; no Stage 15 or main promotion.

## Reusable prompt and next decision

Use [the recovery planning prompt](prompts/GATE6_RECOVERY_PLANNING.md) to reproduce
the evidence-first pass. Its planning instructions were applied in this task;
the result is recorded above. It authorizes no runtime work by itself.

The current next state is **awaiting a concrete, separately authorized recovery
decision if existing evidence cannot establish a correction**. No new product
design, policy change, risk waiver, job budget or execution scope has been selected.
This plan is durable repository memory; resume from PROJECT_STATE, not from an
assumed successful Gate 6 rerun.
