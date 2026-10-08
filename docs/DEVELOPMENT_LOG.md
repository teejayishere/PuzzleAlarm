# Development log

## Stage 0, attempt 1 — 2026-09-30

Status: BLOCKED

Changes: Independent project scaffold, dependency-free Swift package, iOS boundary,
XcodeGen definition skeleton, Stage 0 CI, master specification and evidence docs.
Tests added/changed: None; no domain implementation exists.
Commands executed: Get-ChildItem; Get-Command swift,git,gh,wsl,docker;
git status --short; git diff --stat in starting folder; wsl --list --quiet;
common Swift installation-directory checks.
Focused validation: Environment discovery complete. Swift unavailable.
Full gate result: BLOCKED; manifest parsing and module compilation cannot run.
Regression gates rerun: None; no prior gates passed.
Self-review findings: Starting folder is an unrelated Next.js app; create a
separate sibling project. No Next.js source needs editing.
Adversarial-review findings: Keep CI named Stage 0; private repositories skip
execution; no scaffold result may count as iOS build evidence.
Invalidated prior gates: None.
Known limitations: No Swift compiler, Xcode, Simulator, remote or observed CI.
Device validation remaining: All device plan cases.
Next action: Finish structural review, then obtain Swift/CI execution and rerun Gate 0.

### Structural review follow-up

Commands executed: Node stdin validation using built-in fs/path/assert/crypto and
existing js-yaml from the adjacent development environment; git -c
safe.directory="C:/Users/Teej/Desktop/Puzzle Alarm" -C
"C:/Users/Teej/Desktop/Puzzle Alarm" remote -v.
Result: 16 authored/specification files inspected. YAML parses and structural
assertions pass; exact master-plan copy, no package dependency, common secret
patterns and trailing-whitespace checks pass. No remotes configured.
Initial validation attempt: Python could not import yaml. Reused an existing
Node YAML parser; no dependency installed or added to PuzzleAlarm.
Git initially rejected sandbox ownership; used a command-local safe.directory
for this exact repository, without modifying global Git configuration.
Self-review: project.yml intentionally has no targets; no placeholder app or
trivial test falsely implies Stage 1/2 progress. CI reports its Stage 0 boundary.
Full gate remains BLOCKED. No Swift/Xcode commands or tests have run.
Next action: obtain Swift execution or a public GitHub remote, run the Stage 0
workflow for a recorded revision, and rerun Gate 0 before implementing Stage 1.

## Stage 0, attempt 2 — 2026-10-01 America/Chicago

Status: PASS
Changes: Public repository created; executable standard macos-26 workflow;
SwiftPM test target and Foundation/Swift Testing toolchain smoke test.
Tests added: foundationCodableAvailableInPackageTests (tooling only).
Commands executed: gh auth status; gh repo create; git commit/push; gh run view
36943963689 --json status,conclusion,headSha,jobs,url; gh run view --log.
Focused/full gate result: actual manifest parse, build, swift test passed.
CI: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36943963689
Revision: 92faaf89716a4f4d030e8cff4abe1021a07dd558
Toolchain: macOS 26.6.2; Xcode 26.6 build 17F113; Swift 6.3.3; 1 test passed.
Self-review: no paid runner or dependencies, no platform app code; GitHub
noreply identity configured only in this repository. Public status verified.
Adversarial review: smoke test is explicitly not domain evidence; private repos
are guarded out; workflow failures propagate rather than being ignored.
Regression gates rerun: Gate 0 checks. Invalidated gates: None.
Known limitations/device validation: all iOS and hardware behavior unverified.
Next action: Stage 1 domain models and behavioral tests, then current CI.

## Stage 1, attempt 1 — 2026-10-01 America/Chicago

Status: FAILED (test compilation)
Changes: Value models, snapshots, operation ledgers, controlled lifecycle,
calendar/DST rules, backup generation and behavioral/Codable tests.
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945010757
Revision: eb03c50d1dfeb3785c96f758a19304412c0b1c18
Actual result: manifest and production core build passed; Swift test compilation
failed at SchedulingTests.swift:74. #require macro needs explicit inner try.
Classification/root cause: test defect in macro throwing-expression syntax.
Correction: add inner try; preserve every assertion and production behavior.
Local focused validation: inspected macro expansion in actual failed CI log;
git diff --check. Swift execution remains CI-only.
Gate 0 assumptions remain supported; Gate 1 has never passed.
Next action: rerun package validation/build and complete test suite on macOS.

