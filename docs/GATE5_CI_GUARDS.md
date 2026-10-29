# CI safeguards — sealed preparation

Source review October 28, 2026. Every workflow in the exact Gate 5 tree was
inspected: ios.yml (validate; push, pull_request, workflow_dispatch) and
sdk-evidence.yml (inspect; workflow_dispatch). No new workflow is introduced.

Both jobs now require literal false AND explicit repository/public/branch/event/
first-attempt/validation-marker conditions; negative record-only/preparation/
diagnostic markers also appear. SDK dispatch uses explicit scope and record_only
inputs, with record-only defaults. The false latch dominates every condition.

| Event on recovery tree | Marker/input | validate | inspect |
| --- | --- | --- | --- |
| Push preparation/record-only | any, including validation marker | no runner | not triggered |
| Push ordinary change | none | no runner | not triggered |
| Push candidate | gate5-stage6-validation | no runner: sealed | not triggered |
| Pull request, any base/head | any | no runner: event excluded and sealed | not triggered |
| Dispatch ios.yml | any | no runner: event excluded and sealed | not triggered |
| Dispatch SDK workflow | default record-only | not applicable | no runner |
| Dispatch SDK workflow | SDK scope, record_only false | not applicable | no runner: sealed |
| Other branch/private/fork repository/rerun | any | no runner | no runner |

This is a manual expression/trigger review, not an executed workflow test or CI
PASS. No preflight job is used because even a preflight allocates a runner.
All original checkout/actions, required build/test steps, runner labels and job
timeouts remain unchanged below the job guard. Their retained 25/5-minute
historical ceilings are NOT a new validation allowance and are not yet a
sufficient Stage 6 validation plan.

The sealed workflows deliberately cannot provide Gate 6 acceptance. Before any
future runtime authorization, review a concrete diff that replaces the latch,
pins the frozen candidate, implements approved absolute deadlines/preservation/
fail-stop accounting, adds all ledger requirements and partitions the authorized
jobs. A commit marker alone is not owner authorization. Preserve required check
names and all original checks; a skipped required check is unvalidated, never a
pass. Branch protection was not changed.

A future PR can also activate workflows from its target/default branch; these
local guards make no claim to govern that other revision. No push, PR or dispatch
is allowed in this task. Review remote/default-tree triggers separately before any
future publication, including publication of the preserved Stage 14 branch.
