# Gate 6 bounded input investigation — October 17, 2026

October 18 (America/Chicago): authorized experiment source
`7bfeca92401a577f770a97bc074bf40124f1f66f` /
[run 39199089437](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39199089437),
attempt 1: **INCOMPLETE_CAPTURE / Actions FAILURE**. The one original audio/editor
declaration executed once and passed (230.991s). No retry or further experiment.

Accounting: 1 allocated macOS job, 1 explicit boot requested/completed, 1 UI
invocation, 1 actual execution/completed passed case; separate preboot compile
invocation executed no test. One post-save target row tap plus the original
post-relaunch restored-row tap, each with touch/action/draft/sheet/editor records;
0 captured failed target interactions. Job duration 11 minutes under 30-minute cap.
Repair publication and ordinary workflow jobs all skipped with no runners.

Source / Windows: 31 focused checks PASS; original product/Core/native/UI sources
and one-tap assertions preserved. Selected Xcode 26.6: option checks, 31 tooling
checks, actual Swift writer/decoder roundtrips and generated app/UI-runner compilation
PASS before boot. Simulator iPhone 17 / iOS 26.5: original declaration PASS once.
Physical device NOT RUN. This is no gate or broad CI pass.

Two unique raw PIDs contain 2,586 + 455 committed records, valid byte structure/
checksums/sequences and zero overflow/truncation. All 622 counted gesture lists
validate, zero gesture omission markers. **Capture incomplete:** first PID has
2 ancestor-depth omission markers; exported attachment manifest empty and no usable
exported video. Fallback raw copies are identical duplicates. Complete original ZIP,
both xcresults, raw buffers and full Actions log are
[durably archived](evidence/gate6-repaired-single-editor-39199089437/README.md),
with independent integrity and correlation review. ZIP digest matches GitHub.

Home/activation and audio-stop return boundaries are observed in this successful
sample, followed by successful saved-row chains. This establishes no historical
cause or remedy. Both historical input/editor failures and prior activation failure
remain unresolved. Gate 6 FAILED / HELD; Gates 7–12 INVALIDATED / HELD; last
unheld gate 5. STOP after evidence-only closeout: no repair/rerun, production remedy,
main promotion, gate replay, redesign or Stage 13. No further execution queued.

Earlier offline work: [October 18 offline repair/review](GATE6_OFFLINE_REPAIR_2026-10-18.md).
31 Windows tooling checks pass; no new CI/Simulator/device run. Full gesture-list
capture remains bounded with strict count/index/loss validation; original archive
still incomplete. Lifecycle/audio boundary instrumentation is source-checked only.
Activation cause remains undetermined, including a native-video PTS gap across the
boundary. The exact one-execution/30-minute proposal there supersedes historical
batch proposals below; it is prepared only, **not authorized or queued**. STOP.

Latest authorized one-editor diagnostic: source 6966ab5 /
[39185410894](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39185410894)
attempt 1 TOOLING_FAILURE. Preflight passed; one boot, invocation and actual execution.
Activation timed out after Home before Save/target row tap. Gesture omissions also
invalidate complete capture. Zero captured failing target interactions; no cause
established. [Original artifacts and counts](evidence/gate6-single-editor-39185410894/README.md).
No repair or rerun. Gate 6 failed/held, 7–12 invalidated/held. STOP.

October 18 update: [evidence review and local tooling correction](GATE6_REVIEW_2026-10-18.md)
supersedes the historical dry-run requirement and automatic product-failure attribution
below. No new experiment is authorized or executed. Help inspection is option-name
evidence only; exact invocation remains unvalidated. Raw decoder integrity does not
establish complete process coverage. Gate 6 held; Gates 7–12 invalidated/held.

Gates 6–12 remain HELD; last unheld gate is 5. No Mac and no installed iPhone
build are available. That constraint is settled. An interactive comparison is
one possible future observation, not a prerequisite for useful CI investigation.

