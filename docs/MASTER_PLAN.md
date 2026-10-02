# PuzzleAlarm — Recursive Self-Correcting Master Development Plan

You are the lead implementation engineer for **PuzzleAlarm**, a personal native iPhone alarm application.

Your job is not merely to generate code.

You are responsible for:

- architecture
- implementation
- automated testing
- integration testing
- CI
- simulator validation
- code quality
- regression prevention
- documentation
- diagnosing your own failures
- revisiting earlier architectural decisions when later evidence disproves them
- distinguishing verified behavior from assumptions
- preparing the application for eventual physical-iPhone validation

The development process must be **incremental, evidence-driven, recursive, and self-correcting**.

Do not treat this specification as a one-way checklist.

Every implementation stage may reveal flaws in an earlier stage. When that happens, return to the earliest affected stage, correct the root cause, invalidate dependent evidence, rerun the affected gates in order, and only then continue.

Never knowingly build new functionality on top of a failed or invalidated assumption.

---

# 1. Product Goal

Build a personal native iPhone alarm application inspired by Alarmy.

The primary purpose is to make it difficult for the user to dismiss an alarm and immediately go back to sleep.

An alarm can operate in either of two modes.

## Mode A — Annoying Alarm Only

The alarm behaves as a normal AlarmKit alarm.

The user can select:

- the default supported alarm sound
- one of several intentionally annoying bundled sounds

No challenge is required.

For Version 1, do not create the challenge backup-alarm chain for this mode.

Use AlarmKit's recurring scheduling capability where appropriate so normal weekday alarms continue to recur without requiring the app to reopen after each alarm.

## Mode B — Challenges Required

The user configures an ordered challenge sequence.

Version 1 supports these challenge types:

- Math
- Memory
- QR Code

For Version 1, each challenge type may appear at most once in one alarm sequence.

Therefore the sequence contains between 1 and 3 challenges.

Examples:

- Math
- Memory
- QR
- Memory → QR
- Math → Memory
- Memory → Math → QR
- QR → Math → Memory

The order matters.

A challenge-required wake-up occurrence is not complete until every configured challenge has successfully completed in order.

While the wake-up session remains incomplete, independently scheduled backup alarms remain scheduled.

Completing the entire challenge sequence cancels the remaining backup alarms for that occurrence.

---

# 2. Non-Negotiable Constraints

## Cost

The entire development and testing workflow must use **$0 tools and services**.

Do not introduce:

- paid Apple Developer Program requirements
- paid CI
- paid cloud Mac services
- paid SDKs
- paid APIs
- paid analytics
- paid databases
- paid signing services
- paid dependencies

Open-source and genuinely free tools are permitted.

Assume the source repository may be public so free standard GitHub-hosted macOS runners can be used.

Never commit personal credentials, Apple credentials, tokens, signing materials, or other secrets to that public repository.

## Developer hardware

Assume the developer:

- has an iPhone
- does not own a Mac
- may use Windows or Linux
- develops primarily through Codex and GitHub
- will eventually use free personal iPhone provisioning/sideloading for device tests

Do not make ownership of a local Mac a prerequisite for ordinary development.

## Distribution

This is a personal application.

Do not build:

- App Store infrastructure
- subscriptions
- payments
- advertising
- user accounts
- server infrastructure
- cloud sync
- analytics
- telemetry

## Platform

Target:

- iPhone
- iOS 26+
- Swift
- SwiftUI
- AlarmKit
- App Intents where AlarmKit requires them
- async/await
- public Apple APIs only

AlarmKit is the real alarm mechanism.

Do not substitute ordinary notification hacks for the actual alarm system.

---

# 3. Core Engineering Philosophy

Apply these rules throughout the project.

## Evidence over assumption

Never call behavior verified merely because:

- the code looks correct
- an API should work
- documentation suggests it should work
- a mock test passes
- a similar feature worked elsewhere

Use the strongest available evidence.

Distinguish:

- source code exists
- automated test passes
- Xcode compilation passes
- Simulator workflow passes
- physical-device validation passes

## Root cause over symptom patching

When something fails, do not immediately patch the visible symptom.

Determine:

1. what failed
2. where the incorrect assumption originated
3. whether the problem belongs to the current stage or an earlier stage
4. what evidence should have caught it
5. what regression test should prevent recurrence

Fix the earliest defensible root cause.

## Minimal correct change

Prefer the smallest change that solves the underlying problem cleanly.

Do not rewrite unrelated working code.

Do not introduce abstractions merely because they seem sophisticated.

## Tests are executable requirements

Tests must represent intended behavior.

Do not weaken, delete, skip, or rewrite a valid test merely to get a green build.

If a test is genuinely wrong because the specification changed, explicitly document why before changing the test.

---

# 4. Recursive Self-Correction Controller

This section governs the entire development process.

Every stage must run through the following recursive loop.

## STEP A — Observe

Before changing code:

1. inspect the current repository
2. inspect relevant existing source
3. inspect relevant tests
4. inspect current project-state documentation
5. inspect current git diff
6. inspect current CI status if accessible
7. identify the exact requirement being implemented
8. identify assumptions that the change depends on

Do not modify a file before understanding its current responsibility.

## STEP B — Form a hypothesis

State internally:

- what should change
- why
- what components should remain unchanged
- what tests should prove correctness
- what failure modes are likely

Prefer one coherent implementation hypothesis at a time.

## STEP C — Implement minimally

Make the smallest coherent implementation that can satisfy the requirement.

Avoid combining multiple unrelated feature changes.

## STEP D — Run focused validation

Run the narrowest tests relevant to the change first.

Examples:

- one unit-test suite
- one Swift package test target
- one integration test
- one compile spike

Fast feedback comes before the full suite.

## STEP E — Self-review the diff

Before accepting the implementation, inspect your own diff as if reviewing another engineer's pull request.

Check:

- correctness
- duplicated logic
- accidental API coupling
- state-management mistakes
- concurrency mistakes
- lifecycle issues
- error handling
- accessibility
- resource cleanup
- dead code
- unnecessary complexity
- security/privacy implications
- missing tests

Do not assume passing tests imply good architecture.

## STEP F — Adversarial review

Actively try to break your own implementation.

Ask questions such as:

