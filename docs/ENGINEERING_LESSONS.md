# Engineering lessons and recurrence prevention

Owner requested durable learning on 2026-11-23 (America/Chicago).

This is a reference for failure mechanisms and prevention rules in the active
restart lineage. It is not a second work queue or gate-status authority.
[PROJECT_STATE](PROJECT_STATE.md) owns current decisions and next scope;
[TEST_MATRIX](TEST_MATRIX.md) owns executable scenarios and evidence;
[ARCHITECTURE](ARCHITECTURE.md) owns design contracts; [AGENTS](../AGENTS.md)
makes reading/applying relevant lessons part of future sessions.

The rules below are required. Their implementation and verification must be
reported separately. In particular, this documentation change does not repair
the shared observer or prove QR Save delivery. No new gate is accepted here.

## How future sessions use this record

1. Read current PROJECT_STATE, AGENTS and the relevant lesson entries before
   choosing a repair. Identify the lesson IDs in the change plan/evidence note.
2. Separate the first observed failure, a proven mechanism, downstream symptoms
   and unresolved triggers. State what would disprove the repair hypothesis.
3. Name a concrete prevention mechanism and a meaningful failure-path regression.
   Reuse existing tests when they cover the mechanism; add missing coverage when
   necessary. A successful normal journey cannot prove an error handler safe.
4. Record a fresh bounded $0 budget before any validation, including local
   preflight/lineage checks. Preserve primary evidence and stop as allocated.
5. After validation, link the exact SHA/run and distinguish IMPLEMENTED,
   NOT RUN and VERIFIED FOR THAT REVISION. Document recurrences under the same
   lesson ID; never replace a failed record with a later optimistic summary.

No automatic enforcement of these written rules is claimed. A future instance
must still read them; regression evidence is the technical protection against
the same defect. Do not reintroduce discarded approaches without new evidence
and a regression that exercises their previous failure mode.

## PA-L001 - Diagnostic collection can cause another failure

**Incident:** [c7fd5d04 / run 45086593612](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45086593612).
The Memory UI case stalled during termination/launch. The shared XCTest issue
observer queried accessibility while collecting diagnostics. Those queries
raised further issues, which re-entered the observer and collection again.
The recovered runner crash report explicitly reports stack exhaustion from
excessive recursion and repeating `AlarmUITestCase.record` / `capture` frames.

**Proven cause:** the observer can recurse and crash before forwarding the
original issue. **Unresolved:** what originally caused termination/launch to
fail. Do not label Memory configuration or persistence broken: neither was
reached. Later QR behavior is a separate observation, not a proven consequence.

**Why prior checks missed it:** earlier missing-element collection ran with a
queryable application. That did not exercise collection when the accessibility
query itself reports an issue during a launch transition. A comment saying the
observer makes no assertions did not make XCTest query operations infallible.
The observer I added was missing this protection.

**Required prevention:** preserve/forward the primary issue even if diagnostics
fail. Bound optional collection, guard every collection entry against re-entry,
and release the guard on every exit. Nested issues must not start another capture
or replace the primary issue. Avoid querying an unavailable application; record
why an optional artifact is missing. Do not add retries or extend product waits.

**Required evidence:** TEST_MATRIX scenarios 6A.3a-6A.3d cover normal capture,
collection-induced secondary issues, unavailable app and launch transition.
Demonstrate the primary issue remains visible, secondary issues remain visible,
at most one outer capture occurs, the runner survives, and a subsequent capture
is possible after cleanup. These protections are REQUIRED / NOT IMPLEMENTED by
this documentation change; see current PROJECT_STATE before any repair.

## PA-L002 - An accessibility wrapper is not always the native control

