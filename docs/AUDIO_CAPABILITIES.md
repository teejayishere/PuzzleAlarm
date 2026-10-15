# Stage 11 audio capability probe

The existing installed SDK evidence in ALARMKIT_CAPABILITIES supplies the public
ActivityKit `AlertSound.default` and `named(_:)` signatures already compiled by the
AlarmKit spike. Stage 11 reuses those signatures; no new AlarmKit API is invented.
Current Apple references checked 2026-10-14:

- [AlarmKit WWDC25](https://developer.apple.com/videos/play/wwdc2025/230/)
  identifies ActivityKit sound names and bundle / Library/Sounds locations.
- [Named sound](https://developer.apple.com/documentation/activitykit/alertconfiguration/alertsound/named(_:))
  documents a local filename, not an arbitrary document-provider URL.
- [Custom notification sounds](https://developer.apple.com/documentation/usernotifications/unnotificationsound)
  describes linear PCM, CAF/AIFF/WAV and under-30-second alert assets. This is
  conservative format guidance, not evidence that AlarmKit playback works.
- [Audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)
  informs preview interruption cleanup; previews never resume automatically.

Generated assets are original deterministic 4-second 22050Hz mono signed 16-bit
LPCM CAF, with fades/headroom. The generator uses only Python's standard library.
CI checks byte identity and AVAudioFile decodes every built bundle resource. The
runtime rejects missing, undecodable, empty or >=30-second files before selecting
the AlarmKit name. Fallback chooses `.default` without rewriting persisted settings
or swallowing scheduler errors. Actual custom/default playback remains DEVICE REQUIRED.

Import probe is separate from product implementation: location support exists for
Library/Sounds, but arbitrary provider formats/durations need validated conversion,
durable copying and deletion ownership, plus real AlarmKit acceptance evidence.
No reliable end-to-end imported-file acceptance can be established in this Windows /
unsigned Simulator environment. Optional importing is deferred; no import UI or
unsupported URL is exposed. Bundled custom sounds remain mandatory and implemented.

There is no documented public API here for rendering the exact AlarmKit default
tone in the foreground. Selecting default retains `.default`; Preview explains that
the system tone is heard when the alarm fires rather than substituting another tone.
Bundled preview uses one AVAudioPlayer with reduced volume and ambient session,
respecting Silent Mode, and has no background mode. Selection changes, Save, Cancel,
navigation, dismissal, inactive/background, interruption, route change and media
reset stop/release playback and relinquish an activated audio session. Preview and
camera are independent; no recording category or microphone permission is used.
