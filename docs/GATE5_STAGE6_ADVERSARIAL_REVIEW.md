# Gate 5 foundation / clean Stage 6 rebuild: adversarial review

Reviewed October 29, 2026. This records the read-only review and its subsequent
red-team reassessment. The owner's follow-up authorizes documentation publication
only. It does not authorize implementation, tests, diagnostics, CI allocation,
workflow unsealing, a PR, promotion, or device actions.

## Verdict and exact scope

**APPROVE the Gate 5 foundation and architectural direction for planning a clean
Stage 6 rebuild. BLOCK execution under current authorization and BLOCK describing
the prepared plan as acceptance-ready.** This qualified verdict supersedes the
initial review's overly broad BLOCK on beginning implementation.

Verified review target: `codex/gate5-stage6-rebuild` at
`5193c0aef6cd9076312f042e0d73cca593f076e4`, direct parent
`159b777379ad587a615df56ef24fa273aa29ffe4`. Its worktree was clean, including
untracked-file inspection. Production and test source, project configuration,
resources and dependencies matched Gate 5. Differences were documentation,
engineering instructions and two CI guards. Both workflow jobs have literal-false
allocation guards. This is source inspection, not executed workflow verification.

Historical Gate 5 success applies to its historical revision. Neither preparation
nor this documentation publication is a new product CI pass. Gate 6 remains
FAILED / HELD; Gates 7-14 INVALIDATED / HELD; last unheld gate 5.

## Findings, challenged and narrowed

1. **Ownership direction is independently defensible.** Synchronous store-wide
   admission closes the source-visible gap between row-local pending state and
   asynchronous store admission. It does not explain historical missed native
   input. The proposal already covers a single receipt, UUID/live-state bindings,
   lifetime independent of views, reconciliation and release. Do not characterize
   those safeguards as absent or copy the failed all-stage store forward.
2. **Specify outcomes, not a mandatory API shape.** Admission must synchronously
   distinguish accepted work, no-op and rejection. Accepted work needs one
   observable terminal outcome after authoritative state publication and pending
   release. Distinguish saved, persisted-but-needs-attention, stale/superseded,
   deferred deletion and failure. A typed receipt/awaitable result is one valid
   design, not a requirement by itself. No rejection may strand pending state;
   no command may reject its own reservation or infer success from a global error.
3. **Enforce one production lifecycle authority.** The facade controls admission
   and presentation; the existing coordinator owns lifecycle effects and CAS.
   Views/bindings cannot write persisted lifecycle state or call the scheduler.
   Include authorization, startup and foreground work in the admission policy.
   Private coordinator access is a useful enforcement option, not an independent
   gate requirement; test visibility does not create another authority.
4. **Close the trailing-refresh edge.** Define foreground arrival during the
   command and during its coalesced reconciliation. Use bounded pending work and
   an atomic release/handoff: no lost request, overlapping coordinator calls or
   indefinitely extended command receipt. Startup completion must distinguish
   successful loading from a handled read failure. Keep loaded data, scheduling
   confirmation and operation completion distinct.
5. **Separate failure reload from recovery.** An ambiguous command failure reloads
   persisted progress without repeating the command. Explicit startup/foreground
   reconciliation may use Gate 5 recovery, including cleanup; it is not permission
   to retry a failed scheduling generation. Preserve command and refresh error
   meaning. Never claim healthy scheduling from stale or unreadable state.

These are implementation/acceptance contracts, not proven historical causes.

## Stage boundary and test obligations

The master plan assigns a sound picker shell to Stage 6; playback, resources and
fallback belong to Stage 11. Challenge configuration/order uses existing models,
without engines, scanning, routing or completion orchestration. Stage 6 can be
implemented independently of Stages 7-14.

