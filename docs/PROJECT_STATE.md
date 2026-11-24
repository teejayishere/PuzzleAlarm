# Active restart project state

Owner-approved autonomous milestones: COMPLETION_PLAN. First target all-three
playable Appetize, then physical iPhone verification. Requirements/invariants and
restart lineage preserved; diagnostic probes remain separate from product checks.

## Verified playable candidate

Source90ad2b09457c1a35cb070c19db3ff9a2d5011962 /run45304649847 SUCCESS.
137Core tests (6suites),44app-unit tests and3UI journeys PASS: native time cancel,
time/sound save+relaunch, and full Math→Memory→QR including wrong QR rejection,
completion and return to list. Simulator preview/install/launch/package and unsigned
Release iPhone build PASS. Artifact14879999361 (see exact run artifact metadata),
inner SimulatorZIP1747677bytes, SHA256 from preserved SHA256.txt. Downloaded all
packages; inner ZIP/IPA CRC,previewhash,platform/bundle/minOS verified. Frozen
manifest errors=[],excluded=[];3PNG recovered and all3inspected (08:05wheels,
visible Memory digits, completed session). Runner927seconds. Playable allocation
CLOSED2/2,1494actual seconds,$0; no remaining capacity. Earlier4bceba5 failed only
Debug-test composition; corrected explicit branches compiled and tests executed.

## Final acceptance in progress

Small changed candidate: memory redraws only at its absolute reveal deadline,
audio notifications delivered on main thread, additional pending-route/stale-QR/
cancellation-recovery app tests, user-facing handoff docs and targeted management
workflow groups. These changes NOT RUN at publication. MILESTONE_VALIDATION records
fresh max6distinct/changed-correction executions,30min each/180aggregate minutes.
Initial groups lifecycle/configuration/settings retain5existing management cases
and the full playable UIflow, all app units plusCore coverage in lifecycle group.
Do not claim all legacy UI/diagnostic cases ran. M1 requires these results; M2's
playable behavior is verified for90ad2b0 only until final candidate evidence arrives.

Device: iPhone16,owner-reported iOS27.2.1,Windows,noMac or sideload setup. Planned
free route WINDOWS_DEVICE_INSTALL uses unsigned IPA and local Sideloadly signing.
Provisioning/install,real AlarmKit firing/sounds/camera/intent launch are NOT VERIFIED.
Browser runtimes failed to initialize; no hosted Appetize URL created. Simulator
alarms/camera remain explicitly simulated; unsigned IPA requires legitimate signing.

Known failure history: diagnostic activation-point case remains FAILED/diagnostic-only;
legacy6A/Gate6 are not relabelled passed. QR no-op Save trigger remains unresolved
until its representative check. Recursion containment has scoped c62d0a8/run45250273849
negative evidence. No Gates0-5 disproof or old-lineage source imports. Dirty outer
checkout/local commits and all artifacts preserved. Historical status is in
history/PROJECT_STATE_2026-11-23.md. Next: finish these automated checks, preserve
results and deliver final packages, then owner device installation/physical testing.
