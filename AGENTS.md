# HISTORICAL / ABANDONED — DO NOT DEVELOP HERE

> This branch is retired. Do not develop, recover, repair gates, or promote work here.
> The single current-status authority is the [active restart PROJECT_STATE](https://github.com/teejayishere/PuzzleAlarm/blob/codex/restart-gate5-20261029-f8a41c/docs/PROJECT_STATE.md).
> Use `codex/restart-gate5-20261029-f8a41c` after verifying its remote state and lineage.
> Do not merge, cherry-pick, or copy this abandoned implementation into the restart.
> This documentation-only retirement notice accepts no gate. Original content below is historical, including its status, instructions, failures and budgets.

---

# PuzzleAlarm engineering instructions

Read docs/MASTER_PLAN.md, docs/PROJECT_STATE.md, docs/DEVELOPMENT_LOG.md,
current source/tests, and git status/diff before substantial work.

Follow the ordered gates in MASTER_PLAN. A blocked gate is not a pass.
Do not advance past a failed or blocked prerequisite. Trace later failures
to their earliest cause, invalidate affected gates, and rerun them in order.

Use only free tools and public Apple APIs. Keep credentials and signing material
out of this repository. Core must not depend on SwiftUI, UIKit, AlarmKit or
AVFoundation. Never invent AlarmKit signatures: inspect SDK and compile a spike.

Record source, automated, Xcode, Simulator and physical-device evidence separately.
Never report a CI pass without a run for the exact revision being assessed.
