# Codex prompt: derive next steps for a Gate 5 based Stage 6 rebuild

In teejayishere/PuzzleAlarm, execute a planning-only pass. Read PROJECT_STATE first,
then GATE5_REBUILD_PLAN and the relevant MASTER_PLAN, architecture, test matrix,
development log, current source/tests and git status/diff. Preserve existing edits.
Do not create a branch/worktree, change product code/tests/workflows, push, run tests,
dispatch/rerun CI, contact another task or perform device actions in this pass.

Verify the proposed Gate 5 base from repository ancestry and exact historical CI
metadata without allocating jobs. The candidate base is
159b777379ad587a615df56ef24fa273aa29ffe4 / run 37236891939, attempt 1 SUCCESS;
underlying implementation 8118e44 / run 37236486724. Never substitute a different
SHA's success. Inspect the historical workflow and policy before proposing setup.

Red-team the strategy. Explicitly check policy rollback, accidental push/PR CI,
loss of uncommitted planning work, silent loss of later tests/fixes, wholesale
reintroduction of the failed input owner and unsupported root-cause claims.
Compare the preserved current tree with the proposed base, separating modified
pre-existing foundation files from added later-stage modules/tests.

Produce docs/CODEX_NEXT_STEPS.md with concrete ordered tasks, prerequisites,
deliverables, stop conditions and an authorization boundary for each phase. The
first proposed task is safe branch preparation from the verified SHA, preservation
of current edits, a current-policy/evidence overlay and guarded CI before any push.
Follow it with a Stage 6 design/test migration ledger. A proposed branch name is
not a created branch. Identify real product decisions without silently selecting
a different input interaction or requesting a vague permission to continue.

Keep the current failure authoritative: candidate 62c8953 / run 40564260790 failed
the first ordinary list input assertion; 37 native contracts passed, editor was
cancelled and downstream checks skipped. Six Stage 14 additions compiled but were
not executed. Gate 6 FAILED / HELD; Gates 7–14 INVALIDATED / HELD; last unheld gate 5.
The failed enable flow intentionally injects scheduling failure: valid input must
lead to Needs attention, then explicit product retry, rather than immediate On.

Both historical diagnostic budgets remain EXHAUSTED with zero jobs; the exception
is REVOKED. Neither branching nor relabeling a run as replacement validation renews
diagnostic authority. No new numerical allocation or policy amendment is approved.
A current assertion failure cannot be waived by the revoked exception. If runtime
investigation is required but forbidden, document BLOCKED and stop. No speculative
fix or unchanged rerun is a substitute for a defensible implementation design.

Future runtime work needs a concrete authorized scope, frozen candidate SHA, free
tools/public Apple APIs, declared absolute limits, preserved original assertions and
logs/results, and failure-stop rules. Retain the original required gates and map
all later tests to their stage dependencies; do not silently remove them. Earlier
failures trigger recursion. Stop a first rebuild milestone after Gate 6 or blocker;
later ordered replay through Gates 7–14 needs its own declared scope. No Stage 15,
main promotion, UX redesign or physical-device acceptance.

Save findings in GATE5_REBUILD_PLAN, output in CODEX_NEXT_STEPS, and a pointer near
the top of PROJECT_STATE with a planning-only DEVELOPMENT_LOG entry. State exactly
what was reviewed and which proposed actions were not executed. Stop after planning.