## Stage 1, attempt 2 — 2026-10-01 America/Chicago

Status: AUTOMATED PASS, audit pending
Revision: 76420f1f8595d5c82cf103824e948088923a1b3f
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945155823
Changes: One explicit inner try in the existing calendar invariant test.
Tests: All 21 functions passed, including 15 sequence/13 calendar cases and each
scheduling/cancellation failure position. Assertions were not weakened.
Commands: gh run view --json; gh run view --log; git diff --check; git push.
Gate 0 replay: manifest validation and core build passed before tests.
Next action: Finish adversarial review and measure production coverage.

## Stage 1, attempt 3 — 2026-10-01 America/Chicago

Status: PASS
Revision: cb5797f133993183e5dcf6082598182dc25450a9
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36945373495
Changes: Five adversarial tests; dependency-free coverage summary script.
Tests added: concurrent uncertain scheduling outcome survives failure/restore;
stale session snapshot timestamps; malformed checkpoint counters/types;
non-finite/extreme calendar inputs; regressing success/finalization timestamps.
Commands: Python ast.parse (reporter); rg safety/boundary checks; git diff --check;
git push; gh run view --json and --log.
Focused validation: prior macro failure reproduction fixed in actual compiler;
new assertions exercise identified recovery/decoding edges.
Full gate: manifest parse, warnings-as-errors build, 26 tests and coverage report
all passed. Core coverage: 439/444 lines = 98.87%.
Regression gates rerun: Gate 0 and all Stage 1 tests, including 2,590 date checks.
Self-review: explicit immutable values, controlled mutations, bounded settings,
validating decoding, no Apple UI/OS adapters or uncontrolled time/randomness.
Adversarial findings: rollback must retain unacknowledged in-flight IDs; future
retirement must never become challenge completion; creation cannot predate a
snapshotted edit. Tests now cover these. No additional failing behavior observed.
Invalidated prior gates: None. Expanded suite passed before Gate 1 acceptance.
Known limitations: core state/checkpoint tests are not engine, disk, OS or device
tests; operational side effects and full Math/Memory round snapshots are deferred.
Device validation remaining: all cases.
Next action: Documentation-only evidence commit and exact-HEAD CI confirmation.
Stage 2 remains unstarted under the user's latest Stage 1-only scope.

## Stage 2, attempt 1 — implementation awaiting CI

Base: 457fe81ee26cfac1312cf9ecb648b6eccf076f0f; clean working tree and prior PASS confirmed.
Changes: Pinned/checksummed XcodeGen 2.44.1; local SwiftPM product dependency;
minimal SwiftUI title screen; iPhone-only iOS 26 app; one launch UI test;
dynamic compatible iPhone discovery; generation reproducibility checks;
existing core tests and coverage preserved in expanded CI.
Package change: explicit iOS 26 minimum added alongside macOS 13. No core source
or API change; prior macOS-only declaration did not exclude other platforms.
This is deployment configuration, not evidence of an invalid Stage 1 assumption.
Local validation: pending structural checks; no local Xcode claim.
Gate 0/1: last PASS retained; regression replay runs before iOS build/tests.
Gate 2: pending actual generation, iOS compilation and Simulator test evidence.
No Stage 3+ product functionality introduced. No paid tool/service or signing keys.

## Stage 2, attempt 1 — actual CI success; audit correction required

Revision: 373fa89e856b3f2b03d32b1baf4f00ed0c104a56
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/36946854457
Generation: PASS (project/scheme/Info.plist reproducibility comparisons).
Core: 26 tests PASS; 439/444 lines = 98.87% coverage.
iOS app: BUILD SUCCEEDED on Xcode 26.6 / Swift 6.3.3.
Simulator: dynamically selected iPhone 17 / iOS 26.5; 1 launch test PASS.
Local validation: YAML/package-boundary checks and five Simulator-selector cases passed.
Self-review: actual log confirms core compiled from Package.swift as a dependency,
not copied into the app. No core source/test changes from 457fe81.
Adversarial finding: xcodebuild matched ARM and Intel variants of the same UDID.
Classification: Stage 2 destination configuration ambiguity; no core defect.
Smallest correction: add arch=$(uname -m) to both build/test destinations.
Add explicit warning audit: fail on new warnings; report the SDK's exact
appintentsmetadataprocessor advisory (no AppIntents dependency by design).
No compiler warnings found. Do not add Stage 3 code to remove an SDK advisory.
Gate 2 remains pending acceptance until the corrected current revision passes.
Earlier gates invalidated: None. Rerun full CI with core regressions before Gate 2.
## Stage 2 adversarial review

