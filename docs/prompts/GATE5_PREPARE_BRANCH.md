# Next task prompt: prepare the Gate 5 recovery branch

Prepare the Gate 5 based Stage 6 recovery in teejayishere/PuzzleAlarm. This task
authorizes safe branch/worktree preparation, documentation/CI guard changes and a
concrete design/test migration ledger only. Stop before product implementation,
test execution, diagnostic capture, CI allocation or device work. Do not push or
open a PR in this preparation task. Do not change main.

Read docs/PROJECT_STATE.md first, then docs/GATE5_REBUILD_PLAN.md,
docs/CODEX_NEXT_STEPS.md, applicable AGENTS.md and relevant MASTER_PLAN sections.
Inspect git status/diff and preserve every existing local planning edit. Do not
reset, clean, overwrite, silently stash or discard work. Save the approved planning
records on the existing branch using a record-only documentation commit if needed;
do not push it. Record its exact SHA so the recovery checkout can reference it.

Verify the historical Gate 5 base
159b777379ad587a615df56ef24fa273aa29ffe4 and exact historical run 37236891939,
attempt 1 SUCCESS, without starting jobs. Create a separate worktree and proposed
branch codex/gate5-stage6-rebuild from that exact revision. If the branch exists,
inspect it and reuse only if appropriate; never overwrite an unrelated branch.
Preserve codex/stage-14-resilience, its six resilience additions and all history.

The historical base has older policy and unconditional public push CI. Before any
future push, prepare a current-policy/evidence overlay and verify explicit
branch/event/marker guards for every workflow. Preserve required checks; do not
disable them to claim a pass. Preparation and record-only publication must allocate
zero runners. No push/dispatch/PR is allowed in this task even after guards are edited.

Keep the current facts authoritative: candidate 62c8953/run 40564260790 failed the
first original list switch-input assertion; native contracts passed, editor was
cancelled, downstream checks skipped. Gate 6 FAILED / HELD; Gates 7–14 INVALIDATED /
HELD; last unheld gate 5. Both historical diagnostic budgets remain EXHAUSTED,
zero jobs, and the exception remains REVOKED. Branching cannot renew them.

Produce a Stage 6 design and test migration ledger before touching product code.
Explain the proposed input/store ownership, persistence/lifecycle authority,
single-action state/error/pending outcomes and its concrete difference from the
failed controlled replacement. Do not claim an unknown historical cause is solved.
Preserve original assertions and map all later tests to their real stage
dependencies. The injected scheduling-failure flow expects Needs attention after
valid enable input, then explicit product retry. No alternate user-facing control
or UX redesign is selected by this prompt; identify any real product decision.

Deliver exact branch/base/worktree/record SHAs, documentation/guard diffs, the
design/test ledger, a proposed validation scope with explicit limits and unresolved
decisions. Proposed limits are not approved allocations. If a defensible design
requires unavailable runtime evidence, document BLOCKED. No speculative product
fixes, new diagnostic jobs, runtime tests, retries or risk waiver. Stop at this
reviewable preparation result. Do not advance to Stage 7, Stage 14 execution,
Stage 15, promotion or physical-device acceptance.
