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
| Disk persistence / atomicity / disk failures | AUTOMATED / SIMULATOR PASS | Stage 4 evidence below; real disk and injected interruption tests |
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

## Gate 4 — final implementation PASS

Revision: 40501452d1aaf7e7e3fa03ba54d153574d560fde
[Actual final implementation CI](https://github.com/teejayishere/PuzzleAlarm/actions/runs/37144990239).

- Total: 66 distinct tests (57 core, eight iOS unit/integration, one UI).
- Persistence: 32 tests (31 core, one iOS Application Support integration).
- Core coverage: 771/777 production lines = 99.23%.
- Four additional adversarial checks above passed; concurrent losers specifically
  report conflicts. Source/test assertions were not weakened.
- Production persistence, AlarmKit and AppIntents compile; all Gates 0–3 regressions
  pass in the same run, with no compiler/destination warnings.
- The known UI-test metadata advisory remains documented and unchanged.
- Earlier gates invalidated: none. Stage 5+ NOT STARTED.

Subsequent documentation-only revisions also run the complete workflow.
Acceptance of the current checkout requires its matching successful GitHub run;
this named run is the immutable evidence for the final implementation.

## Coverage audit — baseline 771/777, six missing line counts

Baseline source: cdd45d57477d8f2cbc492dbc9535ff76a28f8ecf.
Raw evidence (same production sources): a5f7a28385141accf9e3131a788f5c2257f81982,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181404906.
LLVM LCOV merges source lines and lists four zeros; SwiftPM's JSON also counts
two uncalled nil-coalescing autoclosures as separate uncovered line counts.
This accounts for all six, without confusing line coverage with branch coverage.

| Baseline location/function | Behavior | Classification and disposition |
| --- | --- | --- |
| DiskRepository.swift:23, applicationSupportDirectory | Throw when Foundation returns no user Application Support URL | PLATFORM-DEPENDENT. No production injection seam for the system search-path result. Normal macOS and iOS lookup and real read/write failures are tested. Track unavailable storage/file protection under platform/device integration; do not swizzle Foundation for a coverage number. |
| RepositoryState.swift:20, AlarmOwnership.isPrimary | Derive primary versus backup from persisted ordinal | CRITICAL BEHAVIOR. Add restored-ledger regression verifying exactly one primary/four backups, stable IDs/owners, and a detached ordinary primary. |
| Scheduling.swift:16, ScheduleContext.calendar | Reject a timezone that disappears after successful validation | DEFENSIVE/UNREACHABLE BRANCH under a stable timezone database. Immutable context init and decode reject unknown identifiers before calendar construction. No unchecked context or broad mock added; platform database replacement remains an environmental limitation. |
| Scheduling.swift:55, OccurrenceCalculator.next | Throw when no occurrence exists within the search horizon | CRITICAL BEHAVIOR. Not safely dismissible as unreachable: skipped-date regression exposed the seven-day assumption. Recurse to Stage 1 and fix the horizon, then replay dependent gates. |
| WakeUpSession.swift:200, finalizeCompletion | Nil fallback to wake date when deriving last challenge success timestamp | DEFENSIVE/UNREACHABLE BRANCH. Prior full-sequence guard plus nonempty challenge-required configuration guarantees last exists. Existing malformed-completion tests prove rejection; new terminal-reload late-event regression protects idempotency without manufacturing an invalid session. |
| WakeUpSession.swift:262, validate | Same nil fallback while validating a completed session's timestamp | DEFENSIVE/UNREACHABLE BRANCH. Earlier decode validation requires the full nonempty sequence. Corrupt missing/empty challenge completions already fail before this line's autoclosure. No test bypasses the invariant. |

No coverage threshold changed; no production code removed merely to raise coverage.
Zero-count inline regions also appear on covered lines; the retained JSON evidence
makes clear that 99% line coverage is not exhaustive branch coverage.

### Reproduction and correction pending full validation

Regression-only revision: 1356491831105c34768d56632a122d4a83e25a96.
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37181948057
Actual failure: weeklyOccurrenceSurvivesSkippedLocalCalendarDate throws
"No occurrence found in calendar horizon"; other 59 core tests pass.
Earliest affected stage: 1; Gates 1–4 invalidated pending complete replay.
Samoa skipped Friday 2011-12-30 (IANA historical timezone data:
https://lists.iana.org/hyperkitty/list/tz%40iana.org/2011/9/?count=10&page=8).
A Friday alarm after the prior Friday must advance to 2012-01-06 local, not fail
or silently select Saturday. Search two weekly cycles to allow an omitted weekday.
Keep the fail-closed fallback for unsupported calendar outcomes. Stage 5 not started.

### Coverage audit — corrected implementation PASS

Revision: b9c87ab56df0e0e7928578d978d1c03304faa5ce
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37182114469
60 core + eight iOS unit/integration + one UI = 69 tests PASS.
Persistence: 32 core + one iOS = 33. Coverage: 774/779 (99.36%).
The primary-role getter is now covered. The two added source comments also appear
in LLVM's line-region denominator; coverage was not the reason for those comments.
Remaining five counts: DiskRepository:23; Scheduling:16 and now :57;
WakeUpSession:200 and :262 autoclosures. Platform/unreachable justifications remain
as above. The horizon fallback is retained after the real recurrence defect was
fixed and meaningfully tested; no injected calendar failure just to make it execute.
Gates 1–4 restored after full replay; Gate 0 also rechecked. Stage 5 NOT STARTED.
No threshold changed. Final documentation-only acceptance requires exact-HEAD CI.

## Stage 5 acceptance matrix

Stage 5 adds deterministic lifecycle tests plus two iOS composition/translation
tests. Parameterized cases count as one Swift Testing test declaration in the
reported totals; focused reruns are not counted twice. Final evidence is recorded
in PROJECT_STATE.md and the final acceptance entry in DEVELOPMENT_LOG.md.

| Requirement | Meaningful evidence |
| --- | --- |
| Five-alarm transaction | LifecycleTests checks ID/date order, durable inFlight at each effect, no premature armed/completed state, and final five acknowledgments. |
| All five failures / rollback | Parameterized failures at positions 1–5 include an OS side effect followed by an error; assert exact cancellation IDs, empty OS state and retained five-entry ownership. Cancellation errors must not stop siblings. |
| Every external-effect crash window | LifecycleRecoveryTests restores partial plans at positions 0–5, all acknowledgments before arming, missing/present inFlight IDs, failed acknowledgment writes, partial cancellation and failure after actual OS removal. |
| Missing / failed / stale snapshots | Snapshot errors propagate; known missing alarms do not solve challenges; unknown owned IDs are reported; stale terminal positives do not repeat cancellation. |
| Recurrence | Ordinary weekly uses one ID without sessions; challenge completion creates one successor only after cleanup. Calendar tests cover midnight, month/year, DST and Pacific/Apia's skipped local date. |
| One-time | Fixed ordinary occurrence and challenge terminal consumption disable the definition; repeated startup/enable cannot silently rearm. Deadline crossing during storage or OS awaits is tested. |
| Enable / disable / delete | Both modes, repeated commands, partial cleanup, write failure before/after effects, retained ownership, deferred active deletion, tombstone ID reuse rejection. |
| Edit / mode change | Seven cases cover time, weekdays, sound, challenge settings/order and both mode directions. Assert new target healthy before old retirement, old preserved on replacement failure, stable retry IDs, active snapshot isolation. |
| Ringing protection | Already-alerting snapshots protect a session even before the local clock reaches its date; alerting during replacement blocks old retirement without cancelling the healthy new target. |
| Conflicts / await races | Bounded three-attempt CAS; unrelated writes merged; newer definitions and operation generations preserved; reentrant commands rejected; snapshots refreshed after intent writes. |
| Schema / corruption | Schema-1 upgrade, schema-2 journal requirement, invalid operation ownership/status and duplicate UUID rejection before effects; all existing persistence corruption/atomicity tests rerun. |
| Domain completion | Degraded state preserves scheduling history; active/completed guards, late scheduling/cancellation acknowledgments and full challenge sequence requirements remain enforced. |
| Platform | Production disk + coordinator + injected AlarmManagerService integration, native recurrence/presentation/sound translation, original seven capabilities, disk integration and native shell launch. |

### New coverage gaps investigated

The first passing expanded run (6924c81, run 37208755043) had 107 core tests and
1800/1848 lines (97.40%). The audit prompted behavioral regressions for duplicate
create, partial acknowledged-chain disappearance, final-snapshot disappearance,
elapsed planned and ordinary inFlight occurrences, scheduling-failure/crash state,
future degraded rollback, completed rollback with pending journal, missing ordinary
ownership, and cancellation throwing after OS removal. The cleanup loop was
corrected so a single recovery pass does not make redundant cancellation attempts.

Passing c48aeb7/run 37209286645 had 117 core tests and 1835/1852 (99.08%).
Inline-region inspection, not just whole-line coverage, then prompted tests for
deleted identity reuse, weekly retries after their original date, unknown commands,
ringing protection (including during replacement), generation supersession, and
invalid late domain acknowledgments. No test fabricates an impossible valid state
or merely asserts execution.

Remaining locations below refer to the Stage 5 production sources (unchanged by
the final test-only revisions). SwiftPM counts closure regions independently,
whereas LLVM LCOV merges line numbers; these are different denominators.

| Location / behavior | Classification / justification |
| --- | --- |
| AlarmLifecycleCoordinator.swift:30, default clock closure | NON-MEANINGFUL COVERAGE. Production delegates directly to Date(); deterministic behavioral tests inject their clock. |
| AlarmScheduling.swift:31, request for ID outside session plan | ERROR/RECOVERY BEHAVIOR. Already tested by the iOS capability suite using the shared production request type; core-only coverage excludes that executable. Do not duplicate solely for percentage. |
| DiskRepository.swift:23, no Application Support URL | PLATFORM-DEPENDENT. Foundation environment lookup has no realistic injected failure; normal lookup, real I/O errors and iOS disk integration are tested. Device storage/file protection remains required. |
| LifecycleEffects.swift:228/235, session/ownership lookup absent | DEFENSIVE/UNREACHABLE BRANCH within the supported single lifecycle owner. Validated journal/ledger references supply these IDs and history is retained. Invalid ownership is rejected at repository boundaries; helpers do not invent records. |
| LifecycleOperation.swift:89, absent detached record during update | DEFENSIVE/UNREACHABLE BRANCH for validated targets and retained history. No public command removes ownership before acknowledgment. |
| LifecycleRecovery.swift:175, journal target session absent | DEFENSIVE/UNREACHABLE BRANCH after repository validation. Corrupt journal references are tested as rejected input. |
| LifecycleRecovery.swift:179, failed target with neither target ID | DEFENSIVE/UNREACHABLE BRANCH for coordinator-produced failed scheduling operations: allocation persists a target before any effect/failure outcome. Keeping empty cleanup safe does not authorize creating or deleting anything. |
| Scheduling.swift:16, validated timezone becomes unavailable | DEFENSIVE/UNREACHABLE BRANCH with stable system timezone database. Init/decode reject invalid zones. |
| Scheduling.swift:57, no date in two-week search horizon | DEFENSIVE/UNREACHABLE BRANCH for tested supported Gregorian dates/zones. Retained fail-closed fallback after the real Apia defect was fixed and regression tested; no fabricated calendar to inflate coverage. |
| WakeUpSession.swift:200/282, nil last-success fallback closures | DEFENSIVE/UNREACHABLE BRANCH. Nonempty full sequence validation precedes completed state; malformed completion and terminal replay are tested. |

Additional zero-count inline guards were reviewed:
- DiskRepository's coordination-error/missing-callback guards and failed removal
  of an interrupted-write marker are PLATFORM-DEPENDENT. Real write/read failures,
  interruption detection and preservation are covered; no Foundation swizzling.
- LifecycleEffects' active early return duplicates ensureTarget's active guard
  (DEFENSIVE/UNREACHABLE through public commands).
- Token checks in failure/final-retirement and allocation's already-target guard
  are defensive against unsupported competing journal writers. Generation
  supersession is tested through the public scheduling path; ordinary parent
  edits/conflicts are independently tested. No claim of multi-process OS atomicity.
- Allocation's disabled-definition nil occurrence is defensive: disabled parents
  use retirement actions, and checkedOperation rejects a changed parent.
- Internal updateSession's missing-ID guard is defensive under the same validated,
  retained-history invariant. Public unknown-parent/operation commands are tested.
- Scheduling's calendar calculation and missing-primary inline guards are
  defensive for validated Gregorian inputs and a validated five-entry plan.

The existing meaningful-coverage policy is unchanged. The final percentage is
evidence of exercised lines, not a claim of exhaustive branches or device behavior.

### Test quality and recursive final review

Five principal remaining risks and their evidence:
1. Disk/OS disagreement after process death: persisted phase matrices, injected
   acknowledgment failures and before/after-effect OS failures assert stable IDs.
   Real daemon freshness and power loss remain device work.
2. Replacement cleanup destroying a healthy target: assert exact old/new sets,
   retry behavior, both mode changes and ringing during the replacement await.
3. Stale writers overwriting intent: CAS conflicts preserve unrelated/newer data,
   bounded conflict exhaustion throws, and superseded generation stops old work.
4. Completion or recurrence bypass: due missing/degraded sessions retain challenges,
   failed cleanup blocks completion/next occurrence, repeated one-time recovery
   cannot create another occurrence.
5. Ownership ambiguity: malformed/duplicate journals fail before OS calls; foreign
   and orphan IDs are untouched; retained history prevents identity reuse.

Most damaging prior assumption: missing AlarmKit presence could invalidate the
historical schedule acknowledgment and accidentally bypass a due session.
Stage 1 was corrected to retain acknowledgments in degraded state; domain,
persistence and lifecycle regressions directly exercise that assumption.
All dependent gates require current replay, not the original Stage 4 run.

The fake records requests/IDs/effects and injects errors, including errors after
effects. It does not implement occurrence calculation, rollback or reconciliation.
Assertions would fail for wrong order, early arming, stop-on-first-cancel-error,
duplicate schedules, foreign cancellation, overwritten state or non-idempotent
recovery. Mock and Simulator evidence does not prove real AlarmKit delivery.

### Final Stage 5 implementation evidence

8118e44dc007143813edf668cca223459cd97b88:
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37236486724 — SUCCESS.
123 core + 10 iOS unit/integration + one shell UI = 134 distinct tests.
New Stage 5 work: 65 tests including the two Stage 1 recursion regressions.
Core: 1840/1852 (99.35%). Ten merged uncovered source lines plus the two
WakeUpSession completion autoclosures account for all 12 missing counts.
All prior gates pass in this same run. Final documentation HEAD must also pass.
No numeric/meaningful coverage threshold was lowered.

## Stage 6 test matrix — pending actual full-gate results

Prior 123 core tests and 10 platform unit/integration tests are preserved. The
existing shell-launch test evolves to verify the real list/empty state using injected
effects. New tests must pass alongside these before Gate 6 acceptance.

| Area | Test evidence under validation |
| --- | --- |
| Draft/domain boundary | AlarmEditorDraftTests: new one-time state/defaults, edit round trip/identity, challenge uniqueness/order/QR stability, configured Math/Memory and ranges, wall-clock conversion, sound/repeat labels. |
| Application CRUD | AlarmStoreTests: create/edit/enable/disable/delete through the real coordinator, stable owner, explicit fixed context, deterministic sorting. |
| Authorization | Injected four-state mapping, no startup prompt, intentional request, denied save without OS effects, revoked-access refresh removes healthy claim. |
| Honest failure/retry | Failed scheduling retains configuration and stable retry ID; snapshot failure marks status unconfirmed; failed delete retains ownership; one-time cleanup retry never rearms. |
| Storage safety | Missing vs committed empty, corrupt/future-schema rejection, write failure before OS effect, failed acknowledgment after OS success, recovery without duplicate scheduling. |
| Concurrency/staleness | Paused external effect tests duplicate Save suppression and coalesced foreground refresh; stale expected-original save cannot overwrite newer configuration and explicit reload succeeds. |
| Protected sessions | Store deletion preserves active session and all challenges; no completion/control API in product views. |
| UI create/persistence | Empty → time/weekday/mode/sound → Save → row → actual process relaunch. |
| UI challenge configuration | Memory/Math/QR → configure → accessible reorder → Save → relaunch → exact order/settings restored. |
| UI mutations/errors | Enable failure → needs attention → Retry → healthy; off/on; identity-preserving edit; confirmed/cancelled delete; failed cleanup keeps row. |
| UI one-time/authorization/accessibility | Empty weekdays remain Once after relaunch, Cancel discards draft, injected permission states, large-text toolbar controls. |
| Release | Separate Release compile; executable scan rejects DEBUG UI-test switch/fake scheduler/storage marker. |
| Coverage | Unchanged core report plus separate xccov application-behavior report. No arbitrary SwiftUI-body line target. |

All app tests use real AlarmLifecycleCoordinator. External effects are the fake
boundary; some unit tests seed legitimate persisted phases to test recovery.
No real AlarmKit prompt, scheduling, sound, camera or physical device is required
by UI tests. Fixed date/context and isolated durable test directories keep relaunch
behavior reproducible. Test switches compile only in DEBUG.

### Stage 6 self-review / adversarial findings

- Most damaging UI misunderstanding: enabled is only intent. Status requires a
  successful report and healthy persisted ownership; errors remove certainty.
- Cancel discards draft only; a Save that already persisted state is reported as
  saved-with-attention, not rolled back by dismissing the sheet.
- Superseded drafts require explicit reload; successful partial-save adoption uses
  the full authoritative definition, including any one-time disabled state.
- One-time next date uses durable ownership, never a newly calculated tomorrow.
- Cleanup retries remain available for disabled/deleting one-time definitions,
  while consumed one-time scheduling does not automatically restart.
- Conflicting controls are disabled during async work and the store independently
  suppresses duplicate actions. Foreground refresh is bounded/coalesced.
- Code inspection finds no view repository writes, direct AlarmKit effects or
  challenge completion actions. DEBUG fixtures are isolated from Release.
- Device-only uncertainty (snapshot freshness, real access prompt, intent delivery,
  sound and file protection) remains separate from these tests.

Gate 6 is PENDING current exact-HEAD full CI and final uncovered-behavior audit.