- Clean checkout: GitHub checkout supplies no generated project, build cache,
  certificates or user-specific Xcode state.
- Reproduction: pinned XcodeGen 2.44.1 with official release SHA256;
  consecutive generation compares project, shared scheme and Info.plist.
- Core linkage: local SwiftPM product dependency from path '.', no core sources
  listed in the application target, and no copied core implementation.
- Core boundary: no changes in PuzzleAlarmCore/Sources or its tests since 457fe81;
  no iOS-only imports in core.
- Simulator selection: available runtime/device metadata, iOS >=26, iPhone only,
  deterministic version/name/UDID choice. No fixed model or hard-coded UUID.
- Tool count: XcodeGen alone for generation; Xcode/Swift, Bash and standard-library
  Python for orchestration/reporting; no Homebrew/Mint or runtime dependencies.
- Deployment: package iOS 26 and app/test project iOS 26; macOS 13 remains solely
  the package host-testing floor.
- Diagnostics: Swift/C warnings treated as errors; actual job log warnings
  inspected separately before gate acceptance.
- Scope: SwiftUI title screen and launch assertion only. No AlarmKit, App Intents,
  camera, QR scanner, audio, persistence, scheduling effects or challenge UI.
- Cost: public repository, standard macos-26, signing disabled for Simulator,
  no credentials, larger runner or artifact storage added.


## Stage 2, attempt 2 — 2026-10-02

Status: PASS
Revision: 7d619f480c99b8868cbb7bfc7a776132deb104db
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37035827761
Changes: Native architecture in Simulator destination; explicit diagnostic audit.
Tests added/changed: No core or UI test weakened/changed. Four local diagnostic
cases reject compiler/destination warnings while reporting the specific SDK advisory.
Commands: git diff --check; Python local diagnostic cases; git push; gh run view
--json and --log; actual CI commands in .github/workflows/ios.yml.
Focused validation: log confirms ARM/Intel destination ambiguity eliminated.
Full gate: XcodeGen reproducibility PASS; core parse/build/26 tests PASS;
98.87% coverage; native iOS app BUILD SUCCEEDED; 1 UI launch test TEST SUCCEEDED;
warning audit PASS with no compiler/destination warning and 2 SDK metadata advisories.
Runtime: discovered iPhone 17, iOS 26.5; Xcode 26.6, Swift 6.3.3, macOS 26.6.2.
Regression gates rerun: Gate 0 package checks and complete Gate 1 suite.
Self-review/adversarial review: checklist above completed; one Stage 2 CI issue
corrected at its cause. No Stage 1 design assumption was disproved.
Invalidated prior gates: None.
Known limitations: title-only shell; Simulator and unsigned build only; no product
features, physical validation, AlarmKit or other Stage 3 implementation.
Device validation remaining: all cases.
Next action: Push documentation and verify exact-HEAD CI; stop after Gate 2.

## Stage 3, attempt 1 — 2026-10-02 America/Chicago

Status: PENDING actual compile/test result.
Base Gate 2 b3f12f8 and exact run 37037179078 verified successful; tree clean.
SDK observation: 917a399 / run 37095284734 PASS before platform calls were written.
Inspected installed Xcode 26.6 / iOS Simulator 26.5 public interfaces and official
Apple documentation. Found deprecated Stop customization/openAppWhenRun and
newer web overloads absent from the installed SDK. Implementation follows SDK.
Changes: one iOS scheduler protocol, thin injected adapter, traditional fixed
configuration, relative/weekly translation probe, minimal metadata, foreground
secondary intent with session ID, built-app usage-description validation.
Tests added: seven iOS tests, no real daemon/permission calls; existing 26 core
tests and launch test unchanged. Core source and Package.swift unchanged.
Local validation: YAML parses, git diff --check, core/shell unchanged diff.
A broad text replacement initially duplicated a project scheme block locally;
inspection corrected it before commit; the parsed final YAML has three targets.
Current implementation: 6e750fd; run 37095598366 under observation.
Self-review/adversarial findings: documented in ALARMKIT_CAPABILITIES.md.
Invalidated prior gates: None. Snapshot IDs support the existing recovery model;
metadata is not available in snapshots, so the persisted ledger remains required.
Known limitations: compilation and fake tests do not establish OS behavior;
Stage 4+ intentionally absent. All physical alarm behavior DEVICE REQUIRED.
Next action: inspect actual CI, correct any failure at its source, replay gate,
record passing evidence, then stop after Gate 3.

