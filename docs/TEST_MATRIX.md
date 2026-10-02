# Evidence ledger

Observed 2026-10-01 America/Chicago (CI timestamps 2026-10-02 UTC).

## Gate 0 — PASS

Revision: 92faaf89716a4f4d030e8cff4abe1021a07dd558
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36943963689).
Manifest parsing, core compilation and Foundation/Swift Testing smoke test passed.
Local YAML structure, coherent source layout, free-dependency review and common
secret-pattern scan passed. No claim of an exhaustive secret/security audit.

## Gate 1 — PASS

Revision: cb5797f133993183e5dcf6082598182dc25450a9
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945373495).
26 test functions; parameterized cases are reported separately in the log.
Swift 6.3.3 / Xcode 26.6 on standard macos-26. Warnings are errors.

| Capability | Status | Evidence |
| --- | --- | --- |
| Definition creation/edit/enable/disable, modes, weekdays, sounds | AUTOMATED PASS | ModelTests; replacement preserves identity; no OS effects claimed |
| Unique ordered configuration, add/remove/reconfigure/reorder | AUTOMATED PASS | ModelTests + all 15 allowed session sequence permutations |
| Config validation and Codable round trips | AUTOMATED PASS | ModelTests, DecodingTests; malformed values rejected |
| Next occurrence | AUTOMATED PASS | 13 explicit cases: weekday/weekend, exact time, midnight, month/year/leap boundaries, Chicago DST gap/repeat, Kathmandu offset |
| Weekly schedule invariants | AUTOMATED PASS | Seven weekdays across 370 instants (2,590 checks), strictly future with correct wall time/day |
| Five-alarm plan | AUTOMATED PASS | Exact offsets/unique IDs, crossing midnight, decode corruption |
| Session lifecycle | AUTOMATED PASS | No false armed state; activation time checks; strict success order; finalization invariant |
| Partial scheduling/unknown outcomes | AUTOMATED PASS | All five failure positions; in-flight round trip; concurrent unknown outcome retained |
| Cancellation model | AUTOMATED PASS | Each failure position, continue after failure, retry, restore and duplicate acknowledgments |
| Immutable session snapshot | AUTOMATED PASS | Definition edits/disable preserve occurrence; future-edited snapshot creation rejected |
| Future retirement | AUTOMATED PASS | Cancellation required; cancelled is not completed; active retirement rejected |
| Counter checkpoints | AUTOMATED PASS | Matching types, bounds, monotonicity and restoration |
| Corrupted lifecycle data | AUTOMATED PASS | False armed/completed states, ledger shapes, invalid progress/dates/IDs rejected |
| Core line coverage | AUTOMATED PASS | 439/444 lines = 98.87%; does not imply full branch/behavior coverage |
| SwiftUI shell / generated Xcode project | NOT STARTED | Stage 2 |
| AlarmKit / App Intent SDK compilation | NOT STARTED | Stage 3+ |
| Disk persistence / atomicity / disk failures | NOT STARTED | Stage 4; Codable evidence is not disk evidence |
| Actual scheduling/rollback/edit/disable/delete effects | NOT STARTED | Stage 5; current evidence covers model transitions only |
| Challenge coordinator and answer validation engines | NOT STARTED | Stages 7–10; success events currently supplied by tests |
| Memory hidden-state restoration and camera QR matching | NOT STARTED | Stages 9–10 |
| Audio resources / previews / real alarm sounds | NOT STARTED | Stage 11 |
| iOS Simulator flows | NOT STARTED | No iOS app target exists |
| Physical firing/camera/audio/provisioning | DEVICE REQUIRED | No device observations |

Production coverage by source: Challenges 100%; Models 100%; Scheduling 97.10%;
WakeUpSession 98.77%. Coverage reporter excludes tests and generated SwiftPM sources.

## Failed evidence and replay

[First Stage 1 run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945010757)
at eb03c50 failed test compilation; production build passed.
Root cause: missing inner try in #require. Test requirements were unchanged.
[Corrected run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945155823)
at 76420f1 passed 21 tests before the final adversarial expansion.

Local Windows Swift remains absent by choice; CI supplies actual execution evidence.
No paid service/tool was introduced.
