# Buffered passive capture — stopped on tooling invocation failure

Source: `4b0e1c126bec45723e30481cd6eab59a40fe2fa9`, based on verified
`420a52ef46722dcd9fcea0e5b20beac018cc3894` on `codex/stage-12-routing`.
[Run 39079559751](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39079559751),
attempt 1, one Simulator job, FAILED. The three ordinary CI jobs were SKIPPED.

Actual Swift mmap writer/decoder self-tests passed before Simulator boot, including
Unicode, overflow and truncation. Six decoder tests passed. The generated patch
removes callback-time file journals, added XCTest snapshots and ineffective tracking
overrides; retains passive attachment/touch and control/action/binding/owner/draft/
presentation records. Original readiness/selectors/single taps/assertions remain,
with bounded post-tap editor presentation assertion. Nonzero overhead remains.

**No UI declaration executed.** The first xcodebuild invocation exited 64:
`Must specify -test-iterations with more than 1 iteration.` The agent supplied
unsupported `-test-iterations 1`. This is a tooling invocation failure, not an
observed switch failure. Editor/audio was not attempted. No retry or second job.
The stop rule was applied; no repair-and-repeat was performed.

Xcode 26.6 / 17F113; Swift 6.3.3; macOS 26.6.2 / 25G83, arm64;
selected iPhone 17 / iOS 26.5. Stopped 23:37:44 UTC, job completed 23:38:01 UTC,
well before minute 25 and the absolute thirty-minute cap measured from 23:29:33 UTC.

`artifact.zip` is the complete original CI export: generated patch and Swift probe/
recorder, exact SHA, runtime/device inventory, toolchain, self-test raw records and
logs, invocation log, original manifest, empty product timeline/integrity arrays,
and complete invocation-created toggle.xcresult with no test nodes. No editor
xcresult or product process records were generated. The full Actions log is separate.
No DerivedData activity logs existed because xcodebuild rejected its arguments.

The original runner manifest misleadingly labels the invocation RELEVANT_FAILURE
and executions=1. Preserve it as emitted; reviewed-outcome-manifest.json explicitly
corrects classification and actual test executions to zero. Self-test decoded records
are synthetic validation evidence, not product-input evidence. No product attachment
or integrity counters exist; absent counters are not evidence of zero loss.

[Artifact 12118591759](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39079559751/artifacts/12118591759),
expires 2026-10-24 23:37:49 UTC. Independently verified archive SHA-256:
`251d5f3d250070ecee7e9d4a0d3f227b45b98b585b8f2ab21818b02060cd6fb1`.
The full archive is also retained here to survive artifact expiry.

Both historical failures remain unresolved. No negative conclusion is permitted.
Gates 6–12 remain HELD, last unheld gate 5, Stage 13 NOT STARTED. No production
remedy, main promotion, downstream replay or redesign. Experiment STOPPED.