**Evidence:** [run 44608072736](https://github.com/teejayishere/PuzzleAlarm/actions/runs/44608072736)
showed an identified outer switch receiving a tap while both the direct-state
readout and native value stayed on. The underlying list and presented editor
also shared a diagnostic identifier, making the observer ambiguous. Later
[run 44701206582](https://github.com/teejayishere/PuzzleAlarm/actions/runs/44701206582)
provided revision-specific native-child/fixture evidence.

**Lesson:** an ineffective gesture is not sufficient evidence of a product
binding or asynchronous service defect. Two visible contexts can both remain
in the accessibility tree. `firstMatch` would conceal the wrong-target problem.

**Required prevention/evidence:** use known fixture identity and contextual
identifiers; require exactly one intended match. Inspect the control hierarchy,
use one evidenced native gesture, and compare native value with actual draft,
service entry and durable state. Keep duplicate/absent-target rejection and the
original functional assertions. Do not repair product bindings from tap logs
alone, blindly retap or use broad unscoped queries to obtain a pass.

## PA-L003 - Observation has cost, and readiness is not existence

**Evidence:** [run 44697616061](https://github.com/teejayishere/PuzzleAlarm/actions/runs/44697616061)
spent roughly 150-175 seconds per diagnostic phase resolving descendants.
Filtering in XCTest before enumeration reduced that demonstrated cost.
[run 45037783645](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45037783645)
later failed the minute-menu readiness predicate despite a unique existing
option. Native-wait evidence in
[run 45041577045](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45041577045)
also exercised rejection of covered and disabled controls.

**Lesson:** existence/cardinality, enabled state, hittability and gesture delivery
are separate claims. Remote property calls and collection can dominate a test.
Runtime improvement does not prove a particular XCTest internals defect.

**Required prevention/evidence:** filter before enumerating; reveal lazy/offscreen
content within existing bounds; retain unique targeting and native readiness
checks. Measure existence wait, count and readiness separately. Preserve the
3/10-second API limits and negative absent/covered/disabled cases. Report measured
elapsed time honestly: remote-call overhead can exceed a requested API timeout;
do not call it a proven hard wall-clock deadline. Never lengthen waits or remove
assertions solely to hide the observed failure.

## PA-L004 - Failure evidence needs its own safe lifecycle

**Incident:** [run 45037783645](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45037783645)
timed out and artifact upload failed while a live `.tracev3` file changed or
disappeared. Logs mentioning screenshots did not provide recoverable images.
The settings failure in
[run 45086593612](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45086593612)
successfully froze/uploaded evidence, allowing the crash to be diagnosed.

**Required prevention:** upload an immutable snapshot of finalized xcresult
objects and copied logs, outside live diagnostic staging. Record every exclusion
and read error in a manifest. Reserve time for cleanup/freeze/upload and include
actual cleanup time in the runner budget. Size profiles using measured runtime;
retain coverage through explicit ordered profiles rather than quietly skipping
functional assertions.

**Required evidence:** preservation-script tests must cover later source changes
and missing inputs. Verify uploaded artifact metadata, digest and ZIP integrity;
index recovered screenshots and inspect the images relevant to the claim. An
upload step or log message alone does not prove complete artifact preservation.
Frozen upload does not by itself establish that test execution passed.

## PA-L005 - A recorded tap does not prove command delivery

**Incident:** QR in
[run 45086593612](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45086593612)
had successful native Save readiness and one tap, but the editor remained open,
disk was unchanged and no edit-service event appeared. The cause is unresolved.
The later covered-row assertion identifies where the test stopped, not why Save
failed to reach the service.

**Required prevention/evidence:** trace intended identity -> actual draft -> one
gesture -> handler/service entry -> authoritative disk -> reopened UI. Assert
the expected screen transition before trying to reveal a control behind a sheet;
scrolling cannot make a covered control available. Preserve before/after values,
service events, disk hashes and screenshots. Isolate no-op Save from changed Save
without dropping the no-op contract. Do not declare a storage/scheduler defect,
add a second tap or rewrite product code without evidence at the failing boundary.

## PA-L006 - Verify harness and invocation changes before interpreting results

**Evidence:** restart commits
[c9c8ed5](https://github.com/teejayishere/PuzzleAlarm/commit/c9c8ed54125fd3190e0e95d6f9db57abf65a779a),
[bdb8336](https://github.com/teejayishere/PuzzleAlarm/commit/bdb83365ddf75981281ddbe0caf5e30eba2731f4)
and [cd05a8d](https://github.com/teejayishere/PuzzleAlarm/commit/cd05a8d3ca51478b305060916bc06b2c94d5dff4)
record an unsupported Xcode invocation option, Swift isolation issue in the
observer and an XCTest helper selector collision. These prevented intended
functional validation; they were not evidence of a product feature failure.

**Required prevention/evidence:** inspect supported installed-tool options before
changing invocations; review Swift actor isolation and inherited XCTest/Objective-C
selectors when changing shared helpers. Confirm the source compiled and the
intended distinct cases actually executed. Separate build, unit, UI, diagnostics,
artifact and device evidence. Report interrupted cases and runner restarts rather
than inferring success from the final suite total after a restart. A focused pass
is neither full Gate 6 coverage nor physical-device evidence.

## PA-L007 - Session memory must be discoverable and honest

**Observed process gaps:** long prepended histories preserved incidents but made
actionable prevention hard to find. Broad acceptance wording could be read as
covering untested failure paths. During this documentation session, local
preflight/lineage checks were also executed before the new budget was written.
That order was an error; the later budget does not retroactively authorize it.
No CI or product-test execution occurred in this documentation session.

**Required prevention:** read this ledger through AGENTS; keep current status and
next scope in PROJECT_STATE only. Link concrete incidents and regression IDs,
not a new duplicate status summary. Record budgets before all checks. Preserve
the original checkout and incident history; publish only from verified lineage
using expected remote SHA and non-force fast-forward. Record real procedural
misses instead of describing them as compliant after the fact.

**Required closeout:** for each affected lesson, state the safeguard actually
implemented, the regression actually executed, exact SHA/run/result and remaining
uncertainty. If only documentation changed, say so and leave implementation/gate
acceptance unchanged. No successful exact-HEAD CI is claimed for `[skip ci]`
documentation revisions. An unchanged failing run is not useful new evidence.

## Record format for a new incident or recurrence

- Lesson ID and affected boundary; recurrence links, if any.
- Exact assessed SHA, run URL/profile/attempt and relevant artifact identifiers.
- Observed sequence; proven cause; unresolved trigger; downstream symptoms.
- Why previous tests, review or documentation failed to prevent it.
- Concrete prevention rule and implementation status.
- Required regression ID and independently expected result; actual evidence
  remains in TEST_MATRIX, and current acceptance remains in PROJECT_STATE.
- Remaining uncertainty and an observation that would disprove the hypothesis.

This ledger contains no copied implementation from abandoned branches and does
not authorize new validation or later-checkpoint work.
