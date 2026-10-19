# Offline repair evidence — no new experiment

Review starts at clean `codex/stage-12-routing` HEAD
`31ed9af36031dd4cfa28b03b5fffea45c65f989e` on October 18, America/Chicago.
All new checks are Windows/offline. [Review and proposed experiment](../../GATE6_OFFLINE_REPAIR_2026-10-18.md).

- `windows-tooling-tests.log`: 31 focused Python checks, no Apple tools invoked.
- `archive-recheck.json`: independent decoding of the latest ZIP's raw bytes,
  raw/video hashes, omission recount, selected native frame PTS and video gap.
- `video-native-frames.png`: six native decoded frames, labeled by decoded-frame
  index/PTS, scaled for inspection without interpolating frames across the gap.
- `video-decoder-excerpts.log`: original video metadata/timestamp warning and
  selected `showinfo` rows. Original video remains in the unchanged archived ZIP.
- `proposed-command.json`: command construction only, **NOT EXECUTED**; Simulator
  ID is a placeholder resolved by the existing selector at any future authorized run.

Frame extraction used the already installed Overwolf FFmpeg (libavcodec 61.3.100),
local input only: `select=eq(n,0)+eq(n,1264)+eq(n,1265)+eq(n,1266)+eq(n,1268)+eq(n,1270),showinfo,scale=300:-1`,
`-fps_mode passthrough -frames:v 6`. One-per-second resampling was initially inspected
but discarded because it duplicates frames across the observed PTS gap.
No audio stream is present; screenshots cannot establish sound or main-thread liveness.
ZIP/raw/manifests and prior evidence files were not rewritten.

Xcode/Swift/UIKit compilation, actual updated Swift self-test, Simulator and physical
device behavior are unvalidated. No CI trigger, commit, push or promotion. Gate 6
FAILED / HELD; 7–12 INVALIDATED / HELD. Root cause remains undetermined. STOP.