## Stage 3, attempt 1 — actual CI PASS; final follow-up pending

Revision: 6e750fdbe510a4dc2174fc222e62f05548b96eae
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37095598366
Actual result: generation/reproduction, manifest/build, 26 core tests,
439/444 production lines (98.87%), iOS BUILD SUCCEEDED, built-app nonempty
NSAlarmKitUsageDescription, seven platform tests, one shell UI test and
diagnostic check all PASS. Xcode 26.6 / iOS 26.5 / Swift 6.3.3; iPhone 17
selected dynamically. App and platform-test metadata extraction completed.
No compiler/destination warning. One existing no-AppIntents advisory belongs
to the UI-test bundle, which intentionally has no AppIntents dependency.

Self-review: diagnostic summary still described the old Stage 2 app as lacking
AppIntents; correct that text without expanding the warning allowlist.
Strengthen the fake update test to assert the empty snapshot is also forwarded.
No source/API failure, retry or weakened assertion. No earlier gate invalidated.
The inspection-only push's full regression run 37095284730 was superseded and
cancelled by the implementation push; it is not counted as passing evidence.
The dedicated SDK inspection run completed successfully.

Final follow-up changes: evidence docs, stronger empty-update assertion and
accurate diagnostic text. All require a fresh exact-HEAD full run before final
acceptance. No Stage 4 work. Physical behavior remains DEVICE REQUIRED.
Next action: push final follow-up, inspect actual full CI, stop after Gate 3.

## Stage 4, attempt 1 — implementation pending CI

Base: 6be4415148445f83a1879d2a219d3667327bcffc; clean tree.
Gate 3 exact-HEAD run 37096261777 rechecked successful.
Changes: schema-1 repository document; disk and byte-backed memory actors;
compare-and-swap revision; coordinated atomic replacement; interrupted-write marker;
canonical session-derived ownership ledger plus detached recovery records;
validated session timestamp/checkpoint wrapper; read-only reconciliation inventory.
Stage 1 counters/lifecycle were intentionally limited, not disproved. The additive
wrapper persists engine inputs without duplicating progress or changing lifecycle.
No earlier gate invalidated; full regressions required.
Tests: 27 persistence tests plus one iOS disk integration test; unchanged 26 core,
seven AlarmKit platform tests and native launch test retained.
Focused test step precedes full coverage suite in free standard macOS CI.
No permission/AlarmKit daemon calls, engine, scheduler, recovery actions or UI.
Status: Gate 4 PENDING actual Swift/Xcode execution.

## Stage 4, attempt 1 — actual CI PASS

Revision: 47c96dc9bb9b5c122e4ac0fd6f240eec1b784461
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144199020
Focused result: 27 persistence tests PASS.
Full gate: 53 core + 8 iOS unit/integration + 1 UI launch = 62 functions PASS.
Coverage: 772/779 core production lines (99.10%).
Xcode 26.6/iOS 26.5; production Foundation disk adapter compiles and executes in
iOS Application Support. AlarmKit/AppIntents and all prior checks remain green.
No compiler/destination warnings. One unchanged UI-test SDK metadata advisory.
Commands: git diff --check; free macOS focused/full Swift suites; coverage reporter;
Xcode generation/build/test; built plist validation; diagnostic review; gh run logs.
No test failure, speculative retry, warning suppression or weakened assertion.

Self-review: one Codable document, one ownership authority per session, no
platform-framework leakage into core; separate revision tokens prevent stale writes.
Adversarial review: staged termination leaves old committed state; uncertain
OS effects retain inFlight ledger; missing IDs never complete sessions; corruption
blocks overwrite; parent edits retain snapshots; concurrent commits do not lose data.
One gap in test strictness: losing concurrent writers initially accepted any error.
Strengthen to require conflict. Add four regressions for invalid commits,
ownership/timestamp decoding, stale cancelled IDs and actual read failures.
Remove duplicate header decode now that Snapshot validates schema before payload.
These are Stage 4 improvements, not defects in earlier models.