Baseline candidate: `480df32f58b82f6320d90739fcb74a8b6e72acd5`.
Main: `bd069f29c6d045d5bc27fc56212edcbde2090855`, failed, not accepted.
Local source was compared with the candidate archive after newline normalization;
no content differences were present. The desktop checkout is left untouched.

## Separate unresolved failures

- Switch: `39058576894`, `39060200894`, `39061680552` contain actual ordinary
  one-tap misses. The latter reaches neither native valueChanged nor binding/owner
  submission. Earlier SwiftUI failure `38843851982` positively records window
  delivery to its visual lens; it does not prove delivery to the current UIKit
  adapter or native control recognition. No OS defect is established.
- Editor: [39064851750](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39064851750)
  passes the focused audio/management invocation but fails the same audio test in
  Shell.xcresult. After Save, an ordinary saved-row tap is followed by absence of
  editor.preview; hierarchy remains on the alarm list with the saved Rapid Beeps
  row and On state. The helper then scrolls the wrong screen repeatedly. No row
  action/draft/presentation trace exists for that failed input. Do not infer an
  audio fault or the switch's cause from this observation.
  Native artifact `12114687647`, toggle `12112604762`, editor `12113191811` are
  available until October 24, 2026. Availability is not an acceptance claim.

## Exhausted comparisons

Duration, thumb drag, label activation and boot-only changes are insufficient.
Zero-target probes provided no native evidence. The previous twenty-flow passive
window/control diagnostic `39063276440` captured successful chains only; this
cannot clear historical misses. Do not repeat that sampling unchanged.
Direct setter and UIKit adapter candidates remain unaccepted remedies. Preserve
native controls, exact values/status/persistence assertions and one tap per input.

## One additional discriminating batch

`gate6-diagnostic.yml` applies `Scripts/diagnose_gate6.py` only inside an ephemeral
CI checkout. No product source change is committed. Three original switch flows
and three original audio flows run under a single thirty-minute cap, recording
every result; this is a fixed sample budget, not retry-to-green. The ordinary
workflow explicitly skips this diagnostic-marked commit; no gate acceptance is
claimed by the diagnostic workflow, regardless of color. No downstream replay
occurs while the known failure remains unresolved.

Additional observations compared with the previous probe:

| Boundary | Observation |
| --- | --- |
| Test targeting/readiness | Timestamp, concrete role/ID, frame, enabled/hittable/value, app state, screenshot/hierarchy immediately before/after input |
| Touch delivery | Positive window attachment, began/ended/cancelled coordinates and public ancestor identities, app/scene state, ancestor recognizer states |
| Native recognition | UISwitch beginTracking result, endTracking before/after, cancellation, attachment, target count and updates; original valueChanged journal |
| Binding/owner | Original synchronous setter guard, binding request and owner completion journals |
| Editor | Row action with stable ID/owner existence/busy/route, draft assignment/change, editor appearance/disappearance, routing revisions |

The passive recognizer never recognizes, delays, cancels or prevents another
gesture. Tracking overrides call the original implementation once. Instrumentation
can affect timing; passing instrumented runs cannot prove correction. A new bounded
editor.save assertion stops at missing reopening before unrelated preview scrolling;
all original preview, value, status, and persistence assertions remain.

## Verified diagnostic outcome — STOP / Gates 6–12 HELD

Source `d9a585bd3d17a93a6512dff031a21345296a8f4a`, run
[39074041807](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39074041807),
attempt 1: complete diagnostic workflow SUCCESS, every step. Xcode 26.6 / build
17F113; Simulator only. Three switch flows and three audio/editor flows PASS.
This is six executions of two existing declarations, not six additional tests.
No failing input was captured. No gate acceptance, production correction, complete
regression, Release validation, final-main validation or physical evidence follows.