- What happens if this operation executes twice?
- What happens if the app dies halfway through?
- What happens if disk persistence fails?
- What happens if AlarmKit schedules only some alarms?
- What happens if cancellation fails?
- What happens if a callback arrives twice?
- What happens if a user edits an alarm while a session exists?
- What happens at midnight?
- What happens during DST?
- What happens if permissions are denied?
- What happens if the camera disappears?
- What happens if a referenced sound file is missing?
- What happens if persisted data comes from an older schema?
- What happens if the UI is recreated?
- What happens if two async operations race?

Add tests where these reveal meaningful gaps.

## STEP G — Run the stage gate

Run every test/check required by the current stage.

A focused test passing is not enough.

## STEP H — Run regression checks

Determine what earlier stages could have been affected.

Rerun their relevant gates.

Do not blindly rerun every expensive test after every line change, but err toward broader regression testing when changes affect shared domain models, persistence, scheduling, lifecycle, or coordinator logic.

## STEP I — Update evidence

Update project-state documentation with:

- what was changed
- what was tested
- exact test/build result
- what remains inferred
- what requires a device
- new risks discovered

## STEP J — Decide

There are only three valid outcomes:

### PASS

Evidence supports the stage.

Proceed.

### RECURSE

Later evidence reveals a defect or invalid assumption in this or an earlier stage.

Return to the earliest affected stage.

Invalidate dependent gates.

Fix the underlying problem.

Then rerun all invalidated gates sequentially.

### BLOCKED

The problem cannot be resolved in the current environment.

Stop at the precise technical boundary and report evidence.

Never convert BLOCKED into PASS through optimistic language.

---

# 5. Recursive Gate Invalidation

A previously passing gate is not permanently trusted.

If later work reveals that an earlier assumption was wrong, mark every dependent gate invalid.

Example:

Stage 3 reveals AlarmKit cannot represent metadata the way Stage 1 modeled it.

Do not add increasingly awkward translation layers merely to preserve Stage 1.

Instead:

```text
Stage 3 failure
↓
root cause traced to Stage 1 domain model
↓
invalidate Gate 1
invalidate Gate 2 if affected
invalidate Gate 3
↓
repair Stage 1
↓
rerun Gate 1
↓
rerun Gate 2
↓
rerun Gate 3
```

Only after all affected gates pass again may development continue.

The same rule applies later.

Example:

A Stage 11 lifecycle test reveals the persistence model cannot safely represent partially scheduled alarms.

Return to the persistence/session architecture stage.

Fix it there.

Do not bury compensating logic inside Stage 11.

---

# 6. Bounded Recursive Debugging

Self-correction must not become infinite looping.

For one failing hypothesis:

1. attempt the most likely root-cause correction
2. rerun the failing reproduction
3. if still failing, gather new evidence before making another change

Do not repeatedly make speculative edits without new information.

After approximately three unsuccessful corrections based on the same underlying theory:

- stop using that theory
- re-examine assumptions
- inspect primary evidence again
- try a different architectural or diagnostic approach

If progress remains impossible because of environment/tool/platform limitations, classify the state as BLOCKED.

Do not fake progress by cycling endlessly.

---

# 7. Persistent Engineering State

Create:

`docs/PROJECT_STATE.md`

This is the durable state machine for development.

Maintain at least:

```text
Current stage:
Current gate:
Last known passing gate:
Invalidated gates:
Current blockers:
Open engineering risks:
Unverified assumptions:
Device-required validations:
Most recent CI evidence:
Current version/status:
```

Update it whenever a gate:

- passes
- fails
- becomes invalidated
- becomes blocked

Codex must read this file at the beginning of every substantial new development session.

Do not trust PROJECT_STATE blindly if code/tests disagree with it.

The repository and fresh test evidence are authoritative.

---

# 8. Evidence Ledger

Also maintain a concise evidence table in `docs/TEST_MATRIX.md`.

For important capabilities use statuses such as:

```text
NOT STARTED
IMPLEMENTED
AUTOMATED PASS
XCODE COMPILE PASS
SIMULATOR PASS
DEVICE REQUIRED
DEVICE PASS
FAILED
INVALIDATED
BLOCKED
```

Record what produced the evidence when practical.

Example:

```text
Math challenge answer validation
AUTOMATED PASS
PuzzleAlarmCoreTests
current HEAD
```

Never mark DEVICE PASS without an actual physical-device observation.

---

# 9. Development Environment Architecture

Divide the project into two conceptual layers.

## PuzzleAlarmCore

Create a Swift Package containing as much pure business logic as reasonably possible.

Avoid dependencies on:

- SwiftUI
- UIKit
- AlarmKit
- AVFoundation

when the feature does not fundamentally require them.

Core responsibilities include:

- domain models
- challenge state machines
- math generation
- memory generation
- challenge sequencing
- schedule calculations
- backup date generation
- wake-up session rules
- persistence interfaces
- deterministic utilities
- validation

The package should support fast testing outside macOS where Swift tooling permits.

## PuzzleAlarm iOS Application

Contains:

- SwiftUI
- AlarmKit
- App Intents
- AVFoundation
- camera implementation
- audio preview
- iOS persistence implementation
- application lifecycle handling
- platform-specific routing
- file import/share interfaces

Keep Apple-framework adapters thin.

Do not hide core product rules inside platform adapters.

---

# 10. Project Generation

Because there is no developer-owned Mac, the Xcode project must be reproducibly generated from text configuration.

Prefer a free/open-source project generator such as XcodeGen.

Maintain:

`project.yml`

as the project definition.

Do not require manual `.pbxproj` editing.

CI should generate the project before building.

Pin versions of external build tools where practical.

Print versions during CI.

Do not add more project-generation tooling than necessary.

---

# 11. Repository Structure

Prefer approximately:

```text
PuzzleAlarm/
├── Package.swift
├── project.yml
├── README.md
├── CONTRIBUTING.md
├── .gitignore
│
├── PuzzleAlarmCore/
│   ├── Sources/
│   │   └── PuzzleAlarmCore/
│   │       ├── Models/
│   │       ├── Challenges/
│   │       ├── Scheduling/
│   │       ├── Sessions/
│   │       ├── Persistence/
│   │       └── Utilities/
│   └── Tests/
│
├── PuzzleAlarm/
│   ├── App/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   ├── AlarmKit/
│   ├── Intents/
│   ├── Camera/
│   ├── Audio/
│   └── Resources/
│
├── PuzzleAlarmTests/
├── PuzzleAlarmUITests/
│
├── Scripts/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── PROJECT_STATE.md
│   ├── TEST_MATRIX.md
│   ├── DEVICE_TEST_PLAN.md
│   └── DEVELOPMENT_LOG.md
│
└── .github/
    └── workflows/
        └── ios.yml
```

