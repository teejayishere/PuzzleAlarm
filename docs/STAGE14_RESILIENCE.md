# Stage 14 resilience / failure injection

## Result — BLOCKED / NOT ACCEPTED / STOP

Frozen tested `62c8953fdcd915ebdac8cb5838799e0b2f64389e`, run 40564260790,
attempt 1 FAILURE. Gate 6 original list input assertion failed on iteration 1;
37 native contracts PASS, editor CANCELLED without result, validate SKIPPED.
**Gate 6 FAILED / HELD; Gates 7–14 INVALIDATED / HELD; last unheld gate 5.**
New tests compiled but were NOT EXECUTED. Cause unknown, historical diagnostic
budgets EXHAUSTED, exception REVOKED. No further investigation, repair or execution.
[Original evidence, allocation, hashes and preservation limits](evidence/stage14-40564260790/README.md).
Physical device NOT RUN. No Stage 15/UX/main promotion. STOP after record-only
closeout. The audit and pre-execution contract below remain the frozen preparation
record; their pending statements are superseded by this result.

Authorized October 27, 2026 by the owner's Stage 14 task. Stage 14 only;
stop after Gate 14 PASS or a documented blocking failure. No Stage 15, redesign,
main promotion or physical-device acceptance. Historical diagnostic budgets remain
EXHAUSTED; the historical-risk exception remains REVOKED.

## Verified baseline and status reconciliation

Started clean at local/remote `codex/gate6-controlled-reset`
`2cb81a6e89698e7e13887f4038fcc83afa793174`, then created fresh
`codex/stage-14-resilience` preserving that history. Public GitHub REST independently
confirmed run 40521565094, attempt 1, SUCCESS at accepted source
`f01abf42c7b4e7a7ed10bb926bb736ebaa8e77bc`; all three jobs and required steps
were independently checked through the GitHub connector. Exact baseline publication
runs 40538097946 / 40538098077 are SKIPPED, not new product PASS evidence.
The intervening commit changes only records/evidence. Main remains
`bd069f29c6d045d5bc27fc56212edcbde2090855`.

[Immutable Gates 6–13 acceptance](evidence/gate6-13-acceptance-40521565094/README.md)
supersedes the earlier failed/held candidate statuses only within its automated/
Simulator scope. Older “Stage 13 pending”, “Stage 14 not authorized” and STOP text
describes prior tasks; it does not override the accepted replacement or this new
Stage 14 authorization. Historical failures, unknown causes, exhausted budgets and
device requirements stay recorded. No reliance on the revoked exception.

## Audit before additions

| Injection | Existing meaningful coverage retained | Recovery contract |
| --- | --- | --- |
| Disk read | PersistenceTests realDiskReadFailureIsNotMissing / realFilesystemWriteAndReadErrorsAreSurfaced; LifecycleRecoveryTests snapshotFailureAndCorruptStorageCannotProduceEmptySuccess | Propagate failure; never adopt empty success or issue effects from unreadable state. |
| Disk write | PersistenceTests diskFailedWritePreservesPriorDocumentAndReportsInterruptedWrite / interruptedInitialWriteNeverLooksLikeEmptyRepository; AlarmStoreTests pre/post-effect failures; MathStoreTests, MemoryStoreTests, QRStoreTests failed submissions | Prior committed bytes/progress remain authoritative. No completion acknowledgment before durable progress. |
| Scheduling | LifecycleTests eachScheduleFailureRollsBackIncludingUncertainSuccessfulSideEffect (all five positions); LifecycleRecoveryTests disappearanceAfterLastAcknowledgmentPreventsArming; OrchestrationIntegrationTests B/H | Persist intent before effects, roll back uncertain successes, never claim armed until all required siblings are confirmed. Explicit retry reuses identity. |
| Cancellation | LifecycleTests rollbackContinuesAfterCancellationFailureAndRetryUsesOriginalIDs; LifecycleCommandTests acknowledgment loss; OrchestrationIntegrationTests F/G | Continue remaining IDs, retain cleanup failure, defer successor until cleanup, recover using inventory without repeating acknowledged effects. |
| Duplicate callbacks | QRStoreTests duplicate/pending/stale scanner tests; Math/Memory stale identity tests; WakeUpRoutingTests concurrent entry; OrchestrationIntegrationTests D/F | Reject stale identity; one progress advance, one cleanup sequence. |
| Lifecycle interruption | LifecycleRecoveryTests restart after each schedule / cancellation crash windows; MemoryStoreTests scene hiding and owner contention; OrchestrationIntegrationTests G/H | Fresh owner resumes durable identity/checkpoint/journal. These simulate acknowledgment loss; they do not prove process-kill behavior. |
| Malformed persistence | PersistenceTests malformedTruncatedAndInvalidConfigurationFailClosed / diskCorruptionIsRetainedAndCannotBeOverwritten; DecodingTests; RecoveryInvariantTests corruptPartialProgressCannotBeAcceptedDuringRestore; AlarmStoreTests corrupt/future schema | Reject invalid data without deletion, reset, false completion or invented ownership. Unsupported schema needs a compatible app. |
| Camera unavailable | QRStoreTests testScannerPermissionsLateCallbacksRetryAndInterruptionNeverSucceed; QR UI fixtures | Unavailable/interrupted attempt cannot solve; stop scanner and invalidate callbacks. User may explicitly retry after availability returns. Optical capture is device-only. |
| Audio resource | AudioTests missing/empty/corrupt/too-long files, player failure, route loss; resource reproducibility | Use default alarm sound without rewriting selection; preview failure stops playback and shows feedback. Actual alarm audio is device-only. |

