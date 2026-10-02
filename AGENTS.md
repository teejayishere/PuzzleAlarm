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
