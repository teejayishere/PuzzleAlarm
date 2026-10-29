# Stage 6 and later test migration ledger

Source reference: cfb37a86e63049f2f1326b8187f7d7fdf2d93ba2, retained unchanged
as ancestor of planning record 2b6463fa5212dc724c37ed532686308f9f5cc269.
All execution in this preparation is NOT RUN.

[Declaration inventory](GATE5_TEST_DECLARATIONS.csv) maps every XCTest test method
and Swift Testing @Test declaration in the preserved Core/native/UI source to
its real stage. [Source hashes](GATE5_TEST_SOURCE_HASHES.csv) retain SHA-256 per
test file. This is a static declaration inventory, not executed case totals:
parameterized Core cases and repeated UI executions do not inflate declarations.
Fixtures/helpers and the optional VisualDemoCapture helper are source dependencies,
not independent acceptance cases. Original source remains available at each CSV
source_url and through git show at the reference SHA.

## Prerequisite comparison

Rechecked exact 159b777 versus cfb37a8: no pre-existing Core test file changed.
No pre-existing Core production file changed except Models.swift's sound
selection comment. Added Core files are ChallengeCoordinator (Stage 7),
MathEngine/MathLifecycle (8), MemoryEngine/MemoryLifecycle (9), QREngine/
QRLifecycle (10), WakeUpRouting (12), with corresponding added tests.
This supports isolation, not a fresh Gate 5 compatibility or acceptance claim.
Core Model/Decoding/Session/Scheduling are Stage 1; persistence Stage 4;
lifecycle/recurrence/recovery Stage 5; Toolchain Stage 0. Native capability tests
belong to Stage 3 and native lifecycle composition to 5. Review later sound/
intent expectations against their 11/12 dependencies before adapting these files.
ShellLaunchTests originally checks the shell; its later management-empty/add
assertions are a documented Stage 6 extension, not grounds to delete shell coverage.

## Stage 6 native acceptance (37 preserved declarations)

| Source | Declarations | Migration/observation |
| --- | --- | --- |
| AlarmStoreTests.swift | 28 | Retain CRUD, one coordinator/context, failure/retry ID, stale/deleted edits, access/prompting, malformed/future state, protected sessions, real pre/post-effect persistence, stable sorting, uncertainty and coalesced refresh assertions |
| AlarmEnabledInputTests.swift | 2 | Retained/current owner/removal and busy-owner rejection, no pending leak/effects |
| AlarmEditorDraftTests.swift | 6 | Defaults/one-time, identity/time/sound roundtrip, unique ordered QR/configuration, Math/Memory range delegation, wall time and repeat labels |
| PersistenceIntegrationTests.swift | 1 | Real Application Support disk roundtrip with a fresh repository owner |

The first three AlarmStoreTests declarations explicitly exercise retained binding,
completion after denial/failure/success, and synchronous pending/outcomes, including
write failure/recovery. Preserve every assertion. Replacing AlarmEnabledInput
with store-owned admission requires API-only native-test adaptations:
construct/retain the production UUID binding and query the store receipt instead
of constructing a per-row pending owner. Command tests must still exercise
production admission, not a bypass. Preserve synchronous requested value/pending,
duplicate rejection, exact completion ordering, no OS effects before writes, and
all failure/status outcomes. Review the adaptation diff before implementation.

Add the four distinguishing admission/lifetime contracts in
[GATE5_STAGE6_DESIGN.md](GATE5_STAGE6_DESIGN.md); these are proposed obligations,
not tests already present or passed.

## All eleven management declarations

Every method below remains intact at the reference SHA, including the original
tap helper's enabled/hittable checks, concrete Switch 0/1 values, one control.tap,
bounded readiness and original exact outcomes. No helper edits are selected.

