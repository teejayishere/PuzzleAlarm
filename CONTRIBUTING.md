# Contributing

Fetch origin and verify the default/active branch `codex/restart-gate5-20261029-f8a41c`.
Read its remote [PROJECT_STATE](https://github.com/teejayishere/PuzzleAlarm/blob/codex/restart-gate5-20261029-f8a41c/docs/PROJECT_STATE.md)
first: it is the single current-status authority. Then read AGENTS.md and the
unchanged recursive controller/specifications in docs/MASTER_PLAN.md.
Verify repository identity, clean tree, HEAD, fixed-anchor lineage and every
post-baseline diff; stop on unexpected changes. Run the lineage check with full history.

Gates 0–5 are inherited accepted; Stage/Gate 6 are NOT STARTED. The next implementation
scope is independently rebuilding Stage 6 and stopping after Gate 6. Do not develop,
recover or promote on main or any inactive branch, or copy their later code/tests/workflows.
Historical stage records preserve evidence, not current work queues. Old failures,
budgets and completed session restrictions neither authorize nor block new work.

Before implementation, inspect actual successful CI matching the exact current HEAD.
Reuse an existing successful run when HEAD is unchanged; no unchanged-code rerun is
needed. Missing, skipped, pending, failed or blocked CI is not PASS, and an ancestor's
success cannot validate a new HEAD. Before new validation, record the checks, maximum
executions/retries and runner time in an explicit $0 budget. Include all documentation
before final CI and verify SUCCESS for the exact final published HEAD.

Keep each change within the earliest unpassed stage. Add behavioral tests when
domain implementation begins; do not replace required compiler evidence with
text matching or another language's reimplementation.

For each gate, inspect the diff, try failure cases, run focused validation and
affected regressions, then update PROJECT_STATE, TEST_MATRIX and DEVELOPMENT_LOG.
Record exact commands, revision and CI run URL when available.

Never commit secrets, Apple credentials or signing assets. No paid dependencies.
Do not publish this repository or configure external services implicitly.

Local Swift tooling can verify pure logic. iOS integration needs actual Xcode
compilation. Simulator evidence does not establish physical alarm behavior.
The documentation reconciliation session permits no local product validation or
implementation; its bounded scope is recorded in docs/DOCUMENTATION_RECONCILIATION.md.