Adjust where SwiftPM/XcodeGen constraints justify something cleaner.

Do not create empty architecture for appearance's sake.

---

# 12. Core Data Model

Create clean Codable and Sendable domain models where appropriate.

## AlarmDefinition

At minimum:

- id
- time
- selected weekdays
- enabled
- dismissalMode
- challengeSequence
- selectedSound
- createdAt
- updatedAt

Do not couple this model to SwiftUI.

## DismissalMode

Conceptually:

```swift
enum DismissalMode {
    case annoyingOnly
    case challengesRequired
}
```

Use a stable Codable representation.

## ChallengeConfiguration

Represent challenges as ordered data.

Conceptually:

```swift
enum ChallengeConfiguration {
    case math(MathChallengeConfiguration)
    case memory(MemoryChallengeConfiguration)
    case qr(QRChallengeConfiguration)
}
```

Version 1 permits each challenge type at most once.

The application must support:

- add
- remove
- configure
- reorder
- persist
- restore

Do not encode challenge transitions as direct view-to-view relationships.

Use a generic coordinator/state machine.

---

# 13. WakeUpSession

A challenge-required wake-up occurrence has its own persistent WakeUpSession.

It represents one occurrence, not the general recurring alarm definition.

Persist at minimum:

- session ID
- parent alarm ID
- scheduled wake-up date
- timezone/calendar context needed to interpret the occurrence
- challenge configuration snapshot
- selected sound snapshot where relevant
- planned AlarmKit IDs
- successfully scheduled AlarmKit IDs
- primary AlarmKit ID
- backup AlarmKit IDs
- current challenge index
- challenge-specific progress
- scheduling state
- completion state
- cancellation state
- created timestamp
- completed timestamp where applicable

Editing AlarmDefinition later must not silently mutate the configuration of an already active session.

The active WakeUpSession owns a snapshot.

---

# 14. Wake-Up Session State Machine

Avoid scattered booleans.

Represent meaningful lifecycle states explicitly.

Conceptually:

```text
planned
scheduling
armed
active
completing
completed
schedulingFailed
cancellationPartiallyFailed
```

Exact naming may differ.

State transitions should be controlled.

Invalid transitions should be prevented or rejected.

Example:

```text
planned
→ scheduling
→ armed
→ active
→ completing
→ completed
```

A failed partial schedule should not be represented as fully armed.

---

# 15. Critical Completion Invariant

There is one authoritative rule:

> A challenge-required WakeUpSession becomes completed only after every configured challenge has successfully completed in order.

These actions do not complete it:

- opening the app
- stopping one system alarm
- backgrounding
- terminating
- reopening
- completing only Math
- completing only Memory
- scanning QR before earlier required challenges
- navigating views
- relaunching after partial progress

Prefer one controlled domain transition responsible for session completion.

Do not assign completion state from arbitrary views.

---

# 16. Recurring Alarm Strategy

Treat normal alarm definitions separately from individual challenge-required occurrences.

## Annoying Alarm Only

Where AlarmKit supports it cleanly, use its recurring scheduling behavior for selected weekdays.

This avoids depending on the app reopening after every ordinary alarm.

## Challenges Required

Prefer scheduling a concrete next wake-up occurrence as:

- one primary one-time AlarmKit alarm
- four independent one-time backup AlarmKit alarms

After successful completion, calculate and arm the next applicable occurrence for the parent AlarmDefinition.

This separation prevents canceling the current occurrence's backup chain from accidentally destroying future recurring alarms.

If AlarmKit's actual current APIs suggest a materially safer architecture, validate that through a compile/prototype spike and document the decision before changing this design.

Do not guess.

---

# 17. Transactional Alarm Scheduling

Scheduling a five-alarm challenge chain can partially fail.

Treat this as a transaction-like operation.

Process:

1. calculate complete desired schedule
2. create/persist session as `planned`
3. transition to `scheduling`
4. schedule alarms
5. persist each successfully returned AlarmKit ID
6. if all required alarms succeed:
   - mark session `armed`
7. if one fails:
   - attempt to cancel every sibling that was successfully scheduled
   - record rollback results
   - mark session scheduling failure
   - do not present the alarm as successfully armed

Never leave the UI claiming an alarm is armed when only an accidental partial chain exists.

Add automated tests for:

- primary fails
- backup 1 fails
- backup 4 fails
- rollback succeeds
- rollback partially fails

---

# 18. Alarm Editing / Disable / Delete Semantics

Explicitly define these cases.

## Disable

If a challenge alarm has a future armed WakeUpSession:

- cancel all associated scheduled AlarmKit alarms
- update persistent state
- disable parent AlarmDefinition

## Delete

Cancel all future associated scheduled alarms before deleting the definition.

Do not silently orphan scheduled alarms.

## Edit

For changes affecting schedule/challenges/sound:

1. preserve existing active session if the alarm is currently firing/active unless product semantics require otherwise
2. cancel the future armed occurrence when safe
3. persist edited AlarmDefinition
4. create and arm a fresh future occurrence
5. use rollback logic if replacement scheduling fails

Write tests before relying on these semantics.

---

# 19. AlarmKit Architecture

Use:

```text
AlarmScheduling
        ↑
AlarmManagerService
        ↓
Apple AlarmKit
```

The domain layer depends on the protocol, not directly on AlarmKit.

Do not name our implementation `AlarmManager`.

Before implementing or modifying AlarmKit behavior:

1. inspect the installed SDK
2. inspect compiler-visible APIs
3. inspect current official documentation if available
4. build the smallest compile spike necessary
5. use compiler output as source of truth

Never invent AlarmKit signatures.

Required capabilities include:

- authorization request
- authorization state
- scheduling
- cancellation
- supported presentation
- App Intent integration
- supported custom sound configuration
- supported metadata
- error propagation

Include the required usage description.

Do not claim real alarm behavior is verified by compilation alone.

---

# 20. Capability Probe Rule

For uncertain Apple functionality, do not embed speculation into the main architecture.

First create a minimal isolated probe.

Use this for things such as:

- AlarmKit custom sound format requirements
- AlarmKit metadata constraints
- App Intent routing behavior
- imported sound support
- Simulator support
- AlarmKit limits

A capability probe should answer one narrow technical question.

If the probe fails:

- document the actual result
- revise the architecture if needed
- invalidate any assumption that depended on it

Delete temporary probe code after its conclusion is captured unless it remains useful as a DEBUG diagnostic.

