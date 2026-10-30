# PuzzleAlarm

Personal native iPhone alarm application under development for iOS 26+.
The planned app offers ordinary alarms with selected sounds or ordered Math,
Memory and QR challenges backed by one primary and four independent backup alarms.

**Current status is maintained only in the [active restart PROJECT_STATE](https://github.com/teejayishere/PuzzleAlarm/blob/codex/restart-gate5-20261029-f8a41c/docs/PROJECT_STATE.md).**

Use the default branch `codex/restart-gate5-20261029-f8a41c`. Gates 0–5 are the
inherited accepted baseline; Stage 6 and Gate 6 are NOT STARTED. The next implementation
scope is an independent Stage 6 rebuild, stopping after Gate 6. Main and all other
branches are HISTORICAL / ABANDONED: no development, recovery or promotion there.
Old Stage 6–14 failures and budgets are nonbinding. See the
[branch and local entry-point inventory](docs/DOCUMENTATION_RECONCILIATION.md).

## Evidence and scope

See [PROJECT_STATE](docs/PROJECT_STATE.md) for exact revisions and CI runs.
[TEST_MATRIX](docs/TEST_MATRIX.md) distinguishes automated evidence from unimplemented
platform features. [MASTER_PLAN](docs/MASTER_PLAN.md) is the authoritative specification.

See [ALARMKIT_CAPABILITIES](docs/ALARMKIT_CAPABILITIES.md) for historical installed-SDK
evidence and device-only limits. The app still opens a title screen; no real alarm
behavior is verified on a physical device.

Implemented in dependency-free PuzzleAlarmCore:

- Validated alarm definitions, modes, unique ordered challenge configurations and sound identifiers.
- Immutable occurrence snapshots with explicit scheduling, challenge and cancellation states.
- Stable planned alarm IDs, in-flight outcome tracking, retryable cancellation and retirement.
- Deterministic local-time scheduling with explicit Gregorian calendar/timezone and DST rules.
- Exactly five backup-plan entries at T, T+60s, T+120s, T+180s and T+240s.
- Codable validation, recovery-state round trips and behavioral/invariant tests.
- Versioned atomic persistence and a durable lifecycle operation journal.
- Transactional scheduling, rollback, recurrence, edit/disable/delete and recovery
  through an injected scheduler, with Stage 5 automated evidence.

The iOS boundary contains the AlarmKit adapter and compile-spike App Intent.
Lifecycle orchestration is not connected to product UI/startup. Challenge engines,
product UI, final intent routing, camera and sound files belong to later gates.
No real alarm, device installation or camera/audio behavior has been verified.

## Free CI-first development

[Public repository](https://github.com/teejayishere/PuzzleAlarm) /
[GitHub Actions](https://github.com/teejayishere/PuzzleAlarm/actions/workflows/ios.yml).

CI uses a standard macos-26 runner, prints macOS/Xcode/SDK/Swift versions, parses
the package, builds with warnings as errors, runs Swift tests and reports core
line coverage. It also generates the Xcode project, builds the iOS app and runs
platform capability, disk persistence, lifecycle integration and shell-launch tests.
Exact revision-specific counts belong in the evidence ledger. No paid runners, runtime dependencies or signing
credentials. Private-repository execution is guarded out to preserve the $0 rule.

A local Mac or large Windows Swift toolchain is unnecessary for ordinary work.
With Swift 6+ available, equivalent core commands are:

```sh
swift package dump-package
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors --enable-code-coverage
python3 Scripts/report_core_coverage.py "$(swift test --show-codecov-path)"
```

The package's macOS 13 minimum supports host-side testing. Both package and iOS
app declare an iOS 26 minimum. project.yml is the source of truth for the native
app and its platform/unit and launch-test targets. Generated projects and Info.plist are ignored.

On macOS with Xcode, bash Scripts/install_xcodegen.sh downloads checksum-pinned
XcodeGen 2.44.1 and prints its executable path. Run that executable with
`generate --spec project.yml`. See .github/workflows/ios.yml for complete build
and test commands. CI discovers a compatible available iPhone Simulator and
selects the runner's native architecture; no fixed model is required.

The shell displays only PuzzleAlarm. CI confirms the package dependency compiles
for iOS and the shell launches, not physical-device functionality. The diagnostic
check rejects compiler/destination warnings and explicitly reports Xcode's expected
metadata-extraction advisory for the UI-test bundle without AppIntents. The app itself extracts App Intents metadata.

## Engineering rules

Fetch origin and read the remote restart PROJECT_STATE first, then [AGENTS.md](AGENTS.md)
and [CONTRIBUTING](CONTRIBUTING.md). Existing successful CI may be reused when its SHA
matches an unchanged HEAD; a parent run never validates a new commit. Record a new
bounded $0 budget before any new validation. Invalidated assumptions
send work back to the earliest affected gate. Full device validation remains
[DEVICE REQUIRED](docs/DEVICE_TEST_PLAN.md), including free personal provisioning.

This standalone directory/repository is separate from Investment Dashboard.
No accounts, backend, telemetry, payments or App Store infrastructure are planned.

[GitHub standard runner rules](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
confirm standard public-repository runner usage is free.
