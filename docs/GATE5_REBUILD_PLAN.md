# Gate 5 branch strategy: red-team review and saved plan

October 27, 2026. The owner selected a Gate 5 branch strategy for planning and asked
for red-team review, a saved plan and prompt-generated Codex next steps. This task
does not create the branch, rebuild source, push, allocate CI or authorize device work.
It supersedes the choice of starting point in GATE6_RECOVERY_PLAN; that document's
failure evidence and budget restrictions remain applicable.

## Verified starting point

Use **`159b777379ad587a615df56ef24fa273aa29ffe4`** as the proposed Gate 5 branch
base, rather than guessing a tag or using main. GitHub read-only verification in
this task confirmed its [exact-HEAD run 37236891939](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236891939),
attempt 1, push, completed SUCCESS. Job `111537697876` and every required assigned
step passed. It is an ancestor of current publication `cfb37a8`.

Its underlying implementation is `8118e44dc007143813edf668cca223459cd97b88`,
[run 37236486724](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236486724),
attempt 1 SUCCESS. The change from that implementation to `159b777` is four
documentation files only. Historical Gate 5 records report 123 Core tests,
10 native tests and one shell UI test; the run/job metadata verification here
does not claim to have re-executed or re-exported those test counts.

Inspection of the Gate 5 tree confirms it has the native shell, lifecycle,
persistence and scheduling foundation, without the Stage 6 management implementation.
Compared with `cfb37a8`, the only changed pre-existing Core production file is
Models.swift, with a sound-selection comment change. Other Core source/test deltas
are added Stage 7–12 modules/tests. No existing Core lifecycle/persistence source
or pre-existing Core test file changed in that comparison. This supports the chosen
boundary; it does not establish current runtime compatibility or input reliability.

## Red-team verdict

**A Gate 5 branch is a defensible isolation boundary, not evidence that starting
there fixes the failure.** The previous controlled input replacement passed and
later failed again. Another native-control rewrite without a concrete design
rationale risks repeating that cycle.

| Risk | Required safeguard |
| --- | --- |
| Checking out Gate 5 also restores older, looser debugging policy. | Carry current gate holds, exhausted lifetime budgets, revoked exception, stop rules and evidence references into the recovery branch before any development or execution. Historical policy is not renewed authority. |
| Gate 5's workflow runs on every push and has no record-only guard. | Patch and verify runner guards locally before the first push. A record-only commit message alone cannot suppress that historical workflow. Do not push a bare Gate 5 branch or open a PR first. Review all push/PR/dispatch triggers. |
| Current planning edits are uncommitted. | Preserve them on the current branch before any checkout. Prefer a separate worktree when branch preparation is authorized, so the existing checkout remains intact. Do not stash/reset/discard the plan as an incidental setup step. |
| Returning to Gate 5 can hide later fixes, tests and operational knowledge. | Maintain a test/feature migration ledger against preserved `cfb37a8` and the planning files. Keep all original later source and evidence on the existing branch. Never call tests absent from the Gate 5 tree passed or obsolete. |
| Copying today's whole store or cherry-picking all later commits recreates the disputed boundary. | Review Stage 6 responsibilities individually. Use the Gate 5 coordinator as authority; do not import Stage 7–14 implementation as an unexplained bundle. |
| Removing later tests makes regression coverage appear smaller but green. | Map each existing obligation to Stage 6 now or its real later-stage dependency. Preserve original assertions; document any justified implementation-specific adaptation and behavioral equivalence. Missing dependencies are not permission to weaken or silently omit a test. |
| A new branch or replacement is described as a new issue to obtain diagnostics. | No lifetime budget reset. A genuinely authorized implementation-validation scope is distinct from a diagnostic replay; relabeling unchanged sampling is prohibited. If required investigation is disallowed, remain BLOCKED. |
| A historical green base is treated as current exact-HEAD acceptance. | Gate 5's run validates that historical SHA only. Changes require their own authorized prerequisite checks; SDK drift or a new earlier failure triggers recursion. |
| A candidate receives Gate 6 PASS and is assumed ready for Stage 14. | Keep later gates held until their dependent implementation and ordered checks are restored. Stop the first recovery milestone at Gate 6; later replay needs its declared scope. |

