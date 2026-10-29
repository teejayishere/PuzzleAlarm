# Prompt: red-team Gate 6 recovery and produce executable next steps

Work in teejayishere/PuzzleAlarm. Perform a planning and existing-evidence pass
only. Do not start tests, diagnostics, CI jobs, device actions, source changes or a
UI redesign. Do not interpret this prompt as permission to reset any allocation
budget, accept risk, invoke an exception or resume Stage 14 implementation.

Read docs/PROJECT_STATE.md first, then docs/GATE6_RECOVERY_PLAN.md. Verify local
branch, exact HEAD, worktree status and revision-specific acceptance/failure
evidence. Read only relevant MASTER_PLAN invalidation/budget rules, architecture,
test mappings, current source and archived logs. Preserve all existing work.

The known baseline is accepted source f01abf42 / run 40521565094. Failed Stage 14
candidate 62c8953 / run 40564260790 passed 37 native contracts but failed the first
ordinary list switch-input assertion; the editor was cancelled and the dependent
job skipped. Publication cfb37a8 is record-only, not a new validated product SHA.
Gate 6 is FAILED / HELD; Gates 7–14 are INVALIDATED / HELD; last unheld gate 5.
Historical diagnostic budgets are EXHAUSTED, zero jobs; the exception is REVOKED.
Check these facts against current records rather than assuming they remain latest.

Red-team the proposed recovery. Separate direct observations, inferences and
unknowns. Explain why unchanged product source, passing unit contracts, missing
trace entries and an earlier green run do not establish the new failure's cause.
The failed flow intentionally injects scheduling failure: after a valid first
enable input its expected status is Needs attention, then explicit product retry.
Do not describe that first action as requiring immediate healthy On.

Before additional archive review, state a specific question and the evidence that
could resolve it. Reuse original captured artifacts only; no generated probes,
runtime capture, replay or indefinite reinspection. If evidence proves a defect,
document the earliest cause, minimal proposed correction and affected gates; do
not implement under this planning-only prompt. If it does not, say so and stop.

Produce concrete ordered next steps and identify any genuine owner decision:
implementation/validation scope for a proven correction, a specified replacement
design requiring product authorization, or an explicit policy-change proposal if
runtime investigation is indispensable. New scope alone cannot renew the lifetime
diagnostic cap; the revoked exception cannot waive a current assertion failure.
Do not ask for vague permission to rerun or treat a generic continue as risk or
budget approval. No new design, policy change or allocation is preapproved.

Any future authorized validation must freeze an exact SHA, preserve original
assertions and required declarations, use free public tools/runners with declared
absolute limits, stop on required failure and preserve original evidence. Gate 6
must legitimately clear before ordered dependent replay through Gate 14 and full
required regression. Reopen the earliest gate if evidence requires it. Never
substitute a previous SHA's success, retry until green or conceal incomplete tests.

Save the red-team result and plan in docs/GATE6_RECOVERY_PLAN.md, link it near the
top of PROJECT_STATE and record the planning-only work in DEVELOPMENT_LOG. Keep
current FAILED/HELD statuses unchanged. Clearly state what was actually reviewed
and what was not executed. Preserve history, Stage 14 additions and all artifacts.
No main promotion, Stage 15, UX redesign or physical-device acceptance. Stop after
the plan or a documented blocker, and report the next required decision concisely.
