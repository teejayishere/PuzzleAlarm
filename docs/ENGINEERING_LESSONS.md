# Native wheel regression evidence - 2026-11-23

Picker300f63a/run45300385711 FAILED: seven draft unit tests PASS, both UI cases
failed at native adjust(toPickerWheelValue:"8"). XCTest explicitly listed the
accepted zero-padded values01...23,00. Picker/app compiled, installed, launched;
no product binding defect established. Changed helper selects "%02d" for both
wheels, preserving all draft/disk/service/relaunch assertions. Actual runner949s;
native allocation1/2 used. Downloaded artifact14877874730; inner app ZIP hash/CRC
and frozen xcresult ZIP CRC verified. Two PNG recovered; one inspected showing
the native time wheels. Combined next candidate consumes the second native slot
and first playable slot; both scoped contracts remain required, no duplicate run.

---

# PA-L009 - Formal acceptance must not conceal lack of a usable preview

Owner feedback2026-11-23: months of development without an Appetize version.
Repeated harness repairs and checkpoint reassessments delayed hands-on feedback.
The recursion defect was real, but later XCTest hittability failures do not by
themselves establish a product defect. Distinguish unfinished features, proven
product failures, test infrastructure failures and unresolved observations.

Prevention: when the owner requests a preview, ship a clearly labelled candidate
with explicit limitations independently of formal promotion. Preserve gate failures
without turning every diagnostic failure into a delivery blocker. Provide a build
artifact and exact source/run evidence; compilation/launch is not proof of complete
user journeys. Future sessions should resume from PROJECT_STATE's owner priority.
No extra regression suite is needed to demonstrate this workflow correction;
the concrete evidence is an actual uploadable build and honest capability list.

---

# PA-L001 / PA-L008 scoped verification - 2026-11-23

[Run45250273849](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45250273849)
on c62d0a8 proves the four negative regression postconditions actually completed:
four unique completion markers,all five intentional issue records including the
secondary,one rejected nested capture and later independent collection. No runner
restart; six iOS cases and three verifier tests PASS. Artifact/screens inspected.
The first nominal green run remains rejected as postcondition evidence.

The new prevention is executable: CI rejects missing/duplicate completion or
missing issue evidence. Complete prior6A coverage and exact final-HEAD verification
remain required before gate restoration; PROJECT_STATE owns that decision. Neither
the original launch trigger nor QR Save cause is declared resolved by these tests.

---

# PA-L008 - A passing negative test can stop before its postconditions

Observed2026-11-23: [run45248280818](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45248280818),
sourcee79ce2ab, six cases PASS and no runner restart. Artifact/log inspection found
that direct record() with fail-fast still aborted after each strictly expected
primary issue. Post-injection capture phases were absent; the secondary issue
never executed. The real SUCCESS was not evidence of the intended cleanup tests.
The omission was caught before6A restoration; no green-summary-only acceptance.

Why missed in implementation review: exact XCTExpectFailure matching was assumed
to imply subsequent assertions ran. That assumption was not demonstrated. The
initial progress report calling the postconditions exercised was premature and
was corrected immediately after inspecting the actual messages and phases.

Prevention: controlled negative fixture blocks must explicitly permit continuation
long enough to reach postconditions, then restore normal fail-fast behavior. Keep
strict issue type/source/description matching; unexpected failures still fail.
Require explicit completion after all postconditions and verify primary/secondary
issue counts. Reject a green suite with missing postconditions. Do not infer test
coverage from test names, expected-failure matches or terminal totals alone.

Implementation candidate: FOUR postcondition markers, FIVE intended issue records
and a CI verifier with false-green/missing/duplicate-evidence rejection tests.
Runtime status belongs to TEST_MATRIX/PROJECT_STATE, not this lesson. The existing
observer fix remains source evidence until these regressions actually complete.

---

# PA-L001 implementation progress - 2026-11-23

The current capture repair candidate implements immediate issue forwarding,
deferred optional diagnostics, a shared re-entry guard, lifecycle omission records
and four negative regression scenarios6A.3a-6A.3d. IMPLEMENTED / NOT RUN: this is
not a verified repair or restored gate. TEST_MATRIX owns executable/evidence mapping;
PROJECT_STATE owns the bounded repair scope and decision. Original launch failure
and QR Save cause remain unresolved; no unrelated product repair is inferred.
The earlier REQUIRED / NOT IMPLEMENTED wording below records the documentation-
only revision's state. A passing normal path will not close this lesson: negative
regressions, complete prior6A coverage and documented final-HEAD evidence are needed.

---

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