| Exact AlarmManagementUITests method | Real dependency / required observation |
| --- | --- |
| testEnableDisableAndFailureRetryAreHonest | Stage 6; ten ordinary executions, cold list lane; Off → one enable → enabled/Needs attention → explicit Retry → On → disable Off → enable On. Stop first failed execution; no extra taps |
| testEditorEnabledTogglePersistsAfterRepeatedNativeInput | Stage 6; independent cold editor once; starts persisted Off, eleven original local draft transitions, On save/relaunch, reopen, Off save/relaunch, same row identity |
| testDeniedNativeEnableReconcilesOffAndRemainsUsableAfterRelaunch | Stage 6; one rejected input, Off/exact 0, visible error, released pending/control enabled, Off after relaunch |
| testEmptyAddPersistsTimeWeekdaysModeAndSoundAcrossRelaunch | Stage 6; 8:30/weekdays/mode/selected Siren persisted and same row after relaunch; sound identifier selection does not require Stage 11 playback |
| testChallengeConfigurationOrderAndSettingsSurviveSaveReloadAndEdit | Stage 6 configuration; empty challenge save prohibited; Memory/Math/QR ordering, exact configuration values after save/reload/edit. No engine execution inferred |
| testEditChangesConfigurationWithoutChangingIdentity | Stage 6; 9:15/weekends/Math/Rapid Beeps, same UUID and single row after relaunch |
| testDeleteConfirmationCancelAndSuccessfulCleanup | Stage 6; Keep preserves editor, confirm cleanup removes definition and shows empty |
| testDeleteCleanupFailureKeepsAlarmVisible | Stage 6; error in editor, retained row and Cleanup pending after cancel |
| testOneTimeAndCancelDraftRemainDistinctFromDaily | Stage 6; cancel writes nothing; default Once persists and never claims Every day |
| testAuthorizationAndLargeTextControls | Stage 6; Not requested→Authorized, accessible large-text save/cancel, Denied exposes Settings without request |
| testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch | Stage 11; real preview lifecycle, selection/navigation/Home/reopen/cancel/relaunch and persisted Rapid Beeps. Preserve entire original; dependency-blocked on shell-only Stage 6 |

Ten list executions are repetitions of ONE declaration. Independent editor is ONE
declaration. Do not report twelve distinct methods or silently drop the other
nine. Stage 6 has ten applicable management declarations; the eleventh requires
audio. The historical complete all-eleven replay remains an outstanding obligation
until the owner resolves this scope boundary. Gate 6 equivalence to that replay
is BLOCKED if all eleven are required before later-stage restoration.
No Stage 11 product implementation is authorized by this preparation.

## Later-stage source and test obligations

| Stage | Preserved suites/source | Restore when dependencies exist |
| --- | --- | --- |
| 7 | Core ChallengeCoordinatorTests / ChallengeCoordinator | Permutations, persisted restoration, invalid progression |
| 8 | Core MathEngineTests, MathStoreTests, MathChallengeUITests / Math lifecycle/view | Exact problem/config identity, wrong/valid answer, persistence failures, sequence completion boundaries |
| 9 | Core MemoryEngineTests, MemoryStoreTests, MemoryChallengeUITests / Memory lifecycle/view | Show/hide, interruption, durable round/progress, stale callback and owner contention |
| 10 | Core QREngineTests/QRLifecycleTests, QRStoreTests, QRChallengeUITests / scan adapter, QR views | Exact payload/session identity, availability/permission, duplicate/pending/stale callbacks, no false solve |
| 11 | AudioTests and management audio method / sound catalog/preview/resources | Resource validation/default fallback without rewriting selection, preview stop/failure, route/interruption behavior |
| 12 | Core/native WakeUpRoutingTests and WakeUpRoutingUITests / intent/composition/destination | Due active obligation, stale hints, live owner, cold startup and foreground reassertion |
| 13 | OrchestrationIntegrationTests A–J / final-sequence handoff | All ten mandatory named A–J declarations retained; see declaration CSV |
| 14 | ResilienceTests plus two additions in QRStoreTests/AudioTests | All six compiled-but-unexecuted additions retained; earlier failure injection remains earlier prerequisites |

Stage 13 A–J: A all five/immutable occurrence; B partial rollback/uncertain success;
C stopped primary preserves backups; D intermediate challenge/stale callback;
E all final engine kinds/one successor; F cancellation failure/deferred successor;
G completion acknowledgment loss; H scheduling acknowledgment loss; I active edit
snapshot/future chain; J disable preserves obligation/prevents next occurrence.

Six Stage 14 additions, never counted passed:
- ResilienceTests.testColdDiskReadFailureCannotClaimLoadedOrTouchExternalAlarms
- ResilienceTests.testWarmDiskReadFailureRetainsObligationAndRecoversWithoutEffects
- ResilienceTests.testRealDiskWriteFailureCannotCompleteOrCancelAndFreshOwnerCanRetry
- ResilienceTests.testMalformedDiskStateIncludingForgedCompletionCannotBeReplacedBySave
- QRStoreTests.testCameraLossBeforeQueuedSubmissionCannotCompleteAndNewAttemptCanRecover
- AudioTests.testResourceLossAfterPreviewStopsPlaybackAndRecoveryKeepsSelection

Original tests are preserved, not removed from the later branch. Absence from the
Gate 5 checkout means dependency-held, not obsolete or passed. Restore each suite's
production dependencies and test fixtures under a later authorized stage; rerun
earliest affected prerequisites first. No Stage 7–14 implementation now.