Earlier gates invalidated: None. Full Gates 0–3 regression replay passed.
Known limits: no actual process kill/power loss, separate-process contention,
iPhone file protection or daemon reconciliation evidence. No backup restoration,
migration, engine, product UI or Stage 5 actions implemented.
Next action: push final review changes and docs; run full exact-HEAD CI; STOP at Gate 4.

## Stage 4, attempt 2 — final implementation PASS

Revision: 40501452d1aaf7e7e3fa03ba54d153574d560fde
Run: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144990239
Changes: four adversarial regressions; exact conflict assertions; redundant
schema decode removed; architecture and evidence documentation.
Focused: 31 persistence tests PASS.
Full gate: 57 core + 8 iOS unit/integration + 1 UI launch = 66 distinct tests PASS.
Persistence: 31 core + 1 iOS = 32 tests. Parameterized cases/focused repeats
are not double-counted. Coverage: 771/777 production lines = 99.23%.
Actual Xcode BUILD SUCCEEDED and TEST SUCCEEDED; iOS disk round trip PASS.
Gates 0–3 replayed: generation, package, original 26 core tests, AlarmKit,
AppIntents, seven platform tests, nonempty built usage description and shell launch.
No compiler/destination warnings; one known SDK advisory in the UI-test bundle.
Commands: gh run view --json/--log, full CI commands in ios.yml, git diff --check.
Self-review: current source and tests meet Stage 4 requirements; no Stage 5 action.
Adversarial review: stricter concurrent losers are conflicts; invalid commits
retain bytes; timestamp/ownership corruption rejected; cancelled-but-present
IDs remain stale and do not change completion; real read error is not missing.
Earlier gates invalidated: None.
Known limitations: architecture's power-loss, process/device and recovery-action
limits remain. No physical AlarmKit behavior or iPhone file protection verified.
Next action: documentation-only evidence commit; confirm exact-HEAD full CI and STOP.

## Coverage audit — six missing baseline line counts and Stage 1 recursion

Baseline: cdd45d57477d8f2cbc492dbc9535ff76a28f8ecf, 771/777 (99.23%).
Raw same-source coverage: a5f7a28385141accf9e3131a788f5c2257f81982,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181404906.
TEST_MATRIX.md records each exact line, behavior, classification and justification.
Added repeatable LCOV plus SwiftPM zero-region/uncalled-function reporting to CI.

Hypothesis: the recurrence horizon fallback might hide a real skipped-date case.
Regression-only revision 1356491831105c34768d56632a122d4a83e25a96 failed:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181948057.
The actual error was "No occurrence found in calendar horizon" for Friday
recurrence across Pacific/Apia's skipped 2011-12-30. The other 59 core tests passed.
Earliest defect: Stage 1 assumed any selected weekday occurs within seven days.
Gates 1–4 invalidated; Gate 0 unaffected. Corrected the horizon to two weekly cycles,
preserving the weekday/local-time/DST policy and the explicit failure fallback.

Three regression functions added:
- weeklyOccurrenceSurvivesSkippedLocalCalendarDate: correct next real Friday,
  exact instant/local time and strictly future result.
- restoredLedgerKeepsExactlyOnePrimaryAndFourBackups: persisted IDs and owners,
  derived primary/backup roles, detached ordinary primary.
- completedReloadPreservesTerminalStateUnderLateEvents: duplicate success/finalize
  does not alter completion, and late cancellation failure/progress is rejected.

Focused and full CI PASS at b9c87ab56df0e0e7928578d978d1c03304faa5ce:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37182114469.
32 focused persistence + two focused domain regressions; 60 full core tests,
eight iOS unit/integration tests, one shell UI test = 69 distinct tests.
Persistence total: 33. Core coverage: 774/779 (99.36%).
The denominator includes two added explanatory comment lines in LLVM's regions;
the primary-role getter is the newly covered production behavior. Five line
counts remain: three throws and two invariant-unreachable autoclosures.
No superficial tests, removed guards, warning suppression or threshold change.

