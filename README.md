# PuzzleAlarm

A planned personal native iPhone alarm app for iOS 26+, SwiftUI and AlarmKit.
Modes: ordinary alarms with selected sounds, or an ordered Math / Memory / QR
challenge sequence backed by a primary alarm and four independent backup alarms.

**Status: Stage 0 scaffold created; Gate 0 BLOCKED. This is not a usable alarm app.**
No Swift build, unit test, Xcode build, Simulator flow or device test has run.

## Start here

- [Authoritative specification](docs/MASTER_PLAN.md)
- [Current state and blockers](docs/PROJECT_STATE.md)
- [Evidence matrix](docs/TEST_MATRIX.md)
- [Development log](docs/DEVELOPMENT_LOG.md)

## Development

Pure logic will live in the dependency-free PuzzleAlarmCore Swift package.
Platform integration will live under PuzzleAlarm. XcodeGen project.yml is currently
a definition skeleton with no app target; the SwiftUI shell belongs to Stage 2.

With Swift 6+ installed, from this directory:

```sh
swift --version
swift package dump-package
swift build -Xswiftc -warnings-as-errors
```

There are no domain tests yet. Stage 1 must add a test target and run swift test.
A successful empty-module build proves tooling only.

The Stage 0 workflow can run on a public GitHub repository's standard macOS runner.
It skips private repositories to avoid assuming a paid minutes allowance.
It prints tool versions, parses the manifest and builds the scaffold.
No repository remote is configured and no workflow has been observed.
Stage 2 must add XcodeGen installation with a pinned version, iOS 26 SDK selection,
project generation, discovered iPhone Simulator destination, builds and tests.

No paid services, Apple membership, signing credentials, backend or telemetry.
Physical installation with personal provisioning remains an unverified capability;
do not assume AlarmKit availability or successful sideloading.

This directory is independent of Investment Dashboard. Adding it to the app's
project sidebar remains a manual app action.

## Sources checked during setup

- [Swift Windows prerequisites](https://www.swift.org/install/windows/manual/)
- [GitHub standard runner cost rules](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

See the evidence ledger for what was actually executed.
