# Corrected bounded experiment — STOP on toolchain preflight

Source `6ba4de1dbadff8c1233fed0488a99d1fbe57c335`, branch
`codex/stage-12-routing`, based on `9f7e286fa6215b927d60fed5dc690cf2c6d7a77d`.
[Run 39080779760](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39080779760),
attempt 1, job 117537091080 FAILED. One macOS Simulator-designated job allocated;
zero Simulator boots, zero xcodebuild UI invocations, zero switch executions and
zero editor/audio executions. No automatic retry, rerun or repair-and-repeat.
Ordinary CI run 39080779757 has all three jobs SKIPPED; no downstream replay.

The unsupported `-test-iterations 1` was removed without increasing iterations.
The new selected-toolchain check stopped before project generation/instrumentation
or Simulator allocation: `AssertionError: Selected Xcode does not advertise -dry-run`.
The agent introduced that unsupported preflight assumption. No dry-run command or
UI test command was actually invoked. Do not classify this as a product failure.
The exact supported final invocation remains unvalidated; runner changes are not
accepted tooling merely because local accounting tests pass. No repair was made
after this stop, and no further experiment is queued.

Xcode 26.6 / 17F113, Swift 6.3.3, macOS 26.6.2 / 25G83, arm64.
No Simulator/runtime selected. Budget began 23:54:29 UTC October 17, 2026;
preflight failed 23:54:36.940 UTC, cleanup finished 23:54:38.687 UTC.
Test cutoff 00:19:14 UTC October 18; absolute cap 00:24:29 UTC.
The job ended within ten seconds of its explicit budget start.

`artifact.zip` is the complete original four-file CI artifact: exact-sha.txt,
toolchain.txt, xcodebuild-help.txt and outcome-manifest.json. The manifest correctly
records TOOLING_FAILURE, actual_test_executions=0, xcodebuild_ui_invocations=0,
complete_capture=false and negative_conclusion_allowed=false. Full Actions job
log is preserved separately. The extracted help/toolchain/manifest are included
for direct inspection. The source revision preserves unchanged buffered
instrumentation and all original readiness checks/selectors/single taps/assertions.
No ephemeral instrumentation patch was generated because that step was skipped.

No xcresults, build/test activity logs, raw product records, decoded product traces,
attachment records or integrity counters were generated. These are absent, not
zero-loss evidence. Product capture is incomplete/absent. There are zero captured
product failures and zero successful samples. No negative product conclusion.
The Mac recorder/decoder/accounting validation commands were also skipped after
the help assertion; historical Swift validation is separate. Windows local
validation: seven accounting tests and six existing decoder tests passed.

[Artifact 12117729955](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39080779760/artifacts/12117729955)
expires October 24, 2026 at 23:54:37 UTC. Independently verified ZIP SHA-256:
`8b5850868553539dd2d85c1f0963290eb6941535f1c39a1d9501d8033612fc9b`.
Original bytes are archived here to survive artifact expiry.

Both historical input failures remain unresolved. Gate 6 FAILED, Gates 7–12
INVALIDATED / HELD, last unheld gate 5; Stage 13 NOT STARTED. No production remedy,
main promotion, downstream replay or redesign. STOP.
