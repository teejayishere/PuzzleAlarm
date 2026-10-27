# Single ordered replacement acceptance attempt

Authorized October 27, 2026 (America/Chicago) by the owner's task instruction.
This separately authorizes acceptance validation of the completed Gate 6
replacement and retained Stage 13 implementation. It does not invoke the revoked
historical-risk exception or reopen either exhausted historical diagnostic budget.
No feature development, new probe, extra input, repair-and-rerun or retry-to-green.

## Baseline and freeze

Started clean on `codex/gate6-controlled-reset`, local/remote
`55695fd7acdaec5642e5642137a6ded6e1c911c0`. Read PROJECT_STATE first, then the
controlled-reset decision and relevant plan, test, architecture, source/workflow
sections. Exact baseline runs 40452342842 (ordinary) and 40452342771 (reset)
are completed SKIPPED, attempt 1; neither is PASS. Main independently remains
`bd069f29c6d045d5bc27fc56212edcbde2090855`.

Preparation changes only acceptance CI wiring, its deadline wrapper and records.
Product/Core/native/UI sources and all valid assertions are preserved. The obsolete
NativeAlarmSwitchTests selector is replaced with all AlarmEnabledInputTests plus
the original retained-binding/completion and adapted pending/outcome contracts in
AlarmStoreTests, AlarmEditorDraftTests and PersistenceIntegrationTests. Equivalent
behavior rationale remains in GATE6_CONTROLLED_RESET and TEST_MATRIX.

Before any validation push, record the immutable candidate SHA locally in
`TestResults/Gate6Through13/candidate.json` and report it in the chat. That SHA is
frozen for the entire execution. Its one push uses `[gate6-acceptance]` and no reset
or diagnostic marker. The reset workflow requires its different explicit marker;
the diagnostic workflow excludes this branch. Ordinary CI permits this branch only
for the marked push, preventing a parallel PR/dispatch acceptance run. Record-only
preparation/publication skips every runner. No main promotion.

## Frozen validation scope and ordering

One attempt, at most three free standard `macos-26` jobs, with existing job ceilings
40/25/85 minutes including setup/preservation. Tooling failure consumes allocation.
Absolute command deadlines at first-step +34/+19/+79 minutes reserve six minutes
for termination and preservation; first-step overhead is separately audited against
actual job timestamps. No budget rollover or extra jobs. Only one attempt is allowed.

1. Fail-fast list lane (40): all 37 focused owner/input/draft/persistence contracts,
   then exactly ten original ordinary list flows with stop-on-first-failure.
2. Independent cold editor lane (25): original editor declaration once, including
   its original repeated inputs and On/Off save/reopen/relaunch checks. No warming.
3. Dependent validation lane (85), starts only after both prerequisite lanes pass:
   reproducible project/package, Core build/persistence/lifecycle prerequisites,
   Debug build, all replacement owner contracts and full Gate 6 management UI;
   Gate 7 coordinator; Gate 8 Math Core/application/UI; Gate 9 Memory
   Core/application/UI; Gate 10 QR Core/application/scanner/UI; Gate 11 reproducible
   audio/resources, public SDK inspection, Release build, usage descriptions and
   audio tests; Gate 12 Core routing and real App Intent/native/UI routing; Gate 13
   unchanged disk/application integration A–J. Then full Core and full native/UI
   regression, coverage/uncovered-line reports, Release fixture exclusion,
   diagnostics, resource/build checks and existing visual evidence export.

Within each job, share DerivedData. After the first coverage-enabled test build,
use test-without-building for later focused/full invocations with identical Debug
coverage settings. No required declaration is excluded. Full regression intentionally
repeats previously passed declarations; it is not a retry of any failed declaration.

On any required failure: fail-fast cancels the sibling prerequisite lane, the
dependent lane cannot start, and an observed later failure stops all later steps.
Cancel remaining validation if any remains. Always preserve available original
logs/results, metadata and digests. Classify only what evidence establishes;
recursively invalidate from the earliest affected prerequisite and STOP. No repair.

## Closeout policy

Archive original Actions run/attempt/jobs/steps/logs and artifact hashes, preserving
available xcresults and explicit retention limits. Record source, local automated,
Xcode, Simulator and physical-device evidence separately. Distinguish the tested
SHA from evidence-only publication SHA; record-only skipped CI is not product PASS.
Gate status reflects only completed ordered checks at the frozen SHA. Device
acceptance remains DEVICE REQUIRED / NOT RUN. No Stage 14, UX work, main promotion,
historical-cause assertion or device-reliability claim. STOP after attempt/closeout.
