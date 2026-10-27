# Controlled Gate 6 replacement — focused PASS / STOP

Owner scope: [controlling decision](../../GATE6_CONTROLLED_RESET.md).
Frozen tested candidate: `8a236a03f0c19eb70863ddd7d290a70fb90efa73`.
[Run 40448988954](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40448988954),
push, attempt 1, completed **SUCCESS**. Both jobs and all required steps succeeded.
The pre-push exact-SHA declaration is preserved in `candidate.json`.
This is the focused replacement result, not broad CI or downstream acceptance.

## Evidence by layer

| Layer | Exact result |
| --- | --- |
| Source | Standard SwiftUI switches replace the custom UIViewRepresentable; one observable pending input owner reads live store state when idle; editor time wheel/input sections separated, explicit list button/sheet identity. Self/adversarial review recorded in decision. |
| Offline automated / Windows | Four mocked deadline-wrapper checks PASS; parsed workflow bounds/branch exclusions PASS. Initial sandbox temporary-directory access failure occurred before wrapper execution; unchanged checks passed outside that restriction. Zero macOS allocations for preparation. |
| Focused native automated | 37 tests PASS: 28 AlarmStoreTests, 6 AlarmEditorDraftTests, 2 AlarmEnabledInputTests, 1 PersistenceIntegrationTests. Retained-owner/removal, synchronous pending/duplicate/disabled input, denial, scheduling/write failure and recovery covered. |
| Xcode | Xcode 26.6 / 17F113, Swift 6.3.3, macOS 26.6.2. Debug app/native/UI targets compile. No compiler/destination warnings; one known SDK metadata advisory per lane. Release/full SDK/resource/fixture checks NOT RUN in this scope. |
| Simulator list | Original enable/disable/failure/retry declaration executed exactly ten times, all PASS; no failed iteration or retry-after-failure. |
| Simulator independent editor | Original declaration PASS once, 199.407s; eleven initial inputs, On save/relaunch/reopen, single On→Off, Off save/relaunch. |
| Simulator remaining management | Nine original declarations PASS: audio/selection/navigation/background/reopen, authorization/large text, challenge configuration, failed and successful delete/cancel, denied-input rollback/relaunch, edit identity, add/persistence, once/cancel. |
| Downstream / broad | Gates 7–13, full Core/native/UI regression and broad acceptance replay NOT RUN. Stage 13 orchestration source/tests retained and unaccepted. |
| Physical device | DEVICE REQUIRED / NOT RUN; no delivery, hardware input, lock/unlock, AlarmKit, camera/audio, provisioning or reliability acceptance. |

37 native + 11 distinct UI declarations = 48 distinct declarations in this focused
scope. The ten list iterations add nine executions, not nine declarations:
57 total case executions, all PASS. Original management UI/test-helper source is
unchanged. The removed bridge-specific test and adapted pending-state test have
documented rationale/equivalent coverage in the controlling decision and TEST_MATRIX.
No corrective extra taps, relaxed checks, generated probes or diagnostic waits.

## Bounded allocation and stop

Exactly one frozen-candidate attempt; two standard free macos-26 jobs allocated.
No rerun, repair-and-rerun or additional macOS job. Both allocations are consumed;
this task's attempt is CLOSED, no remaining execution queued.

| Job / invocation | Elapsed including setup or earlier work |
| --- | --- |
| list job 122006967041, complete including preservation | 30m26s |
| editor job 122006967297, complete including preservation | 10m9s |
| native contracts complete, measured from list first budget step | 6m56.462s |
| ten-list invocation complete, same absolute list budget | 16m11.272s |
| management invocation complete, same absolute list budget | 29m47.874s |
| editor invocation complete, measured from editor first budget step | 9m39.016s |

All invocation exits are zero and before minute 30, below both the conservative
minute-34 wrapper cutoff and required minute-35 test ceiling. First budget steps
follow job starts by three seconds or less; final jobs remain below 40 minutes.
Setup, compile, boot, tests and preservation are included; no allowance rollover.
Original timestamps/commands/exits are in invocation JSON and `jobs.json`.
Runner Actions annotations concerning Node runtime migration/capacity are retained;
they are not product failures or evidence of historical cause.

## Original preservation and integrity

`run.json`, `jobs.json`, `artifacts.json`, both full `*-actions.log` files, native/UI
`*-*.log` files, invocation JSON and toolchain/ordinary fixture journals are archived.
The ZIPs include all four original xcresults. No optional diagnostic capture
completeness or historical root-cause finding is claimed.

| Actions artifact | Bytes | SHA-256 / durable Git preservation |
| --- | --- | --- |
| [list 12710433387](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40448988954/artifacts/12710433387) | 131,260,756 | `6edbc9f6bbd8ca8ffef9fbb86d46124b701a9ed40122bbd2979c7620cb86c045`; four lossless `gate6-reset-list.zip.part01`…`part04` files |
| [editor 12710155938](https://github.com/teejayishere/PuzzleAlarm/actions/runs/40448988954/artifacts/12710155938) | 3,190,823 | `75dc22325b722c406b5f81dd38070573965b576a3646d6a2ee0ec6e7cb0df8e1`; original `gate6-reset-editor.zip` |

Both downloaded original ZIP hashes match GitHub artifact digests. Each list part
and the concatenated original hash were independently checked. The list ZIP exceeds
GitHub's single-file limit; the original bytes are preserved in Git as four parts
with `list-archive-parts.json`. Restore using free Python, without network:

```text
python docs/evidence/gate6-controlled-reset/restore_list_archive.py TestResults/Gate6ControlledReset/restored-list.zip
```

The script verifies each part and the restored ZIP and never overwrites a file.
Original downloaded ZIPs and extracted xcresults also remain locally under
`TestResults/Gate6ControlledReset/`. Actions expires November 26 UTC (exact times in
`artifacts.json`); the Git-preserved original bytes do not depend on that retention.
Historical Stage 13/local-only preservation limits remain unchanged.

## Revision boundaries and disposition

Baseline local/remote Stage 13 closeout `d65649f` matched; exact CI 40446680828
SKIPPED, no jobs executed. Preparation `07edf88` exact CI 40448873182 SKIPPED.
Read-only workflow lookup returned 404 before dispatch/allocation; the unavailable
manual route was replaced before validation with a guarded push. Product/tests
did not change between preparation and tested candidate. Tested exact-HEAD ordinary
CI 40448989070 is SKIPPED, all three jobs/no steps; metadata archived here.

Gate 6 replacement execution is **PASS within this owner-defined focused scope**.
Gates 7–13 remain INVALIDATED / HELD, requiring separately scoped ordered replay.
No downstream development, historical-cause clearance, broad/product/device
acceptance or main promotion. Historical diagnostic budgets remain EXHAUSTED;
the prior exception remains REVOKED. Historical failures/evidence stay preserved.

The evidence/publication descendant is documentation-only and is not the tested
candidate. Its SHA and skipped CI are reported separately in Git history/closeout.
Source is unchanged after the frozen attempt. STOP after this evidence publication.
