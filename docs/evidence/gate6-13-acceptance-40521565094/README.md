# Ordered replacement acceptance through Gate 13 — PASS / STOP

Frozen tested candidate: **`f01abf42c7b4e7a7ed10bb926bb736ebaa8e77bc`**.
[Run 40521565094](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094),
push, attempt **1**, completed **SUCCESS**. Three standard public `macos-26` jobs;
every required assigned step passed. Matrix-only declarations skipped in the other
lane are intentional partitioning, not omitted coverage. All validate steps passed.

[Owner authorization and pre-execution scope](../../GATE6_13_ACCEPTANCE.md).
The immutable SHA was recorded in [candidate.json](candidate.json) before its sole
validation push. Local/remote starting HEAD was 55695fd; both exact baseline runs
were SKIPPED. The candidate's other workflow, reset run 40521565633, was SKIPPED.
There was no duplicate runner allocation, rerun, repair-and-rerun, extra tap, new
probe or historical diagnostic allocation. Product/Core/native/UI source and
assertions are unchanged from the completed replacement/retained Stage 13 baseline.

## Evidence and current gate statuses

| Evidence class / gate | Result at the frozen SHA |
| --- | --- |
| Source / local Windows | Reviewed workflow selectors/order/branch guards, unchanged product/Core/native/UI source. Four mocked wrapper test methods (all three budgets, original failure/no retry, expired budget/no start, deadline termination/preservation) PASS; YAML/source invariants PASS. Initial sandbox temp access failed before wrapper execution; unchanged checks passed with normal temp access. |
| Xcode / build | Xcode 26.6 / 17F113, Swift 6.3.3, macOS 26.6.2, iPhone 17 / iOS 26.5 Simulator. Reproducible XcodeGen/package, Debug/Release builds, installed public SDK declarations, built usage descriptions, generated audio/resources, Release fixture exclusion PASS. No compiler/destination warnings; existing metadata advisory retained, plus original Actions runner/Node advisories. |
| Gate 6 replacement / management | PASS: 37 owner/input/draft/persistence contracts; ten ordinary list executions; independent cold editor once (233.839s); full eleven-declaration management replay before downstream suites. Original exact native values, one-action inputs, pending/error/status, recovery and save/reopen/relaunch assertions retained. |
| Gate 7 framework | PASS: challenge coordinator permutations, restoration and invalid progression. Core remains Foundation-only; coordinator has no platform/audio knowledge. |
| Gate 8 Math | PASS: focused Core, two application declarations, original UI flow. |
| Gate 9 Memory | PASS: focused Core, three application declarations, two UI declarations. |
| Gate 10 QR | PASS: focused Core/owner, five application/scanner declarations, three UI declarations. Actual optical camera behavior DEVICE REQUIRED. |
| Gate 11 audio | PASS: reproducible resources, SDK/Release compilation and usage descriptions, six audio declarations; management preview lifecycle coverage retained. Actual alarm playback DEVICE REQUIRED. |
| Gate 12 routing | PASS: focused Core routing, seven native plus two UI declarations, compiled real App Intent integration. Actual OS launch DEVICE REQUIRED. |
| Gate 13 A–J | PASS: all ten unchanged OrchestrationIntegrationTests declarations, after Gate 12. All repeat successfully in full regression. G/H use acknowledgment loss and fresh disk owners; no physical kill/power-loss claim. |
| Full regression | PASS: **148 Core tests in six suites, 79 native tests, 20 UI tests**. Focused/repeated cases are not added to these unique full-suite counts. Core coverage 2266/2279 lines (99.43%); exact uncovered-line and application behavior reports PASS; no arbitrary 100% inference. |
| Final checks / preservation | PASS: coverage, Release fixture exclusion, complete diagnostics, eleven original screenshot attachments exported, all six artifact uploads. Original ZIP digests match Actions; ZIP CRC checks PASS. |
| Physical device | **DEVICE REQUIRED / NOT RUN**: real AlarmKit/Stop/Solve delivery, backups, lock/first unlock, hardware input, camera/audio, provisioning and reliability remain unaccepted. |

