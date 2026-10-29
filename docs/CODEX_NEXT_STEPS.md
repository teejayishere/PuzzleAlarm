# Codex next steps — Gate 5 based recovery

Generated October 27, 2026 by applying
[the next-step planning prompt](prompts/GATE5_REBUILD_NEXT_STEPS.md).
Authority and red-team findings: [GATE5_REBUILD_PLAN.md](GATE5_REBUILD_PLAN.md).
This file is a handoff plan, not execution authorization.

For the next task, submit [the copy-ready branch-preparation prompt](prompts/GATE5_PREPARE_BRANCH.md).
It authorizes the preparation milestone only when used as the next task instruction;
it was saved, not executed, in this planning task.

## 1. Safe preparation milestone

**Proposed next Codex task:** prepare an isolated Gate 5 recovery branch and a
reviewable Stage 6 design; stop before product implementation or runtime validation.
When that concrete task is authorized:

1. Read PROJECT_STATE first and verify current branch/HEAD/status. Current reviewed
   publication is `cfb37a8` on `codex/stage-14-resilience`; planning files are local
   edits. Preserve them explicitly before any checkout. Do not reset or clean.
2. Reverify `159b777379ad587a615df56ef24fa273aa29ffe4`, its exact run
   [37236891939](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939),
   and lineage. Historical run SUCCESS is established; new checks have not run.
3. Create proposed `codex/gate5-stage6-rebuild` in a separate worktree from that
   exact base. If the name already exists, inspect rather than overwrite it.
   Retain the current checkout and all later source/tests/evidence. Record both paths.
4. Add a documentation overlay preserving current failures, budget accounting,
   revoked exception, scope boundaries and references to `cfb37a8`/planning records.
   Do not replace the historical failure evidence with old Gate 5 status text.
5. Inspect every workflow before pushing. The Gate 5 workflow has an unconditional
   public-repository push job; `[record-only]` alone does nothing there. Add and
   statically verify preparation skips and explicit branch/event/validation-marker
   guards. Do not dispatch, open a PR or push until zero-job preparation is assured.

Deliverables: exact base/branch/path manifest, preserved planning work, current-policy
overlay and reviewable CI-guard diff. No product code, test execution or paid tools.
Stop for ambiguous ancestry, unpreserved edits or triggers that could allocate jobs.

## 2. Stage 6 design and preservation ledger

Prepare a reviewable design before implementation, including:

- Stage 6 responsibilities only: management list/editor, CRUD, enable/disable,
  weekdays, modes, challenge configuration/order and sound selection shell.
- One authoritative store using Gate 5 lifecycle/persistence APIs; views do not
  perform AlarmKit business logic. Core stays free of platform/UI frameworks.
- The input/owner lifecycle, retained reads, busy/pending behavior, error recovery,
  removal and identity semantics. Explain the concrete difference from the failed
  controlled replacement without asserting that its root cause is known.
- A ledger for existing native contracts, all eleven management declarations,
  ten ordinary list executions and independent editor coverage. Preserve original
  assertions and one-action behavior. Map later engine/routing/audio/orchestration/
  resilience tests to their real stage dependencies; preserve their reference source
  rather than silently removing them or counting them as passed.
- A prerequisite comparison. Current inspection found no later logic change to
  pre-existing Core lifecycle/persistence files or existing Core tests; Models.swift
  differs only in a comment. Added Stage 7–12 modules are later work, not Gate 5 fixes.
  Recheck this finding against the actual chosen revisions before relying on it.

Deliverables: design, file-level scope and test migration ledger with acceptance
observations and no source rewrite. If a changed user-facing control/interaction is
needed, present that specific product decision. No such change is selected here.
If no defensible implementation difference can be articulated, report BLOCKED.

## 3. Implementation and validation boundary

Implementation and runtime work require their concrete scope to be authorized.
No fresh numerical allocation is approved. Historical diagnostic budgets remain
exhausted; the revoked exception cannot waive the current failure. Do not rename
unchanged diagnostic sampling as a new replacement-validation task.

Before execution, record the exact original declarations, free runner type/counts,
absolute job/test deadlines, freeze procedure, preservation, failure/cancellation
and closeout rules. Keep preparation/record-only pushes job-free. Only then implement
the scoped Stage 6 design and use the authorized checks. Changed SDK usage requires
installed public declarations and a compiled spike; old API assumptions are not proof.

Replay any affected earlier gates before Gate 6. Gate 6 must retain native contracts,
ten ordinary list executions, independent editor, complete management coverage,
persistence/accessibility behavior and required full regressions/build checks.
Freeze exact candidate HEAD; record source/local/Xcode/Simulator/device evidence
separately. No extra taps, weakened checks, selective omissions or retry-to-green.

Stop on a required failure, preserving originals and invalidating from the earliest
affected gate. An unexplained recurrence cannot consume another exhausted diagnostic
allocation. Gate 6 PASS ends the first rebuild milestone; it does not accept Stage 14.

## 4. Later milestones, only after legitimate Gate 6 clearance

Restore Stage/Gate 7, then 8, 9, 10, 11, 12 and 13 in dependency order with their
preserved implementation/test contracts and authorized exact-candidate evidence.
Then restore Gate 14, including all six added resilience tests and required full
regressions. Stage 13 A–J remain mandatory. A failure reopens the earliest affected
gate and dependents. Do not mark an absent later-stage test passed on a smaller base.

Stop after Gate 14 PASS or a documented blocker. No Stage 15, main promotion, release,
UX redesign or physical-device acceptance. Device behavior remains NOT RUN.

## Status at handoff

Planning completed; historical base and run/job metadata verified read-only.
No new branch/worktree, source/test/workflow changes, push, tests or CI allocation
occurred. Gate 6 remains FAILED / HELD; Gates 7–14 INVALIDATED / HELD, last unheld
gate 5. The immediate next proposed task is milestone 1 plus milestone 2 preparation,
not an automatic rebuild or test rerun. Existing local planning edits must be kept.
