# Architecture intent

This document records planned boundaries, not implemented functionality.
The full requirements are in MASTER_PLAN.md.

PuzzleAlarmCore will hold Codable/Sendable domain data, explicit occurrence state,
challenge engines, ordered progression and deterministic schedule calculations.
PuzzleAlarm will own SwiftUI and thin AlarmKit, App Intents, AVFoundation and local
atomic-file adapters. No external services or paid dependencies.

Annoying-only mode should use AlarmKit recurrence where supported. Challenge mode
plans one occurrence with five independent one-time alarms at T through T+4 minutes.
An occurrence snapshots its definition, challenge order and sound.
Stopping a system alarm must not complete a challenge session.

Planned lifecycle: planned → scheduling → armed → active → completing → completed,
plus explicit scheduling/rollback/cancellation failure states. Full sequence
completion and cancellation reconciliation need distinct durable evidence.
Exact types are deferred to Stage 1 tests and the Stage 3 SDK probe.

Before platform calls, persist planned stable IDs. Reconcile uncertain outcomes
after a crash using actual SDK capabilities; do not infer that an unacknowledged
schedule failed. Cancellation should continue after individual failures and retain
retryable state. Never display a partially scheduled chain as armed.

Persistence will be versioned, local and atomic with malformed-data handling.
QR matching is pure logic; the camera only supplies payloads. Audio preview owns
resource cleanup separately from AlarmKit sound configuration.
All of these statements are intended design, not verified implementation.