Gates **6–13 PASS in this owner-authorized automated/Simulator acceptance scope**.
Earlier holds are superseded only for this replacement candidate and this scope.
Historical failures/evidence remain preserved, causes unknown, diagnostic budgets
EXHAUSTED and historical-risk exception REVOKED. This pass does not invoke that
exception or establish historical root cause. No main promotion or product/device
reliability claim. Stage 14 and UX work are not started or queued. **STOP.**

## Bounded accounting

| Job | Actual including setup/preservation | Ceiling | Last bounded command, from actual job start |
| --- | --- | --- | --- |
| list 122249755370 | 16m49s | 40m | 16.344m |
| independent editor 122249754681 | 10m39s | 25m | 10.224m |
| ordered validate 122259592256 | 73m18s | 85m | 72.170m |

First budget steps were 2/2/3 seconds after allocation; every bounded command exited
zero before its fixed +34/+19/+79-minute deadline. See [budget audit](budget-audit.json),
[jobs/steps](jobs.json), [reviewed invocation summary](reviewed-summary.json) and
original per-lane command JSON/logs under `list/`, `editor/`, `validate/`.
The list's contracts finished at 7.17 minutes and ten-list at 16.30 minutes from its
first budget step. No allowance rollover or unused-job claim; all three allocations
are consumed and the single attempt is closed.

## Original preservation, integrity and limits

Git preserves full original [list](list-actions.log), [editor](editor-actions.log)
and [validate](validate-actions.log) Actions logs; run/jobs/steps/artifact metadata;
all wrapper command bodies/logs/records; toolchains/ordinary fixture journals; the
four small original ZIPs. [Integrity manifest](integrity.json) records full SHA-256,
original byte sizes and exact expiries for all six ZIPs.
Archive attributes disable newline conversion for original logs/JSON/command
bodies/ZIPs. Original log whitespace is preserved; authored Markdown passes the
whitespace check separately.

| Original Actions artifact | Bytes | Preservation |
| --- | --- | --- |
| [acceptance-list 12741304861](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12741304861) | 78,892,628 | Original ZIP and extracted xcresults local; Actions expires November 26 UTC |
| [acceptance-editor 12742801440](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12742801440) | 3,233,308 | Original ZIP in Git and local; Actions expires November 26 UTC |
| [native results 12749101800](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12749101800) | 459,854,793 | Original ZIP and all extracted xcresults local; Actions expires November 3 UTC |
| [QR results 12748872154](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12748872154) | 1,178,965 | Original ZIP in Git and local; Actions expires November 3 UTC |
| [validation logs 12748557256](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12748557256) | 189,700 | Original ZIP and extracted originals in Git/local; Actions expires November 26 UTC |
| [legacy gallery 12749151485](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40521565094/artifacts/12749151485) | 1,248,134 | Original ZIP in Git/local; Actions expires November 26 UTC |

Local originals and extracted results are under
`C:\Users\Teej\Desktop\Puzzle Alarm\TestResults\Gate6Through13\`.
The single-path QR artifact flattens its package root; restore its files into a
folder named `QR.xcresult` (also prepared locally). The original ZIP is unchanged.
The two large ZIPs are **not in Git**; preserving those original result bundles
after Actions expiry depends on retaining this local directory or copying it.
The full durable logs/metadata/command evidence in Git do not expire with Actions.
No claim that all raw xcresults are durably Git-published is made.

Known optional-gallery limitation: its unchanged legacy exporter still prints an
obsolete `application_source_commit`/baseline link and “Stage 12 has not started”
label. Preserve this original artifact without repair; those labels are not
acceptance evidence. Its `capture_commit` is the actual frozen SHA. Authoritative
tested source/run identity is candidate.json plus Actions run/job metadata above.
No visual design or UX acceptance is inferred from the exported screenshots.

Evidence-only publication is a documentation descendant of the tested SHA, uses
`[gate6-diagnostic] [record-only]`, and changes no product/test/workflow source.
Its exact SHA and skipped CI are reported separately at publication; they are not
a newly validated product revision. Remote main remains
`bd069f29c6d045d5bc27fc56212edcbde2090855`, unpromoted.