Artifact [12116418876](https://github.com/teejayishere/PuzzleAlarm/actions/runs/39074041807/artifacts/12116418876)
contains both xcresults, exported attachments/tests JSON, complete per-flow logs,
outcomes, all process journals, generated patch and probe source. Expires October
24, 2026, 22:29 UTC. SHA-256 of archive:
`e22995aa2af822384a25e7c5db68ae88b1c3f0e45f674d291cf9a830b5dc115d`.

Observed limits and findings:

- 24 immediate test snapshots: before/after nine switch inputs and three saved-row
  reopenings. All before-input targets are enabled/hittable with the expected
  concrete role and ID; these are successful samples only.
- Nine positively attached window probes across processes. Nine switch inputs
  have paired window touches with the intended native switch in the ancestor path,
  followed by nine valueChanged, nine setter/binding requests, nine owner entries
  and nine owner completions. App/scene raw states are 0. Private class names are
  diagnostic data only; no private API is invoked. Seeing a glass-lens class is
  therefore not itself proof of a wrong target: successful inputs also hit it.
- **Zero public beginTracking/endTracking/cancelTracking callbacks, including on
  successful inputs.** These overrides are ineffective for identifying this
  runtime's recognition path. Do not interpret their absence as rejection or
  delivery loss. Ancestor recognizer snapshots are observations at probe callback
  time, not a complete recognizer decision history.
- All three saved-row reopenings show sheet binding nil/editor disappearance
  before the input, row action with existing owner/busy=false, draft assignment,
  sheet binding set and editor appearance. Three later relaunch reopenings also
  reach action/draft/appearance. No failure path exists to compare. This neither
  proves nor rejects a dismissal-transition race in the historical failed run.
- Additional screenshots/hierarchy reads add time before input. Instrumentation
  can mask timing-sensitive failures. Passing this batch cannot clear prior misses.

Stop after this fixed batch. Do not repeat it unchanged or alter production input,
binding, owner or presentation state based on these successful observations.

## Missing observation and minimum external action

Setup-only attempt: `3a92799` / run `39073944312` FAILED before test execution:
XcodeGen was installed and used in one step, before GITHUB_PATH takes effect.
Separate installation into its own step. No input sample or product conclusion
comes from that setup failure; the fixed diagnostic is still the planned batch.

| Failure | Precise missing observation |
| --- | --- |
| Current UIKit switch miss | For one actual missed input, the paired concrete target/frame/readiness and window began/ended/cancelled trace, effective recognizer decision/event outcome, then valueChanged/setter/owner presence or absence in that same process. Historical no-event records lack that paired trace; earlier SwiftUI window delivery cannot substitute. |
| Saved editor reopening miss | For one actual failed reopening, the pre-input saved-row target/readiness and dismissal state, actual touch path, row-action receipt, draft before/after and sheet/route publication. The historical failed run has only XCTest synthesis and the later alarm-list hierarchy. |

Minimum external action to unblock is **capture one actual failure with the missing
same-process boundary records**, then review its xcresult/video/journal. An existing
free CI runner or another available Simulator executor can supply that observation;
no user hardware acquisition or iPhone installation is requested. Successful samples,
more unchanged green runs and sendActions contract tests cannot supply it.

If a missed input reaches the intended control but public recognizer snapshots
still cannot distinguish recognition rejection from synthesis/transition behavior,
the next external artifact must be a platform input/recognizer decision trace for
that failing interaction (runtime/tooling support). The ineffective public tracking
overrides are not that artifact. No production remedy or OS attribution is justified
without this missing evidence. No further experiment is queued in this closeout.

Only an evidence-supported correction can start ordered Gate 6–12 replay and the
required complete exact-final-main workflow. Stop after Gate 12; no Stage 13 or UX
redesign. Physical alarm, intent, camera and audio observations remain separate.


## Authorized buffered passive-capture experiment — October 17, 2026

User authorized one materially changed batch on verified branch HEAD
`420a52ef46722dcd9fcea0e5b20beac018cc3894`. CI-only generated instrumentation
replaces synchronous file journals with main-actor serialized, preallocated and
prefaulted MAP_SHARED storage (16,384 fixed 1,024-byte slots plus header per
process). No file open, append, flush or lock occurs in record callbacks. String
formatting, public property observation, clock reads, memory stores and possible
later paging still cost time; this is not zero overhead or proof of nonperturbation.

Remove all traceInput-added queries, screenshots and hierarchy reads; remove
ineffective tracking overrides. Preserve the passive window recognizer and control
attachment, valueChanged, setter, binding, owner, row action, draft, route and sheet
boundaries. Touch and ancestor/gesture observations use separate bounded records;
record/path/gesture truncation invalidates complete capture. Overflow/truncation
counters are persisted before a fail-stop. Sequence, process launch UUID/PID,
monotonic/wall clocks, length/flags and metadata/payload checksum support decoding.
Files are unique per process and never wrap or overwrite old records.

Before Simulator boot, compile/run the actual Swift writer and independently decode
normal/Unicode, overflow and truncation fixtures; run decoder corruption/gap/partial
write/missing-attachment tests. A validation failure stops without Simulator tests.
Original test selectors, readiness checks, single taps and exact assertions stay;
only the existing bounded post-tap editor.save presentation assertion is retained.
No added pre-tap inspection, wait or retry. Each of the existing switch and
audio/editor declarations runs once, sequentially, with no automatic retries.
Stop at the first relevant or instrumentation failure. Fixed absolute request cap:
23:59:33 UTC; terminate test execution before 23:54:33 UTC, including setup time.
Always retain the artifact even on failure. Both passing means INCONCLUSIVE.

Export exact source SHA, generated patch including added Swift files, toolchain and
runtime inventory, complete xcresults, build/test activity logs, raw mapped files,
decoded process timelines, integrity counters and outcome manifest. Missing
attachment, overflow, truncation or incomplete capture prohibit negative conclusions.
Only diagnostic tooling is published; no production remedy or gate acceptance.
Gates 6–12 stay HELD, Stage 13 is not started; stop after reporting this experiment.


## Buffered experiment outcome — STOP

See [complete archived evidence](evidence/gate6-buffered-39079559751/README.md).
Run 39079559751 at 4b0e1c126bec45723e30481cd6eab59a40fe2fa9 failed on
unsupported xcodebuild `-test-iterations 1`, before UI test execution. Actual Swift
writer/decoder validation passed. Zero switch and zero editor/audio declarations
executed; one Simulator job, no retry. Capture absent; no product conclusion.
The original invocation-created xcresult and full logs are preserved. Gates 6–12 HELD.

## Corrected buffered experiment authorization — October 17, 2026

User authorized exactly one corrected bounded Simulator job after the zero-execution
invocation failure. Remove `-test-iterations 1`; use default single execution, never
increase iterations. Preserve diagnose_gate6.py, recorder/decoder, all original
readiness/selectors/single taps/assertions and the existing bounded batch.
Selected Xcode help and an exact-command dry-run must pass before UI execution.
Accounting now distinguishes invocation, actual starts, completed xcresult test cases,
tooling failure, incomplete capture, captured assertion failure and successful samples.
Seven local accounting tests and six existing decoder tests PASS on Windows; these
are tooling tests, not Xcode/Simulator/product evidence. Actual Swift validation still
runs on the selected Mac toolchain before Simulator boot. One thirty-minute job,
setup included; test execution stops before minute 25, no retries or repair-and-repeat.
Exact run, capture and outcome will be archived separately after this sole job.
Gate 6 FAILED; dependent 7–12 HELD; no remedy, promotion, downstream replay or Stage 13.

## Corrected buffered experiment outcome — STOP

6ba4de1dbadff8c1233fed0488a99d1fbe57c335 / run 39080779760 attempt 1
stopped on selected-Xcode help check: the new -dry-run preflight option is not
advertised. Zero Simulator boots, UI invocations and actual UI executions; one
macOS job. No repair or repeat. Iterations=1 removed without increasing iterations;
final invocation remains unvalidated. Correct TOOLING_FAILURE manifest, absent/
incomplete product capture, no successful sample or captured product failure.
See evidence/gate6-buffered-39080779760/README.md for original artifact/log and
explicit absent xcresult/trace/integrity evidence. No further experiment queued.
Historical failures remain unresolved; Gates 6–12 HELD. STOP.
