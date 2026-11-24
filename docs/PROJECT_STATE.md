# Active restart project state

Owner decision: **2026-11-23 (America/Chicago)**. Approved plan:
[COMPLETION_PLAN](COMPLETION_PLAN.md). First finish line is all-three-challenge
playable Appetize; autonomous progress, four milestones, diagnostic separation
and bounded parallel challenge work after stable contracts are authorized.
No further plan approval is pending. Original requirements/invariants remain.

## Current scope and milestones

| Milestone | Status / next scope |
| --- | --- |
| M1 — Management and stable contracts | NOT ACCEPTED. Current slice: native wheel time-picker UX improvement. Next: functional management journeys and QR Save reproducer; then stable coordinator/engine contracts. |
| M2 — Playable Appetize | NOT STARTED. Implement coordinator/host and all three engines, saved-order progression and relaunch restoration. |
| M3 — Real alarm integration | NOT ACCEPTED. Finish sounds, occurrence routing and cancellation/next-occurrence integration. |
| M4 — Device verification/handoff | NOT RUN. Free installation route and owner's iPhone/iOS remain unknown. |

M1 acceptance requires real create/edit/cancel/enable/disable/delete journeys,
stored-state/service-effect assertions, challenge configuration/order and relaunch.
Use the same domain/session/coordinator path for preview and device builds.
Keep simulated scheduling and QR input labelled; preview injection cannot ship in
device builds. Parallel engines wait for stable shared contracts; one integration
owner owns persistence/session/schema/lifecycle/navigation/workflow changes.

## Evidence and unresolved issues

| Assessed source | Run / result | Scope |
| --- | --- | --- |
| `758ccc61256836bf7c36756e6b0f266126b6215f` | [45294551508](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45294551508) SUCCESS; artifact `14877015172` | ARM64 Simulator preview compiled, installed and launched. No functional milestone or Appetize-interaction acceptance. |
| `a7b5fa869f68ab4d6558354c6324b4b6e98ded8d` | [45252354273](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45252354273) FAILED | Native diagnostic activation-point/hittability failure and test-step timeout; unresolved trigger. FAILED/diagnostic-only, never converted to PASS. |
| `c62d0a8d2a3294691eda053588dd77d0d3045ce2` | [45250273849](https://github.com/teejayishere/PuzzleAlarm/actions/runs/45250273849) SUCCESS | Narrow negative capture regressions only; no blanket gate restoration. |

Historical 6A remains NOT ACCEPTED; 6B/6C withheld and 6D–6F/Gate 6 unaccepted.
The new milestone policy replaces their execution blocking order, not their
recorded results. Gates 0–5 are inherited and not disproved; no old gates gain
acceptance from plan approval. QR Save remains unclassified until reproduced.
Engines, challenge navigation, QR generation/camera, bundled audio and final
occurrence orchestration remain feature gaps. Device alarm behavior is unverified.

## Active validation allocation

The native picker batch has its own pre-recorded bounded $0 allocation in
[NATIVE_TIME_PICKER](NATIVE_TIME_PICKER.md): at most two changed preview workflow
executions, 25 minutes each/50 aggregate runner-minutes, focused draft tests and
two time-editor journeys plus bounded local review/artifact checks. It is not
milestone acceptance; no new result is claimed here. Completed repair/preview
allocations do not transfer capacity. COMPLETION_PLAN itself allocates no checks.
Source changes require relevant successful CI for the exact published source SHA.
Documentation-only review links that assessed source and does not claim a new-HEAD
app pass. Keep source/build/launch/Appetize/device evidence separate.

## Authority, history and owner input

Active lineage: `codex/restart-gate5-20261029-f8a41c`; baseline
`159b777379ad587a615df56ef24fa273aa29ffe4`; fixed anchor
`862c2d872958c2e08971acbf605bbcf07ee4b3d5`. No post-anchor merges or old-lineage
imports. Preserve the original dirty outer checkout and all evidence. The fetched
active branch lacks `Scripts/check_restart_preflight.py`; no preflight PASS claimed.

Prior status content is preserved byte-for-byte in
[2026-11-23 history](history/PROJECT_STATE_2026-11-23.md), including superseded next
actions; it is not current authority. PROJECT_STATE owns status, AGENTS policy,
MASTER_PLAN requirements, COMPLETION_PLAN execution/exit criteria, ARCHITECTURE
design and TEST_MATRIX acceptance/evidence. Only pending owner information:
available iPhone/iOS and existing free development-build installation method.