## Plan to retain

1. Preserve the current Stage 14 branch, six additions, original assertions and
   immutable accepted/failed evidence. Save the planning documents before switching
   any checkout. Main is not a starting point or promotion target.
2. In a separately authorized preparation task, create proposed branch
   `codex/gate5-stage6-rebuild` from exact `159b777379ad587a615df56ef24fa273aa29ffe4`.
   The name is proposed, not created or reserved. Prefer a separate worktree;
   verify paths, parent SHA and ancestor relationship. No history rewrite or force push.
3. Before any push, commit only the recovery-policy/evidence overlay and verified
   CI guards. Preserve current lifetime accounting and failures rather than copying
   historical PASS/STOP text as current status. Preparation must allocate zero jobs.
4. Produce a concrete Stage 6 design and migration ledger before implementation.
   The default behavioral contract is the existing alarm-management feature set,
   one-action input, exact value/status/error/pending state, persistence after
   save/reopen/relaunch and retained-owner correctness. Standard controls are a
   preference, not a demonstrated fix. Any changed user interaction needs a clear
   product decision; no redesign is selected by this plan.
5. Identify how the proposed implementation differs from the failed controlled
   replacement, what invariant that difference protects and what meaningful test
   distinguishes them. Do not claim a historical cause without evidence. If no
   defensible design difference exists, report the blocker before rewriting code.
6. Agree the actual implementation and validation scope before runtime work.
   Specify free runner types, job counts, absolute deadlines, exact required
   declarations, original-result preservation and failure stops. Do not borrow
   consumed allocations, infer approval of a policy amendment or invoke the revoked
   exception. No numerical new allocation is granted in this planning task.
7. Rebuild Stage 6 only within that concrete authorized scope. Reuse the Gate 5
   domain/lifecycle/persistence authorities. Preserve free/public API and Core
   dependency boundaries. Inspect the installed SDK and compile a spike before any
   changed AlarmKit API use; never infer signatures from historical source alone.
8. Freeze one candidate for its authorized checks. Replay affected earlier gates
   first, then Gate 6's original contracts, ten ordinary list flows, independent
   editor, management UI and required regressions/build/resource checks. No extra
   taps, relaxed assertions, failed-test reruns, retry-to-green or missing required
   declarations. The injected scheduling-failure flow expects Needs attention
   after the first valid enable input, then explicit product retry.
9. On failure, preserve original evidence, reopen the earliest gate and invalidate
   dependents. An unexplained input recurrence does not renew diagnostics. On Gate 6
   success, report exact SHA/run and stop this milestone. Only a later declared
   scope restores Stages/Gates 7–13 in dependency order and then Gate 14/full required
   regression. No Stage 15, main promotion, UX redesign or device acceptance.

## Prompt execution and result

Applied [the Codex next-step planning prompt](prompts/GATE5_REBUILD_NEXT_STEPS.md)
as a source/history/metadata planning pass in this task. Output is saved separately
in [CODEX_NEXT_STEPS.md](CODEX_NEXT_STEPS.md). No subagent, separate task, runtime
test, branch creation, source change, CI allocation or device action occurred.
The output also links a [copy-ready preparation task](prompts/GATE5_PREPARE_BRANCH.md),
saved for the next Codex instruction and not executed here.

Current state is unchanged: Gate 6 FAILED / HELD, Gates 7–14 INVALIDATED / HELD,
last unheld gate 5; diagnostic budgets EXHAUSTED, exception REVOKED. Historical
Gate 5 metadata was read over the network; no CI was started. The immediate next
Codex milestone is safe branch/policy/CI preparation and a concrete Stage 6 design,
not an automatic rebuild or another test run.
