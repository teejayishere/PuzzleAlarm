# Gate 6 bounded input investigation — October 17, 2026

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

## Stop rule and missing observation

Setup-only attempt: `3a92799` / run `39073944312` FAILED before test execution:
XcodeGen was installed and used in one step, before GITHUB_PATH takes effect.
Separate installation into its own step. No input sample or product conclusion
comes from that setup failure; the fixed diagnostic is still the planned batch.

If this batch provides no failing correlated trace, stop with Gates 6–12 held.
Do not add gesture/state remedies or another unchanged batch. The missing evidence
is a failed input correlated across test target/readiness, actual window touch and
control recognition, binding/action entry, and authoritative owner/presentation
state. Successful traces cannot retroactively supply it.

Minimum next action then is an executor able to capture one failing input with
those boundaries in the same process (existing free macOS CI or another available
Simulator executor). A Mac purchase or iPhone installation is not required to
continue speculative debugging. If UIKit's public traces still cannot distinguish
recognizer rejection from Simulator synthesis after an actual failure, the minimum
external action is review of that failing xcresult/video/journal and a platform
input trace for that single interaction, rather than a redesign or blind retry.

Only an evidence-supported correction can start ordered Gate 6–12 replay and the
required complete exact-final-main workflow. Stop after Gate 12; no Stage 13 or UX
redesign. Physical alarm, intent, camera and audio observations remain separate.
