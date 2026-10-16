# Physical iPhone acceptance plan

## Stage 10 QR checklist (DEVICE REQUIRED / NOT RUN)

- Save a QR alarm, share/save/print its image and scan both screen and paper under
  varied lighting/distance. Another alarm's code and unrelated/malformed/normalized
  values must never advance. Confirm saved token survives edit/relaunch.
- Verify user-selected Save Image's add-only Photos purpose/prompt, denial and retry;
  displaying the code or opening sharing must not request camera/Photos access.
- Verify actual permission prompt, allow/deny/restricted policy, Settings revocation
  and regrant. Retry must recheck access without skipping QR or cancelling backups.
- Interrupt with background/lock/app switch, another camera client and system capture
  interruption/runtime error. Camera must stop, explicit retry safely resumes, and stale
  permission/metadata callbacks must not finish another challenge.
- Recreate navigation and terminate/relaunch before/after matching; interruption grants
  no progress, durable success restores, and pending cleanup is displayed truthfully.
- Test QR before/between/after Math and Memory with actual primary/four backups. Only
  the complete sequence triggers cleanup; failed cleanup remains recoverable.
- Verify preview framing/rotation, VoiceOver/Dynamic Type, native share/save/print,
  thermal/resource release and privacy indicator. Injected Simulator capture and image
  decoding do not prove these hardware/system behaviors. Existing AlarmKit delivery,
  Silent/Focus/file-protection/power-loss/intent checks remain open. Stage 11 is out of scope.

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


Gate 6 automated boundary: revision 73971f054d4e74949e6aa0eb32aa026d0d6dc93d,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/37728785501 passed all nine
native UI tests and platform/unit checks with injected external effects. This does
not satisfy any DEVICE REQUIRED item above. No physical iPhone validation was run.
Stage 7 challenge execution is not implemented and is outside this acceptance.

## Stage 7 framework boundary — DEVICE REQUIRED, not run

Core coordination is tested with supplied trusted events and encoded session state.
No challenge engines, final routing or execution UI exists yet. Future device work
must verify termination during each engine phase, durable commits before presenting
progression, stale callbacks across occurrence routing, and real backup cleanup
only after every challenge succeeds. Core tests are not camera/audio/device evidence.

## Stage 8 Math — DEVICE REQUIRED, not run

The Math engine and native typed-answer UI are implemented. Automated/Simulator
evidence covers supplied active sessions, persistence and injected alarm cleanup;
it does not establish real AlarmKit delivery, intent routing, power-loss durability
or file protection. No physical iPhone action is required for Gate 8's automated
acceptance; these device checks remain open for the later device gate:

- Open a due Math session, type positive/negative answers with the real keyboard,
  and check VoiceOver/largest Dynamic Type in portrait and landscape.
- Terminate during a problem and after accepted progress; verify exact UUID/prompt,
  count and immutable configuration restore without bypassing later challenges.
- Interrupt storage/cleanup under actual file protection; verify a failed answer
  does not advance and pending cleanup never displays completed wake-up.
- After all configured challenges succeed, verify all five real alarms are cleaned
  and the recurrence policy is respected. No CI/Simulator result proves this.

At this historical Stage 8 record, Stage 9 had not begun. No Memory, camera, audio or final intent-routing claim was added.

## Stage 9 Memory — DEVICE REQUIRED, not run

- Verify configured reveal duration, hidden screen and typed leading-zero recall on
  real hardware with VoiceOver and largest Dynamic Type, portrait/landscape.
- Interrupt visible/hidden rounds using lock, home, app switcher, background and kill;
  reopen without re-reveal, progress loss or automatic success. Inspect OS snapshots.
- Interrupt writes under file protection/power loss; failed hiding must keep the UI
  concealed and failed submissions must not advance or replace the committed round.
- Check wall-clock changes during reveal and after expiry without answer reappearance.
- Check wrong recall gets different digits, and later configured challenges/real backup
  cleanup remain mandatory. No build, mock, CI or Simulator result satisfies this list.

Gate 9 is automated/Simulator acceptance; no physical device action is requested now.
QR/camera, audio and final intent routing remain later gates. Stage 10 NOT STARTED.

Gate 9 automated/Simulator boundary: 017218e893a72125b85402336adebb1c965b00ea,
https://github.com/teejayishere/PuzzleAlarm/actions/runs/38334048094 passed both Memory
UI flows and full regression checks using injected alarm effects. None of the
DEVICE REQUIRED items above is satisfied by that workflow. Physical iPhone NOT RUN.

## Stage 11 Audio — DEVICE REQUIRED / NOT RUN

For system default and every bundled sound, verify an actual AlarmKit primary and
backup uses the intended tone, in ordinary/challenge modes, locked/unlocked,
foreground/background/terminated, Silent Mode and Focus. Test fallback with a
controlled missing/invalid resource build; a mock name/default assertion is not
proof of daemon fallback or audible delivery. Check next recurrence/cleanup too.
Check preview identity and comfortable volume on real hardware; Stop, selection,
Save/Cancel, pushed navigation, sheet dismissal, home/lock, call interruption,
headphones/Bluetooth route changes and media reset must stop with no auto-resume.
Check VoiceOver, large text and screen rotation. Default preview explains that its
exact tone is heard at firing. Preview respects ambient/Silent semantics; AlarmKit
behavior needs its own observations. No device observation has been supplied yet.
Optional import is deferred. No Stage 12 action/routing acceptance is implied.

Stage 11 regression boundary: explicitly verify native Toggle thumb tap/drag and
label activation on an iPhone, including enable/failure/retry/disable/re-enable.
On iOS 26.5 Simulator an internal glass lens received began/ended while active
without dispatching its binding; the semantic label path is verified separately.
No passing label-based UI flow proves physical thumb behavior or fixes that
framework interaction. Record both input paths and resulting persisted/OS state.
