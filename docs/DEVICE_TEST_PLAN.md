# Physical iPhone acceptance plan

Status: DEVICE REQUIRED for every item. No device test has run.

Record app revision, iPhone model, iOS version, provisioning method, exact steps,
timestamps, observed result and logs without personal credentials.

- Prove free personal provisioning and required AlarmKit capabilities first.
- Authorization: first launch, allow, deny, recovery.
- Firing: unlocked/locked; foreground/background/terminated; Silent Mode; Focus.
- Challenge intent launch routes to the due occurrence and current challenge.
- Stop primary without solving: independent backup still fires.
- Complete only first challenge: backups remain.
- Complete all challenges: cancellation finishes and no later sibling fires.
- Next enabled recurring occurrence remains valid.
- QR: correct, wrong, another PuzzleAlarm target, low light, permission denied,
  granted, interrupted and unavailable.
- Each bundled sound, fallback and lock-screen playback.
- Terminate during Math, hidden Memory, QR, scheduling and cancellation; restore.
- Timezone change and DST: compare desired and actual AlarmKit behavior.

A failure invalidates the earliest affected assumptions and dependent gates.
Never report DEVICE PASS from mocks, compilation or Simulator observations.

## Stage 5 additions — DEVICE REQUIRED, not yet run

- Terminate between durable intent, OS schedule/cancel and local acknowledgment.
- Measure actual snapshot freshness, delayed effects and same-ID retry behavior.
- Verify ordinary relative weekly recurrence versus fixed one-time scheduling.
- Verify pending edit replacement and old retirement under OS capacity/error limits.
- Check due/degraded challenge preservation after Stop and missing siblings.
- File protection must surface storage failure without assuming alarms are absent.
- The application must use one lifecycle owner; concurrent extensions/processes
  need separate design/validation before enabling lifecycle calls there.
No Stage 5 mock, compile or Simulator result is DEVICE PASS.

## Stage 6 additions — DEVICE REQUIRED, not run

- Intentional Allow Alarms / enabled Save / Enable permission prompt; no startup prompt.
- Denied access and the public Settings action, then authorization refresh on return.
- Foreground reconciliation while a real schedule/cancellation is pending.
- Real file-protection/storage errors displayed without reset or false healthy state.
- Actual replacement overlap/capacity and lifecycle warnings after platform failures.
- VoiceOver and largest Dynamic Type on physical hardware in addition to Simulator controls.
- Real scheduling/firing, Stop, snapshot freshness, intent delivery and sound remain unproved.

The native list and configuration forms do not implement challenge execution or
final due-session/intent routing. A visible unfinished session is not a completion
or bypass path. Sound names select future resource identifiers; playback is not tested.