---

# 21. Backup Alarm Strategy

For challenge-required alarms, Version 1 default:

```text
T
T+1 minute
T+2 minutes
T+3 minutes
T+4 minutes
```

These are independent AlarmKit alarms.

Do not implement backup alarms using an in-app timer.

The backup plan generator belongs in testable core logic.

Store successfully scheduled AlarmKit IDs in WakeUpSession.

When the full challenge sequence completes:

1. transition session to completing
2. persist
3. attempt cancellation of every remaining occurrence AlarmKit ID
4. continue cancellation attempts after individual failure
5. persist cancellation results
6. mark session completed according to explicitly defined semantics
7. arm the next recurring occurrence if the parent alarm remains enabled

Determine carefully whether completion should be persisted before or after cancellation.

Design for app termination during that process.

The process must be idempotent.

If the app is relaunched halfway through cancellation, it should safely resume rather than duplicate or corrupt state.

---

# 22. Idempotency Requirements

Any operation that could be retried after interruption must be safe to retry.

Examples:

- complete challenge
- persist completion
- cancel backup alarms
- schedule next occurrence
- resume after app launch
- apply alarm edit
- handle App Intent routing

Tests must exercise duplicate invocation where practical.

Repeated execution should not:

- increment challenge progress twice
- schedule duplicate alarms
- create duplicate sessions
- cancel unrelated alarms
- corrupt persistence

---

# 23. Alarm Metadata

Where supported, associate minimal metadata needed to identify:

- WakeUpSession ID
- parent alarm ID
- primary/backup role
- backup ordinal

Do not include unnecessary personal information.

Treat SDK limitations as authoritative.

---

# 24. App Launch / Intent Routing

Use current public AlarmKit/App Intents mechanisms.

When PuzzleAlarm enters foreground:

1. load persistent state
2. reconcile incomplete operations
3. inspect active sessions
4. determine whether a wake-up session is due
5. route immediately to its current required challenge
6. restore allowed progress

The alarm list should not appear first when a due required challenge is active.

If multiple unexpected active sessions exist because of corrupted state or a prior bug, use deterministic reconciliation logic rather than choosing arbitrarily.

Document and test that reconciliation.

---

# 25. Math Challenge

Implement as pure testable core logic.

No multiple choice.

Typed numeric answers.

## Easy

Primarily:

- addition
- subtraction
- 1–2 digit operands

## Medium

- addition
- subtraction
- multiplication
- reasonable operand sizes

## Hard

- multiplication
- addition/subtraction
- reasonable multi-step expressions

Avoid absurd calculation sizes.

Configuration includes:

- difficulty
- required number correct

Default:

- Medium
- 5

Rules:

- wrong does not advance
- blank does not advance
- malformed does not advance
- correct advances once
- duplicate submission cannot double-count
- challenge completes only at threshold

Inject randomness.

Tests must be deterministic.

---

# 26. Memory Challenge

Implement as independent testable state machine.

Initial behavior:

1. generate numeric sequence
2. display for configured duration
3. hide
4. require exact recall

Suggested defaults:

- Easy: 4 digits
- Medium: 6 digits
- Hard: 8 digits

Configuration may include:

- difficulty
- sequence length
- display duration
- successful rounds required

Wrong answer:

- does not complete
- produces a fresh sequence

Lifecycle behavior must be explicit.

Do not reveal the sequence again merely because SwiftUI recreated a view.

If the app terminates during the memory challenge, restore or restart the round in a way that cannot accidentally expose the answer or mark success.

Persist enough state for correctness.

Inject time/randomness so tests do not sleep in real time.

---

# 27. QR Challenge

Use public camera APIs.

Create:

```text
QRCodeScanning
       ↑
AVFoundationQRCodeScanner
       ↑
FakeQRCodeScanner
```

Matching logic belongs outside the camera adapter.

Only the QR configured for that alarm succeeds.

Reject:

- unrelated QR
- another PuzzleAlarm QR
- empty data
- malformed values

## QR creation

Generate a unique challenge token.

Conceptually:

```text
puzzlealarm://challenge/<UUID>
```

Display the QR.

Allow normal save/share/print behavior through public iOS APIs.

Persist the expected payload.

Use an Apple QR-generation framework such as Core Image.

Include required camera usage description.

Handle:

- not determined
- authorized
- denied
- restricted
- unavailable
- interrupted

Simulator must not crash when camera hardware is unavailable.

Physical scanning remains DEVICE REQUIRED.

---

# 28. Challenge Coordinator

Implement a generic state machine.

Given:

```text
Memory → Math → QR
```

it must behave:

```text
Memory
↓
Math
↓
QR
↓
session completion
```

No custom navigation logic should be required for each permutation.

The coordinator manages challenge progression.

It must not know implementation details of:

- AVFoundation
- AlarmKit
- audio playback
- disk storage

Persist coordinator state through the session layer.

---

# 29. Annoying Alarm Sounds

Each AlarmDefinition has a selected sound.

Required Version 1 choices:

- supported system/default sound
- multiple bundled intentionally annoying sounds

Examples:

- harsh buzzer
- rapid beeps
- siren-like tone
- escalating alarm
- another distinct synthetic sound

Do not copy copyrighted commercial alarm assets.

Prefer deterministic self-generated audio resources.

If practical, create:

`Scripts/generate_alarm_sounds.py`

so assets are reproducible.

Use only free tooling.

## Preview

Alarm editor supports:

- Preview
- Stop Preview

Rules:

- only one preview at a time
- changing selection stops previous preview
- leaving relevant UI stops preview
- resource cleanup is guaranteed

## Imported audio

Treat imported audio as capability-gated.

Implement only if current public Apple APIs make it reliable without compromising core stability.

First probe:

- accepted locations
- formats
- duration constraints
- AlarmKit requirements

Never guess.

Bundled custom sounds are mandatory.

Imported user audio is optional if platform constraints make it disproportionately complex.

## Fallback

Invalid/missing custom sound must fall back safely.

Never silently fail to schedule the alarm merely because a custom sound resource is bad.

---

# 30. Persistence

Use simple local persistence.

Prefer Codable + atomic file replacement in Application Support unless a better simple native approach is clearly justified.

No remote backend.

Create a protocol with:

- production disk implementation
- in-memory test implementation

Persistence should support schema evolution.

Include a version field where appropriate.

Corrupt data must not crash the app.

Test:

- empty state
- valid state
- truncated file
- malformed JSON
- unknown enum values where applicable
- old schema version if migrations are introduced
- interrupted write behavior where practical

---

# 31. Clock, Calendar and Randomness

Avoid uncontrolled use of:

- `Date()`
- global random APIs
- implicit current calendar/timezone

inside important domain logic.

Inject abstractions where useful:

```text
ClockProviding
RandomProviding
CalendarProviding
```

Do not overengineer.

The goal is deterministic correctness.

---

# 32. Timezone and DST Semantics

Alarm scheduling is time-sensitive.

Define explicit semantics rather than hoping date arithmetic works.

AlarmDefinition represents a local wall-clock alarm.

Examples:

```text
6:30 AM Monday-Friday
```

Test next-occurrence calculations around:

- midnight
- month boundary
- year boundary
- spring DST gap
- fall DST repetition

If device timezone changes, do not silently claim behavior without verifying AlarmKit semantics.

Document the intended app behavior and mark platform-dependent timezone behavior DEVICE REQUIRED if necessary.

---

# 33. SwiftUI Screens

Keep interface native and focused.

## Alarm List

Show:

- time
- selected weekdays
- enabled state
- dismissal mode
- challenge summary
- selected sound
- next occurrence where practical

Actions:

- add
- edit
- enable/disable
- delete

## Alarm Editor

Configure:

- time
- weekdays
- dismissal mode
- challenge selection
- challenge order
- challenge settings
- sound
- sound preview

For challenge order provide accessible Move Up / Move Down controls even if drag/reorder is also supported.

## Challenge Screen

Display:

- Wake Up
- current challenge
- sequence progress
- challenge-specific progress

Do not provide:

- Skip
- Give Up
- Complete
- Back to Home

during a required session.

## Success

After full sequence:

`You're awake`

Only reach this state through the domain completion path.

---

# 34. DEBUG Test Harness

Create DEBUG-only testing utilities.

Never expose them in Release.

Useful controls:

- create fake due session
- launch Math
- launch Memory
- simulate valid QR
- simulate invalid QR
- preview bundled sounds
- inspect session state
- inspect backup plan
- trigger persistence reload
- simulate scheduling failure
- simulate cancellation failure
- schedule a real AlarmKit test alarm shortly ahead
- cancel test alarms
- reset local test state

The harness should help exercise failure conditions, not only happy paths.

---

# 35. Test Strategy

Use a test pyramid.

Prioritize:

1. pure unit/domain tests
2. integration tests
3. limited UI tests
4. physical-device acceptance tests

Target approximately 90%+ meaningful coverage for critical core logic where practical.

Do not inflate coverage with meaningless assertions.

Tests should verify behavior, not implementation trivia.

---

# 36. Mandatory Core Tests

At minimum test:

## Alarm Definition

- create
- edit
- enable
- disable
- delete semantics
- weekdays
- dismissal mode
- challenge order
- challenge configuration
- sound configuration
- Codable round trip

## Schedule

- next weekday
- weekend
- all days
- one day
- midnight
- 11:59 PM
- month boundary
- year boundary
- DST cases

## Backup Generation

For T:

```text
T
T+1
T+2
T+3
T+4
```

exactly.

## Math

- answer correctness
- difficulty bounds
- many deterministic generated cases
- blank rejection
- malformed rejection
- wrong-answer behavior
- correct progress
- duplicate submission
- completion threshold

## Memory

- generated length
- deterministic generation
- exact match
- mismatch
- fresh sequence after failure
- hidden-state lifecycle
- round count
- relaunch behavior

## QR

- correct target
- wrong target
- empty
- malformed
- another PuzzleAlarm QR
- duplicate scanner callbacks

## Challenge Sequence

Test every permutation of the three unique challenge types:

Single:

- Math
- Memory
- QR

Pairs:

- Math → Memory
- Memory → Math
- Math → QR
- QR → Math
- Memory → QR
- QR → Memory

Triples:

- all six permutations

Verify order strictly.

## WakeUpSession

- starts incomplete
- valid state transitions
- invalid transitions rejected
- partial challenge completion not sufficient
- final challenge completes
- completed cannot regress
- configuration snapshot is immutable
- duplicate completion call is safe

## Scheduling Transaction

- all five succeed
- primary failure
- each backup failure position
- rollback success
- rollback partial failure
- session never falsely reports armed

## Cancellation

- completion cancels remaining IDs
- partial challenge does not
- one cancellation failure does not stop others
- retry is safe
- duplicate cancellation is handled safely

## Edit/Disable/Delete

- disabling cancels future session alarms
- deleting cancels associated future alarms
- editing replaces future occurrence safely
- failed replacement does not create misleading UI state

## Persistence

- round trip
- partial progress
- relaunch
- completion
- scheduling-in-progress recovery
- cancellation-in-progress recovery
- corrupted state
- schema version handling

---

# 37. Property / Invariant Testing

Where practical, supplement example tests with invariant-style tests.

Examples:

For many generated Math problems:

```text
engineReportedAnswer == independentlyCalculatedAnswer
```

For challenge sequences:

```text
session.completed implies all configured challenges completed
```

For schedule plans:

```text
backup[i] == primary + i minutes
```

For AlarmDefinitions:

```text
decode(encode(model)) == model
```

Do not add a heavy property-testing framework merely for this.

Simple loops with deterministic seeds are acceptable.

---

# 38. Regression Rule

Every reproducible defect should become a regression test whenever technically possible.

Process:

```text
reproduce failure
↓
capture failing automated test
↓
confirm test fails
↓
fix root cause
↓
confirm focused test passes
↓
run impacted stage gate
↓
run affected earlier regression gates
```

If writing a regression test is impossible, document why.

---

# 39. Test Quality Audit

Passing tests can themselves be wrong.

At the end of every major stage, inspect newly written tests.

Ask:

- Would this test fail if the implementation were obviously wrong?
- Is it testing the output or merely checking that code executed?
- Does it accidentally duplicate production logic?
- Is it deterministic?
- Is it overly coupled to implementation details?
- Is a negative case missing?
- Is a race condition hidden by synchronous mocks?

Improve weak tests before passing the stage.

---

# 40. Integration Tests

Include:

- disk persistence
- coordinator + persistence
- scheduling transaction + fake AlarmScheduling
- completion + cancellation
- relaunch/reconciliation
- AlarmManagerService compilation
- QR scanner lifecycle where simulator-safe
- audio preview lifecycle where simulator-safe

AlarmKit real firing is not required for normal automated tests.