Self/adversarial review: only production edit is the recurrence horizon. Existing
DST/repeated-time/weekday property cases remain green. The new exact-date assertion
prevents silently choosing Saturday. No schema/lifecycle/ownership changes; malformed
completion remains rejected before either fallback. Error paths remain explicit.
No full calendar injection layer was added solely for unreachable/platform branches.

All Gates 0–4 checks now pass: package, generated iOS build, AlarmKit/AppIntents,
platform persistence/capability tests, shell launch and diagnostics. Gates 1–4 restored.
One known UI-test metadata advisory only; no new production compiler warnings.
Locally available checks: Python AST, YAML parse, git diff --check. Swift/Xcode ran
on free standard macos-26, not Windows. No physical device evidence claimed.
Final docs/report-label revision requires its own matching full CI; then STOP at 4.

## Stage 5 observation — RECURSE to Stage 1

Expected clean base f7e7e92 verified. Stage 5 exposes missing controlled transitions:
armed + observed missing ID must cease claiming armed, and a fully rolled-back
future occurrence must retry without replacing its stable IDs. Extend Stage 1
with guarded transitions, preserving active/completed boundaries. Two regression
functions exercise every missing position, round trips, retry identity, cleanup
and time restrictions. Gates 1–4 invalidated pending full replay. No Stage 5
orchestration runs yet; no device claims.

## Stage 5 — first transaction implementation and adversarial review

Stage 1 transition replay PASS: 6d53e594a5a7cde93c9f5e84550d61e4f9113dca,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37183294279.
62 core tests, full iOS/Simulator gate green, 790/795 (99.37%).
Fresh SDK inspection: https://github.com/teejayishere/PuzzleAlarm/actions/runs/37183340935.
No undocumented AlarmKit configuration fields or metadata reads were assumed.

First Stage 5 implementation: 2c2f36d6b15053e01610f2018ae02f5c5ea95299.
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37207440659 PASS.
68 core tests, prior platform/Simulator gate green, 1489/1797 (82.86%).
This was compilation/initial transaction evidence, NOT Gate 5 acceptance.
Expanded crash, command, recurrence, conflict and iOS composition tests follow.

Adversarial findings: old-cleanup failure must never roll back a healthy replacement;
snapshots before storage awaits can be stale when the OS effect runs; an operation
can cross wake time during an await. Added meaningful regressions and corrections.

RECURSE to Stage 1 again: missing presence after successful arming must not rewrite
historical scheduling acknowledgments as failed. Add degraded phase and preserve all
prior successful acknowledgments. Due degraded sessions become active, never completed
or bypassed; future degraded sessions can retire. Gates 1–4 require current replay.
Schema 2 journal and schema-1 upgrade are Stage 5 additions to the Stage 4 repository,
not evidence that corrupt state may be reset. No schema authority is duplicated.
Gate 5 remains PENDING full expanded tests, coverage audit and final exact-HEAD CI.

## Stage 5 final implementation — PASS after recursive replay

Revision: 8118e44dc007143813edf668cca223459cd97b88
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236486724
Full workflow SUCCESS: 123 core + 10 iOS unit/integration + one shell UI = 134 tests.
65 new tests relative to Stage 4: 61 lifecycle, two domain recovery, two iOS.
Focused persistence 32 core; focused lifecycle filter 63 (includes two pre-existing
test names, so it is not the count of new tests). Coverage 1840/1852 = 99.35%.

Gates 0–4 rerun: package, core, Apia/terminal/ownership regressions, reproducible
generated iOS project, AlarmKit/AppIntents, capability and disk tests, native launch,
usage description and diagnostics. Gates 1–4 restored after degraded-state recursion.
Known UI-test metadata advisory only; no avoidable production compiler warnings.

Expanded recovery evidence:
- c48aeb7d697c6c7dc0dd1dbf68939758635ee04c,
  https://github.com/teejayishere/PuzzleAlarm/actions/runs/37209286645:
  117 core, full gate PASS, 1835/1852 (99.08%).
- 88b62c8f07d3fb2544d3bec3088c78eeb38ca526,
  https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236350816:
  test compilation FAILED because uuid(999) exceeded the fixture's UInt8 range.
  Production package built. Small correction to fixture value 99; no production
  workaround, no suppressed diagnostic, no weakened assertion. Final full replay
  above passed, including ringing protection during replacement.