**Recommended acceptance amendment, not yet adopted by the owner:** the ten
Stage-6-applicable management declarations establish this milestone's management
coverage. Preserve the eleventh audio-preview declaration and require it, plus
the complete historical management replay, when Stage 11 is restored. Do not
count audio as passed, silently omit it, or import Stage 11 to satisfy Stage 6.
The existing all-eleven recovery wording must be reconciled explicitly before
acceptance. This review does not silently amend the controlling gate.

The historical inventory contains 253 declarations: 148 Core, 85 native and 20 UI.
Counts, hashes and stage assignments preserve accounting, not behavioral
equivalence or executed coverage. The blanket API-only/preserve-every-assertion
wording needs a more precise migration rule:

- Map each declaration and its material assertions to a product/invariant
  requirement, real dependency stage and replacement observation.
- Retain valid input, timing, identity, status, error, persistence and failure
  obligations. Native setter tests cannot replace real UI input evidence.
- Justify each structural adaptation, consolidation or obsolete assertion before
  changing it. Preserve historical originals and make equivalence inspectable.
- Missing later-stage dependencies mean deferred/held, never passed or obsolete.
  Preserve all six unexecuted Stage 14 additions as later obligations.
- Retain the base disk integration test as an earlier prerequisite also exercised
  by Stage 6; file-level stage labels must not erase its earlier responsibility.

## Executable plan after separate authorization

1. Finalize admission/termination, readiness and refresh-handoff contracts and
   settle the acceptance amendment above. Record assertion-level migration.
2. Compose one app-scoped repository, scheduler adapter, coordinator and observable
   management facade. Keep Gate 5 Core/platform behavior unless an independently
   established earlier-stage defect requires recursive correction.
3. Implement list/add/edit/delete, enable/disable, weekdays/modes, challenge
   configuration/order, sound selection, local drafts with original-definition
   conflict checks, truthful status/errors and explicit Retry. Bind by UUID to live
   store state. Keep fixtures Debug-only. No later-stage runtime implementation.
4. Cover same-turn cross-command/authorization contention; duplicate/no-op input;
   retained/recreated/removed rows; view disappearance; command completion after
   denial, write failures, acknowledgment loss and stale edits; foreground arrival
   during both command and trailing reconciliation; failed startup/warm reads;
   and uncertainty/recovery without fabricated success. Migrate the 37 historical
   native obligations by inspectable behavior rather than importing their owners.
5. Under a separately approved execution manifest, freeze the candidate and exact
   selectors. Establish required Gate 0-5 prerequisites before Stage 6 execution.
   Any parallel evidence collection requires explicit justification compatible
   with the prohibition on advancing past blocked prerequisites. Then require
   ten ordinary list executions, the independent cold editor, all ten applicable
   management declarations, applicable Core/native regression and required
   Debug/Release, reproducibility, SDK, resources/plists, fixture exclusion,
   coverage audit and warning checks. No corrective extra taps or failed-test
   reruns. Product Retry remains part of the required product flow.
6. Accept only complete required evidence for the frozen revision. Stop on any
   required failure, preserve originals, reopen the earliest affected gate and
   invalidate dependents. Rerun only under authorized scope and in gate order.
   Gate 6 success leaves Gates 7-14 held. Restore later stages independently;
   replay each earlier affected prerequisite and all applicable regressions.

## Execution restrictions and evidence

Diagnostic budgets remain EXHAUSTED, zero jobs; exception REVOKED. Rebuilding,
renaming the issue or calling sampling acceptance cannot reset those restrictions.
Exhaustion does not automatically forbid separately authorized implementation
and bounded acceptance. Such authorization must explicitly establish scope and
treatment of unresolved risk without reviving the closed exception. The proposed
three jobs / 40, 25 and 60 minutes remain unapproved, granting zero allocations.

Source review and Git/declaration bookkeeping only were performed for the review.
Automated tests, diagnostics, Xcode/SDK execution, Simulator, device and exact-HEAD
product CI: NOT RUN. Documentation publication is separately authorized by the
follow-up; record its commit separately from the reviewed revision. A skipped
publication workflow is not a product PASS. Do not open a PR or alter main.
