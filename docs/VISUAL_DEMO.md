# Current-app visual demo (documentation only)

Baseline main: `10be76a4b071c7c32b7f8e1938a0883f78d9e66e`.
Complete exact-main CI, all three required jobs and every step SUCCESS:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38923363999
(observed October 16, 2026). Capture revision 3a872db6b0334a1a921f8415fa8c55d2f39b4e10
completed CI 38972785748 successfully. That capture was Stage 11; Stage 12 routing
work and current gate evidence are tracked in PROJECT_STATE.

Existing ordered Simulator CI and UI tests capture eleven named XCTest screenshot
attachments: list, create, edit, repeat, Math and Memory configuration, sound
selection, Math, Memory recall, QR challenge and QR display. Application source,
fixtures, behavior, assertions and gate ordering are unchanged. No video is
recorded; the numbered gallery provides a still-image walkthrough.

After every existing check succeeds, `Scripts/export_visual_demo.py` exports the
focused Management, Math, Memory and QR attachments. It requires every named PNG
exactly once, verifies portrait PNG headers/dimensions and writes an offline HTML
gallery, README and metadata with exact SHA/run, toolchain, Simulator inventory,
original attachment records and SHA-256 image hashes.

Download the Actions artifact named
`PuzzleAlarm-iPhone-Visual-Demo-<full capture commit SHA>` (30-day retention).
On Windows, right-click the ZIP, choose **Extract All**, then double-click
**index.html** in the extracted folder. PNGs also open directly in Photos.
GitHub may require signing in to download artifacts. No Mac, Xcode or xcresult
viewer is needed. The final task report supplies the immutable capture SHA/run
and direct artifact link after actual CI completion; this document does not
claim a pending revision has passed.

Evidence categories:

- Source: production app and deterministic DEBUG fixtures unchanged from baseline.
- Automated/Xcode/Simulator: baseline PASS at the link above. Capture revision
  requires its own full exact-revision run; the gallery links that run.
- Physical device: NOT RUN. Scheduler and scanner effects use existing DEBUG
  fakes. Camera scanning, alarm delivery, audible sound, lock/Silent/Focus and
  provisioning remain device-required. Visible fake QR controls are intentional.

This is a downloadable evidence artifact, not deployment or Stage 12.