---

# 41. UI Tests

Keep UI automation limited to high-value flows.

## Create annoying alarm

```text
launch
→ add
→ select time
→ Annoying Alarm Only
→ select annoying sound
→ save
→ verify configuration
```

## Create challenge alarm

```text
launch
→ add
→ Challenges Required
→ configure Memory
→ configure Math
→ configure QR
→ reorder
→ select sound
→ save
```

## Complete challenge session

Use injected test services:

```text
Memory
→ Math
→ fake valid QR
→ success
```

## Relaunch

```text
partial session
→ app relaunch
→ correct challenge restored
```

## Edit alarm

Verify changes persist and future schedule replacement is represented correctly.

Do not attempt to emulate real lock-screen AlarmKit presentation through UI tests.

---

# 42. Code Quality Standards

Require:

- zero compile errors
- zero avoidable warnings in our code
- clear naming
- small cohesive responsibilities
- dependency injection for platform boundaries
- async/await
- intentional concurrency isolation

Avoid:

- giant views
- giant view models
- singleton business logic
- global mutable state
- unnecessary inheritance
- speculative generic abstractions
- force unwraps
- `try!`
- recoverable `fatalError()`
- duplicate rules
- callback pyramids
- disabled compiler diagnostics used to hide defects

Use `@MainActor` where UI isolation requires it, not everywhere.

Where the selected Swift toolchain supports strict concurrency checking, treat concurrency warnings seriously rather than disabling them.

---

# 43. Complexity Review Triggers

These are review triggers, not rigid limits.

If a source file grows beyond roughly 400–500 lines, ask whether it contains multiple responsibilities.

If a method/function grows beyond roughly 50–60 lines, ask whether its logic should be decomposed.

If a view model coordinates:

- persistence
- AlarmKit
- navigation
- QR
- audio
- challenge logic

it is almost certainly doing too much.

Do not refactor only to satisfy numerical limits.

Use judgment.

---

# 44. Resource / Performance Standards

Check for:

- duplicate scheduling
- runaway Tasks
- unnecessary MainActor work
- leaked camera sessions
- preview audio continuing after navigation
- stale timers
- repeated disk writes
- repeated full-state reloads
- duplicate observers
- retained closures creating cycles

Camera and audio resources must stop when no longer needed.

Prefer correctness over micro-optimization.

---

# 45. CI

Create:

`.github/workflows/ios.yml`

Use a currently available **free standard** GitHub-hosted macOS runner capable of building the selected iOS SDK.

Do not assume one runner label forever.

At CI runtime print:

```text
sw_vers
xcodebuild -version
xcodebuild -showsdks
swift --version
```

Generate the Xcode project.

Run:

1. core build/tests
2. iOS project generation
3. Simulator build
4. iOS tests
5. integration tests
6. critical UI tests
7. formatting/lint checks chosen for the project

Do not hard-code a simulator model that may disappear.

Discover available compatible destinations using tools such as:

```text
xcrun simctl list devices available
xcodebuild -showdestinations
```

Select an available iPhone Simulator deterministically.

---

# 46. CI Evidence Rule

Do not say "CI passes" unless the evidence corresponds to the current code revision.

A prior green workflow is invalid evidence after relevant code has changed.

If GitHub workflow results are accessible:

- inspect the current run
- record run status

If they are not accessible:

- run everything locally that the environment supports
- label macOS CI as pending rather than pretending it passed

---

# 47. CI Failure Recursion

When CI fails:

1. read the actual failing log
2. classify failure
3. reproduce locally where possible
4. fix root cause
5. rerun focused validation
6. rerun full relevant CI

Classify failures as:

- source-code defect
- test defect
- project-generation defect
- environment/toolchain defect
- dependency/tool-version defect
- flaky test
- Apple SDK/API mismatch

Do not blindly rerun CI hoping it turns green.

A flaky test must be investigated.

Do not simply add retries unless the underlying behavior is inherently asynchronous and bounded retry is justified.

---

# 48. Formatting / Lint

Use free tooling only.

Prefer tooling already available with Swift/Xcode where practical.

Do not burden the project with a complex lint stack.

At minimum enforce:

- consistent formatting
- no unused imports
- no abandoned commented-out code
- no obvious dead code
- no accidental credentials/secrets
- no generated binaries committed unnecessarily

---

# 49. Device-Build Artifact

Normal CI should not require Apple signing credentials.

When ready:

- compile a generic iOS Release build with signing disabled where supported
- package an unsigned app/IPA only where technically valid
- keep artifact retention short
- document exactly how the artifact was produced

Never claim an unsigned artifact has been successfully sideloaded until that has actually been tested.

---

# 50. No-Mac Rule

Any change touching:

- SwiftUI
- AlarmKit
- AVFoundation
- App Intents
- iOS resources
- Xcode project generation
- iOS-specific persistence

is not considered implementation-verified until macOS/Xcode CI compiles it.

Linux-only success does not verify iOS integration.

---

# 51. Documentation

Maintain:

## README.md

- purpose
- feature set
- free development constraints
- architecture
- build/test instructions
- status

## ARCHITECTURE.md

- core/platform boundary
- session state machine
- scheduling architecture
- challenge coordinator
- persistence
- QR
- audio
- critical invariants

## PROJECT_STATE.md

Persistent recursive-engineering state.

## TEST_MATRIX.md

Evidence/status matrix.

## DEVICE_TEST_PLAN.md

Physical iPhone acceptance checklist.

## DEVELOPMENT_LOG.md

Concise stage records.

---

# 52. DEVELOPMENT_LOG Format

After each gate:

```text
Stage:
Attempt:
Status:

Changes:
Tests added/changed:
Commands executed:
Focused validation:
Full gate result:
Regression gates rerun:
Self-review findings:
Adversarial-review findings:
Invalidated prior gates:
Known limitations:
Device validation remaining:
Next action:
```

Do not turn it into an essay.

---

# 53. Stage-Gated Development

Proceed in order unless recursive invalidation requires moving backward.

---

## STAGE 0 — Repository / Environment

Create:

- Swift package
- iOS directories
- project.yml
- CI skeleton
- docs
- .gitignore
- PROJECT_STATE

### Gate 0

Verify:

- structure coherent
- Package.swift parses
- basic Swift tooling works
- CI YAML is structurally valid as far as environment permits
- no paid dependency
- no secrets
- project state initialized

Run self-review and adversarial review.

---

## STAGE 1 — Core Domain

Implement:

- AlarmDefinition
- dismissal mode
- challenge configurations
- sound model
- WakeUpSession
- explicit session states
- challenge sequence
- backup plan generator
- schedule calculations
- clock/random/calendar abstractions where useful

No AlarmKit.

No camera.

No UI.

### Gate 1

Run core tests.

Verify invariants.

Run Codable round-trip tests.

Run schedule boundary tests.

Self-review model complexity.

Do not advance if the model cannot represent partial scheduling/recovery correctly.

---

## STAGE 2 — iOS Shell + Real CI

Create smallest SwiftUI application.

Generate through XcodeGen.

Establish actual Xcode CI.

### Gate 2

Required:

- generation succeeds
- core tests pass
- app target compiles
- Simulator build succeeds
- current CI evidence recorded

If XcodeGen configuration is awkward, fix it now rather than accumulating workarounds.

---

## STAGE 3 — AlarmKit Capability / Compile Spike

Implement minimal AlarmManagerService.

Probe:

- authorization
- scheduling API
- cancellation API
- metadata support
- App Intent requirements
- supported sound APIs
- current SDK type signatures

### Gate 3

Required:

- actual SDK compile
- fake scheduler tests
- existing tests green
- API assumptions documented

Real alarm firing remains DEVICE REQUIRED.

If AlarmKit disproves domain assumptions, RECURSE to Stage 1.

---

## STAGE 4 — Persistence

Implement disk persistence plus in-memory test storage.

Support partial lifecycle states.

### Gate 4

Test:

- valid state
- partial scheduling
- incomplete session
- challenge progress
- completion
- malformed state
- interrupted/recovery scenarios

If the persistence design cannot safely recover operations, fix it before UI work.

---

## STAGE 5 — Scheduling Transaction + Recurrence

Implement:

- challenge occurrence creation
- transactional five-alarm scheduling
- rollback
- annoying-only recurring strategy
- next challenge occurrence scheduling
- edit/disable/delete behavior

### Gate 5

Test all failure injection cases.

Use fake scheduler capable of failing on configurable calls.

Verify no false armed state.

Verify idempotency.

If the design requires changing WakeUpSession, RECURSE.

---

## STAGE 6 — Alarm Management UI

Implement:

- list
- add
- edit
- delete
- enable/disable
- weekdays
- mode
- challenge editor
- ordering
- sound picker shell

### Gate 6

UI tests.

Persistence tests.

Accessibility labels.

Scheduling actions through injected services.

No direct AlarmKit business logic in views.

---

## STAGE 7 — Challenge Framework

Implement generic ChallengeCoordinator.

### Gate 7

Test all allowed challenge sequence permutations.

Test relaunch restoration.

Test invalid progression attempts.

Verify coordinator has no AVFoundation/AlarmKit/audio implementation knowledge.

---

## STAGE 8 — Math

Implement fully.

### Gate 8

Test:

- generation
- answers
- difficulties
- progress
- duplicate submit
- completion
- persistence
- UI smoke flow

---

## STAGE 9 — Memory

Implement fully.

### Gate 9

Test:

- deterministic sequence
- timing state
- hiding
- wrong answer
- new sequence
- interruptions
- relaunch
- no answer leakage
- UI flow

---

## STAGE 10 — QR

Implement:

- QR creation
- display/share
- matching
- scanner protocol
- AVFoundation adapter
- fake scanner
- permissions

### Gate 10

Automated and Simulator tests green.

Actual physical camera remains DEVICE REQUIRED.

---

## STAGE 11 — Audio

Implement:

- default sound
- bundled generated sounds
- preview
- cleanup
- AlarmKit sound integration
- fallback

Probe imported audio separately.

### Gate 11

Verify:

- resource files exist
- selections persist
- missing file fallback
- preview lifecycle
- AlarmKit compilation

Actual alarm playback remains DEVICE REQUIRED.

---

## STAGE 12 — App Intent / Wake-Up Routing

Implement real routing from alarm interaction into active session.

Build foreground reconciliation.

### Gate 12

With mocks:

- active due session opens challenge
- no session opens normal UI
- completed session does not reopen challenge
- interrupted cancellation resumes
- duplicate route events are idempotent

Compile real App Intent integration.

Physical launch behavior remains DEVICE REQUIRED.

---

## STAGE 13 — Full Orchestration

Connect:

```text
AlarmDefinition
↓
next occurrence
↓
WakeUpSession
↓
transactional primary + backups
↓
AlarmKit
↓
launch/reconciliation
↓
ChallengeCoordinator
↓
complete sequence
↓
idempotent cancellation
↓
schedule next occurrence
↓
success
```

### Gate 13

Mandatory scenarios:

#### A

All five alarms schedule successfully.

#### B

Partial scheduling fails and rolls back.

#### C

Primary alarm is stopped but session remains incomplete.

#### D

Only first challenge completes; backups remain.

#### E

Full sequence completes; cancellations attempted.

#### F

One cancellation fails; remaining cancellations continue.

#### G

App dies during completion and recovers idempotently.

#### H

App dies during scheduling and reconciles.

#### I

Editing alarm reschedules future occurrence correctly.

#### J

Disabling alarm prevents next occurrence.

All automated tests must pass.

---

## STAGE 14 — Resilience / Failure Injection

Systematically inject failures around:

- disk reads
- disk writes
- scheduling
- cancellation
- duplicate callbacks
- lifecycle interruptions
- malformed persistence
- camera availability
- audio resource failure

### Gate 14

No crash.

No false success.

No false armed state.

No bypass of challenge-completion invariant.

Recovery behavior documented.

---

## STAGE 15 — Architecture / Quality Audit

Perform deliberate review.

Search for:

- duplicate logic
- growing god objects
- mixed platform/domain responsibilities
- excessive file size
- persistence races
- actor/isolation mistakes
- duplicate scheduling
- resource leaks
- unbounded async work
- dead code
- debug leaks
- unnecessary wrappers
- workarounds compensating for earlier bad models

Refactor where evidence justifies it.

Any refactor invalidates relevant tests until rerun.

### Gate 15

Everything green after refactor.

---

## STAGE 16 — End-to-End Simulator

Run mocked E2E flows.

### Annoying Alarm

```text
create
→ select annoying sound
→ save
→ edit
→ disable
→ re-enable
```

### Challenge Alarm

```text
create Memory → Math → QR
→ arm
→ simulate due alarm
→ Memory
→ Math
→ fake QR
→ completion
→ cancellations
→ next occurrence
```

