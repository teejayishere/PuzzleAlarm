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
| SwiftUI shell / generated Xcode project | XCODE COMPILE PASS | See Stage 2 evidence below |
| AlarmKit / App Intent SDK compilation | XCODE COMPILE PASS | Stage 3 evidence below; physical effects unverified |
| Disk persistence / atomicity / disk failures | NOT STARTED | Stage 4; Codable evidence is not disk evidence |
| Actual scheduling/rollback/edit/disable/delete effects | NOT STARTED | Stage 5; current evidence covers model transitions only |
| Challenge coordinator and answer validation engines | NOT STARTED | Stages 7–10; success events currently supplied by tests |
| Memory hidden-state restoration and camera QR matching | NOT STARTED | Stages 9–10 |
| Audio resources / previews / real alarm sounds | NOT STARTED | Stage 11 |
| Native shell launch on iPhone Simulator | SIMULATOR PASS | One launch/title test; product flows still NOT STARTED |
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

## Gate 2 — PASS (observed 2026-10-02)

Revision: 7d619f480c99b8868cbb7bfc7a776132deb104db
[Actual corrected CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37035827761).
Environment: standard macos-26, macOS 26.6.2, Xcode 26.6, Swift 6.3.3.
XcodeGen 2.44.1 installed from its checksum-pinned official release.

| Capability | Status | Evidence |
| --- | --- | --- |
| Clean project generation | AUTOMATED PASS | Project, shared scheme and generated Info.plist reproduced byte-for-byte |
| Core package regression | AUTOMATED PASS | Manifest/build; all 26 tests; 439/444 production lines = 98.87% |
| Native iOS app compilation | XCODE COMPILE PASS | xcodebuild BUILD SUCCEEDED, iOS 26.5 Simulator SDK |
| Core linked as SwiftPM product | XCODE COMPILE PASS | Dependency graph and compiler log reference Package.swift; no duplicated core sources in app |
| Dynamic iPhone destination | AUTOMATED PASS | Discovered iPhone 17 / iOS 26.5; no fixed model/UUID, native architecture selected |
| Native shell launch | SIMULATOR PASS | ShellLaunchTests.testLaunchDisplaysNativeShell; 1 XCTest UI test, 0 failures |
| Xcode diagnostic review | AUTOMATED PASS | No compiler/destination warnings; 2 explicit no-AppIntents SDK metadata advisories |
| Earlier gate invalidation | None | Stage 1 source and tests unchanged; core regressions replayed |
| AlarmKit and all Stage 3+ features | NOT STARTED | Scope explicitly stops after Gate 2 |
| Physical installation/behavior | DEVICE REQUIRED | No device claims |

Initial shell run at 373fa89 also passed generation/build/launch:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/36946854457
Audit found ARM/Intel destination ambiguity and corrected the CI destination.
The corrected run above confirms that warning is gone. The remaining metadata
advisory is an Apple tool message because this stage intentionally has no AppIntents.
No warnings were hidden and no excluded functionality was added to silence it.

Local focused checks: five Simulator-discovery cases and four diagnostic-classifier
cases passed; YAML structure and Python syntax checked. These do not substitute
for the real Xcode and Simulator results above.

## Gate 3 — compile/integration PASS at recorded implementation

Revision: 6e750fdbe510a4dc2174fc222e62f05548b96eae
[Actual CI run](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095598366).
Installed SDK observed before implementation in
[run 37095284734](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095284734).

| Evidence | Result |
| --- | --- |
| Gate 0–2 regression | PASS: reproducible generation; core manifest/build; 26 tests; 439/444 lines (98.87%); app build; shell launch |
| AlarmKit + AppIntents | XCODE COMPILE PASS in real app; metadata extraction completed |
| Permission configuration | AUTOMATED PASS: actual built .app/Info.plist has nonempty NSAlarmKitUsageDescription |
| Platform adapter tests | AUTOMATED PASS: 7 tests, no daemon or permission calls |
| Metadata identity/role | Five planned IDs, UUID/ordinal mapping, Codable minimal keys, foreign ID rejected |
| Relative schedule | All 128 weekday subsets and boundary wall time; never/weekly mapping |
| Presentation/intent | Alert only; custom Solve action; occurrence ID; foreground mode |
| Fake adapter boundary | Stable scheduling/cancellation ID; snapshot/update forwarding; error propagation |
| Diagnostic review | No compiler/destination warnings; one unchanged SDK advisory in UI-test bundle |
| Physical AlarmKit effects | DEVICE REQUIRED; no firing, permission, lock-screen, Focus/Silent, intent launch or playback claim |

Exact API-by-API matrix and scope limits:
[ALARMKIT_CAPABILITIES](ALARMKIT_CAPABILITIES.md).

The final follow-up strengthens the empty-update assertion and corrects diagnostic
wording. It requires its own exact-HEAD successful run; the run above is evidence
only for its named revision. No earlier gates invalidated. Stage 4+ NOT STARTED.

## Gate 4 — persistence implementation PASS at recorded revision

Revision: 47c96dc9bb9b5c122e4ac0fd6f240eec1b784461
[Actual full CI](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144199020).
27 focused persistence tests; 53 full core tests; seven platform tests;
one iOS disk integration test; one native shell launch test.
62 distinct test functions, excluding focused repeats/parameterized invocations.
Core coverage: 772/779 lines (99.10%).

| Requirement | Observed evidence |
| --- | --- |
| Empty/missing, save/load/update/delete, multiple definitions | AUTOMATED PASS; explicit missing differs from a committed empty document |
| Weekdays/modes/order/sounds/timestamps | AUTOMATED PASS; configuration permutations and schema round trips |
| Session lifecycle/progress/index/parent/snapshot | AUTOMATED PASS; all ten phases, inFlight schedule/cancel and partial failures preserved |
| Ownership ledger | AUTOMATED PASS; all five IDs/ordinals, detached records, duplicate UUID and competing authorities rejected |
| Math/Memory/QR data | AUTOMATED PASS; exact math problem, five Memory phases/deadline, QR token; no engines/camera state |
| Corruption/schema | AUTOMATED PASS; empty/truncated/malformed bytes, invalid enum/configuration, schema 0/2/99 rejected; bytes retained |
| Atomic failure | AUTOMATED PASS; injected failure after staging preserves prior document and reports interruption |
| Initial interrupted write | AUTOMATED PASS; missing committed document plus pending file never becomes a valid empty state |
| Real filesystem errors | AUTOMATED PASS; staging-path write failure and blocked storage directory surfaced |
| Concurrency | AUTOMATED PASS; stale revisions rejected; one winner across simultaneous memory writes and separate disk actors |
| Reconciliation representation | AUTOMATED PASS; recognized/persisted-missing/stale/orphaned ownership inventory; no recovery actions |
| Production iOS persistence | SIMULATOR PASS; real Application Support create/save/reload |
| Gates 0–3 | PASS; original 26 core tests, generated build, AlarmKit/AppIntents, seven platform tests, shell launch retained |
| Diagnostics | PASS; no compiler/destination warnings; known UI-test metadata advisory remains |
| Physical durability/AlarmKit | DEVICE REQUIRED |

Final follow-up adds four adversarial tests: invalid commit retains good bytes;
invalid ownership/timestamp decoding; cancelled ID still present classified stale;
real disk read error distinguished from missing. Concurrent losers must specifically
report conflict. It also removes redundant schema decoding. Final acceptance
requires a full successful CI run for that exact follow-up revision.
No earlier gate invalidated. Stage 5+ remains NOT STARTED.
