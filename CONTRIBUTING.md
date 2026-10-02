# Contributing

Follow AGENTS.md and the recursive controller in docs/MASTER_PLAN.md.
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