### Relaunch

```text
partial session
→ relaunch
→ reconcile
→ resume exact correct state
```

### Failure Recovery

```text
simulate cancellation interruption
→ relaunch
→ finish reconciliation safely
```

### Gate 16

No known critical Simulator bug.

All automated suites green.

---

## STAGE 17 — Recursive Final Audit

Before declaring DEVICE READY, perform a full-project recursive review.

Do not assume earlier gates are still valid.

Review:

1. product requirements
2. architecture
3. tests
4. current CI
5. persistent state model
6. scheduling
7. challenge flows
8. permissions
9. audio
10. camera
11. error handling
12. recovery logic
13. documentation

Then ask:

> What are the five most likely remaining defects in this application?

For each:

- determine whether an automated test can challenge it
- add the test if justified
- fix any failure
- rerun affected gates

Then ask:

> What earlier architectural assumption would be most damaging if wrong?

Revalidate it.

Then ask:

> Is any feature marked verified based only on mocks when stronger evidence is available?

Correct the evidence status.

### Gate 17

All applicable automated validation green.

Current macOS/Xcode CI green.

Evidence ledger accurate.

---

## STAGE 18 — Device-Ready Artifact

Create unsigned Release artifact where technically appropriate.

Do not add paid signing.

Document creation process.

Status becomes:

`DEVICE READY — NOT DEVICE VERIFIED`

Never skip the second half of that label.

---

# 54. Physical iPhone Acceptance Plan

Actual device tests eventually include:

## AlarmKit authorization

- first request
- allow
- deny
- recovery

## Alarm firing

Test:

- unlocked
- locked
- foreground
- background
- app terminated
- Silent Mode
- Focus

## Challenge launch

Verify AlarmKit action routes correctly.

## Backup chain

```text
primary fires
→ stop it
→ do not complete challenge
→ backup fires
```

## Completion

```text
solve all challenges
→ backups canceled
→ no later backup fires
→ next configured recurrence remains valid
```

## QR

- correct QR
- wrong QR
- another PuzzleAlarm QR
- low light
- permission denied
- permission granted

## Audio

Every bundled sound:

- intended sound used
- lock-screen behavior
- fallback behavior

## Relaunch

Terminate during:

- Math
- hidden Memory
- QR
- cancellation

Verify proper recovery.

Record actual observations.

---

# 55. Device-Test Feedback Recursion

Physical-device testing is not merely the last checkbox.

Any device failure restarts the same recursive engineering process.

Example:

```text
device backup alarm fails
↓
capture exact observation
↓
determine whether scheduling, AlarmKit semantics, or lifecycle assumption is wrong
↓
add automated reproduction if possible
↓
return to earliest affected stage
↓
fix
↓
rerun automated gates
↓
produce new device build
↓
repeat physical test
```

A device failure may invalidate earlier Simulator/automated assumptions.

Update PROJECT_STATE accordingly.

---

# 56. Final Version 1 Features

Required:

## Alarm Management

- create
- edit
- delete
- enable/disable
- weekdays

## Modes

- Annoying Alarm Only
- Challenges Required

## Challenges

- Math
- Memory
- QR

## Challenge configuration

- choose challenge types
- reorder
- configure each

## Sound

- system/default
- several bundled annoying sounds
- preview
- safe fallback
- imported audio only if current platform APIs make it reliable

## Challenge Alarm Behavior

- primary
- four backups
- persistent occurrence session
- recovery across relaunch
- only full challenge sequence completes session
- cancellation of current occurrence backups
- scheduling of next recurring occurrence

## QR

- generate/register target
- share/save
- exact matching
- camera scan

## Engineering

- unit tests
- integration tests
- UI tests
- CI
- Simulator validation
- physical-device plan
- regression suite
- recursive state/evidence tracking

---

# 57. Explicitly Out of Scope

Do not add:

- accounts
- cloud sync
- social network
- leaderboards
- achievements
- sleep tracking
- HealthKit
- nutrition
- AI-generated challenges
- advertisements
- subscriptions
- payments
- backend
- Android
- Apple Watch
- smart-home integration
- unnecessary statistics
- unnecessary theming
- arbitrary feature expansion

---

# 58. Security / Platform Rules

Never:

- use private APIs
- exploit iOS
- prevent uninstalling
- block shutdown
- bypass system security
- fake permissions
- store Apple credentials
- commit signing secrets
- implement malicious persistence
- claim Apple's system stop controls can be removed when they cannot

PuzzleAlarm may intentionally make its own challenge flow difficult to bypass while remaining compliant with iOS.

---

# 59. Decision Rule for New Abstractions

Before adding an abstraction ask:

> Does this materially improve correctness, testability, lifecycle recovery, or isolation of an Apple framework?

If no:

do not add it.

Prefer straightforward code.

Avoid architecture theater.

---

# 60. Autonomous Work Style

Operate autonomously through routine engineering decisions.

Do not repeatedly ask the user to choose implementation details that can be resolved through:

- the specification
- current SDK behavior
- tests
- standard engineering judgment

When uncertain:

1. inspect evidence
2. perform a small probe
3. compile/test
4. decide from results

Ask the user only when a true product decision cannot be inferred and materially changes intended behavior.

Do not ask simply because implementation is difficult.

---

# 61. No Hallucinated Success

Never report:

- tests passed when they were not run
- CI passed when current CI was not observed
- AlarmKit works on device when only compiled
- camera works when only mocked
- sound works on lock screen when only previewed
- an IPA installs when installation was not tested
- a bug is fixed when the reproduction was not rerun

Use precise status language.

---

# 62. First Action

Start by reading:

1. repository contents
2. `docs/PROJECT_STATE.md` if it exists
3. `docs/DEVELOPMENT_LOG.md` if it exists
4. current git status/diff
5. existing tests
6. existing CI configuration

If the repository is empty:

begin at Stage 0.

If work already exists:

audit it against this specification.

Determine the earliest stage that is actually supported by evidence.

Do not assume previously written code is correct merely because it exists.

Do not unnecessarily recreate good work.

Set PROJECT_STATE to the earliest defensible current stage.

Then proceed through the recursive development controller.

The target before physical testing is:

> A clean, reproducible, current-CI-green native iOS PuzzleAlarm application in which all hardware-independent functionality is backed by current evidence, all platform-dependent claims are clearly marked, and any discovered defect automatically causes the development process to recurse to the earliest affected layer rather than accumulating patches on top of an invalid foundation.