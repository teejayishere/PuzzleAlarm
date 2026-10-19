# Repaired single-editor diagnostic — STOP

October 18, 2026 (America/Chicago). Experiment SHA
`7bfeca92401a577f770a97bc074bf40124f1f66f`,
[run 39199089437](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39199089437),
attempt 1. Diagnostic **INCOMPLETE_CAPTURE**, Actions **FAILURE**. The one original
UI declaration passed once (230.991s); this is no gate or broad CI pass.
Gate 6 FAILED / HELD; 7–12 INVALIDATED / HELD; last unheld gate 5.

## Authorization and limits

User authorized one original declaration, at most one macOS job, one Simulator
boot, one UI invocation/execution, 30-minute cap, no retry or further sampling.
Reviewed repair publication `98b5701cfcec3a02ad0d3669464d6a9a252eaa5e` used both
[gate6-diagnostic] and [record-only]; its diagnostic and three ordinary jobs were
skipped, with no runners. The experiment commit only adds a workflow comment.
Ordinary run 39199089416 also has three skipped jobs/no runners.

The diagnostic allocated **1** macOS job, requested/completed **1** explicit boot,
made **1** UI invocation, observed **1** test start and **1** completed passed test.
A separate **1** nonexecuting build-for-testing compiled generated app/UI runner
before boot. Job 117888106800 ran 04:21:56–04:32:56 UTC (11 minutes), below the cap.
One original post-save target row tap and one distinct restored-row tap after the
original relaunch are recorded; neither is a retry. Both have successful row chains.
Zero captured failed target interactions. There are 21 tap activities / 21 syntheses
and 21 observed began/ended pairs, across two original-flow app processes.
No additional declaration, worker, retry, sampling, production change or gate replay.

## Separate validation evidence

- Source / Windows: 31 focused tooling checks PASS before publication. Entire
  original UI declaration/regression operations preserved by generator-equivalence
  checks; product/Core/native/UI files unchanged in the published source.
- Selected Xcode: 26.6 / 17F113, Swift 6.3.3, macOS 26.6.2. Advertised options,
  31 focused Python checks, actual Swift writer compilation and normal/Unicode/
  80-gesture/overflow/truncation roundtrips PASS before boot. Generated UIKit app
  and UI runner build-for-testing PASS before boot. One metadata-extraction warning
  says no AppIntents.framework dependency; full build log retained, no warning-free
  claim. The UI invocation uses test-without-building and no repetition options.
- Simulator: iPhone 17 / iOS 26.5 / arm64. Original audio/editor declaration PASS
  once; Actions fails because the decoder rejects incomplete capture.
- Physical device: NOT RUN. No audible-output or hardware conclusion.

## What the capture establishes

Test-side Home begin wall=1792384265.0304198, return=1792384265.503552;
activate begin=1792384265.5035958, return=1792384267.962964 (2.459368s).
The return is a harness-call boundary, not an independently established instant
of foreground readiness. PID 9303 records scene deactivation, inactive editor
entry, audio stop/player-stop/deactivation entry and return, background, foreground
and active callbacks. Inactive audio-stop begin/end are sequence 2097/2101;
existing session-deactivation call returns at 2100. This is an observed return
from try?, not proof that AVAudioSession deactivation succeeded or sound stopped.
Some callbacks follow the activate-return print; timestamps are preserved without
forcing them into a stronger ordering/readiness interpretation.

The post-save target is reached once: PID 9303 touch began/ended 2199/2270,
row action 2341, draft 2342, sheet binding 2343, editor appeared 2345, same alarm ID
87653D84-2839-4FD1-81A7-C991DA2B1859 and owner route revision 3. Original XCTest
row tap is t=173.55s, followed by the original preview expectations. After the
original relaunch, PID 16308 records touch 16/87, action 158, draft 159, binding
160 and editor 162 for the same saved ID (route 2). Owner persistence is supported
by original relaunch assertions; no separate save-owner command-entry trace is
claimed. These are successful positive observations, not a reproduced failure.

## Integrity and completeness are independent

Independent Windows redecoding from original ZIP bytes finds two unique raw files:
PID 9303: 2,586 committed; PID 16308: 455 committed. Both have matching attempted/
committed counts, valid checksums/sequences/commits/process identity/attachment,
zero overflow and zero string truncation. Fallback copies are byte-identical
duplicates, not extra app processes. All 622 announced gesture lists / 1,604
indexed entries validate, maximum 30 gestures per list, zero gesture omissions.

**Completeness FAILS:** PID 9303 contains two explicit `capture limited ancestors`
markers (2182 around Save and 2570 around Cancel). The retained depth-24 bound
therefore demonstrably omits ancestor-path information. PID 16308 alone passes
the decoder; that cannot make the entire capture complete. The runner's combined
raw_integrity_valid=false includes this semantic completeness rejection; it is
not evidence of corrupt bytes. Exhaustive process coverage remains unproven.

**No exported native video is available.** The attachment exporter explicitly
reports no matching attachments and its manifest is empty; the artifact has no
standalone video file. Both complete xcresult directories are preserved in the ZIP,
but no separately usable video observation can be reviewed. We do not assert why
Xcode retained no exported attachment or infer screen continuity from test success.
The requested video evidence is missing. No rerun to obtain it is authorized.

No conclusion about the historical activation timeout, saved-row failure or switch
miss follows from this successful sample. App/harness/instrumentation/platform
causation and the historical video gap remain unresolved. Missing evidence is
complete ancestor paths/process coverage, usable video, and the relevant failure's
correlated input/lifecycle/audio/harness boundary records. STOP: no tooling repair
and rerun, product remedy, main promotion, downstream replay, redesign or Stage 13.

## Preserved evidence

`artifact.zip` is the complete original GitHub artifact 12163527135 (3,314,989 bytes),
including raw buffers, both xcresults, generated instrumentation patch/source,
self-test buffers, build/activity logs, test results and empty attachment manifest.
Its SHA-256 is `95379afc4a349c30f186ccc9af3f12964a0008d9100c6607e76200f3c5b97b11`,
independently matched to GitHub's artifact digest. Original ZIP/manifests untouched.
`job.log` is the full decoded Actions job log; `inventory.json` lists every ZIP entry.
`independent-integrity.json` and `independent-timelines.json` are fresh Windows
decodes; `correlated-boundaries.json` retains selected exact records.
`reviewed-summary.json` separates allocation, invocation, execution, interactions,
byte integrity and capture completeness. API run/jobs/artifact metadata prove
attempt, exact SHA and skipped-job accounting. Copied top-level logs are for
inspection; authoritative original bytes remain in artifact.zip.