Added only six missing boundary declarations:

- `ResilienceTests.testColdDiskReadFailureCannotClaimLoadedOrTouchExternalAlarms`: real unreadable state path at cold application load, retaining external IDs.
- `ResilienceTests.testWarmDiskReadFailureRetainsObligationAndRecoversWithoutEffects`: same real read fault after successful load; failed submission preserves obligation; removing the test fault recovers without scheduling/cancellation.
- `ResilienceTests.testRealDiskWriteFailureCannotCompleteOrCancelAndFreshOwnerCanRetry`: obstruct the real staging path at final QR commit; unchanged committed bytes/no cleanup; fresh-owner explicit recovery and duplicate callback check.
- `ResilienceTests.testMalformedDiskStateIncludingForgedCompletionCannotBeReplacedBySave`: truncated JSON, future schema, and forged terminal phase on an unfinished session, through real disk/application read and save paths; original bytes and external alarms remain.
- `QRStoreTests.testCameraLossBeforeQueuedSubmissionCannotCompleteAndNewAttemptCanRecover`: availability lost synchronously after payload queues work, before it runs; invalidate old callbacks and permit a new valid attempt.
- `AudioTests.testResourceLossAfterPreviewStopsPlaybackAndRecoveryKeepsSelection`: remove a previously valid resource, release preview, fall back, restore and explicitly retry without changing selection.

No product/Core/OS adapter change was needed by source review. No existing test or
assertion is replaced. No schema, public SDK signature, capability or UX change.
No percentage target or arbitrary 100% coverage goal.

## Frozen validation contract

One push-triggered attempt on this branch using `[stage14-validation]`; freeze its
exact commit in local `TestResults/Stage14/candidate.json` before push. At most
three free standard public `macos-26` jobs, existing ceilings 40/25/85 minutes,
absolute command deadlines +34/+19/+79 including setup. No additional diagnostic
allocation, rerun, failed-test retry, extra input, assertion weakening or omission.
Record-only closeout must skip runners and distinguish publication from tested SHA.

Retain the original prerequisite lanes (37 owner contracts + ten ordinary list
flows, independent cold editor), then the ordered validation lane: Core/persistence/
lifecycle, Gate 6 management, Gates 7–13 unchanged, focused Gate 14 (new disk suite,
all QRStoreTests and AudioTests), full Core and native/UI regression, coverage audit,
Debug/Release, SDK/resources/plists, fixture exclusion, diagnostics and preservation.
Gate 14 adds only focused selection and evidence preservation to ordinary CI;
existing gates/checks are retained in order. Current candidate validation PENDING.

Failure is evidence: stop later checks, preserve logs/results/metadata, identify the
earliest affected gate and recursively invalidate dependents. Proven defects recurse
under MASTER_PLAN §§4–6; exhausted historical input/editor diagnostics cannot be
reset. Required tooling/authentication/allocation failures are BLOCKED, never PASS.
Do not repair and replay an unexplained failure. No Stage 15 after success.

## Evidence classes

- Source: existing coverage audited; six boundary tests and CI wiring prepared.
- Local automated: YAML parse, required-step/order preservation, original test-body equality, product/Core/UI source equality and diff whitespace PASS. Four existing mocked absolute-budget/failure/no-retry checks PASS (0.071s). PyYAML was installed only in ignored TestResults tooling; no repository dependency change. No Swift toolchain on Windows.
- Xcode: PENDING at candidate HEAD.
- Simulator: PENDING at candidate HEAD.
- Physical device: DEVICE REQUIRED / NOT RUN. No alarm delivery, audible output,
  optical camera, hardware interruption, first unlock or reliability acceptance.