Self/adversarial review and uncovered-line classifications are in TEST_MATRIX.md.
Important corrections include preserved historical schedule acknowledgments,
fresh snapshots after storage awaits, bounded CAS merging, superseded delete
protection, deadline checks and one cleanup attempt per recovery pass.
The fake models errors after effects and retained OS state, not the orchestration.

Locally available validation: five Python scripts parsed; git diff --check clean;
no Apple presentation/platform framework imports in PuzzleAlarmCore.
Swift/Xcode validation used free standard macos-26. Device items remain untested.
Final documentation-only revision requires its matching full CI before exact-HEAD
acceptance; final task report records that SHA/run. STOP at Gate 5, no Stage 6.

## Stage 6 observation and initial implementation — gate pending

Clean requested base 159b777379ad587a615df56ef24fa273aa29ffe4 verified.
Gates 0–5 remain valid as baseline; Stage 6 must replay their full checks.
Read the current plan, evidence, models, persistence/lifecycle boundary, native shell,
platform adapter and CI before editing.

Implemented one production composition root, MainActor observable store, value
drafts, native alarm list/editor, configuration-only challenge/sound controls and
DEBUG-only external-effect UI fixtures. Added focused draft/store and critical UI
flows. New UI behavior does not change Stage 5 source.

Initial CI 37239917692 at 7e2b9e1: core regression passed; iOS compile failed because
a DEBUG sendable clock closure referenced an actor-isolated static fixture date.
Classified as Stage 6 fixture isolation; captured the immutable date before closure
creation. No warning suppression or prior-gate invalidation.
Self-review also corrected next-occurrence presentation: one-time dates come from
the persisted occurrence, never tomorrow's recalculation after the date passes.

Current gate remains pending expanded UI execution, adversarial review, coverage
audit and exact-HEAD CI. No physical device result claimed.

## Stage 6 native interaction failures — RECURSE within Stage 6

Run 37256439193 at fd457c2: all 123 core tests, Debug/Release builds, focused
24 app/draft tests and all 34 iOS unit/integration tests passed. Full UI suite failed:
authorization/large text, deferred-delete failure and evolved shell launch passed;
six management flows failed with 18 assertions/query errors.

Actual trace proved the unscoped Back helper selected the underlying list's
alarms.add button rather than the Repeat screen's Back button. Scoped navigation
to the visible titled navigation bar. Modern iOS menu accessibility exposed popup
elements outside a Button-only query; query the actual popup and option label.
Target the switch control rather than its outer label container.
Native confirmationDialog omitted the custom cancel action in its presentation;
use a native alert with explicit Keep Alarm and Delete Alarm choices.
Keep all behavioral assertions. Stop each UI test at its first failure and include
the test-only accessibility tree in failures for diagnosis.

These are Stage 6 interaction/UX issues. Core, persistence and lifecycle sources
remain unchanged; Gates 0–5 were not invalidated. Full current-HEAD replay remains
required after corrections. No Gate 6 PASS and no device claims.

## Stage 6 interaction correction and coverage audit

Run 37258084975 at 4f15ac4 passed 123 core tests and 36 iOS unit/integration
tests, with six of nine native UI tests passing. Three UI tests failed: challenge
menu opening in two flows, and ambiguous Keep Alarm selection. The actual tree
showed a full-row button wrapping a separate actionable menu-label button. Target
that child instead of the row center; select the confirmation action by identifier.
All mandatory assertions remain. No core or Stage 5 change was needed.

Added meaningful coverage regressions for intentional authorization on Save and
queued-refresh failure, followed by challenge persisted-date expiry and composition
startup idempotence/failure. Expanded paused-operation testing to suppress disable,
delete and retry as well as duplicate Save. The accessible next-occurrence field
now retains its spoken date value alongside its label. Remaining uncovered paths
are classified in TEST_MATRIX.md. Gate 6 remains pending current full CI.
Run 37396765469 at 5445276 passed the core and 38 iOS unit/integration tests,
and seven of nine UI tests. The menu-label button was also not hittable; identifier
selection fixed Keep Alarm and the full delete flow passed. Replace the menu with
explicit native Add Math / Add Memory / Add QR Code actions, removing each option
once selected. This improves direct accessibility and preserves uniqueness and
ordering; the UI tests still configure, save, relaunch and verify exact settings.
Run 37725353411 validates that correction plus the completed behavioral audit.