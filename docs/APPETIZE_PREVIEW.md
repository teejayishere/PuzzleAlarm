# Appetize preview delivery allocation - 2026-11-23

Owner requested a usable Appetize version and challenged checkpoint overhead.
This is an explicitly labelled preview, not stage implementation/promotion or gate
acceptance. Existing Stage 6 candidate UI only; no Stage 7 solver implementation.

Fresh $0 allocation, recorded before new validation: at most TWO changed preview
workflow executions, 25 minutes each, 50 aggregate actual runner-minutes on the
standard public macos-26 runner. No unchanged failing reruns. Stop and diagnose a
failed candidate before using the second slot. Maximum ONE local lineage check,
ONE preflight if present, FOUR diff checks, TEN bounded source/package reviews,
TWO artifact downloads, ONE Simulator launch per candidate, and ONE Appetize
verification session up to 3 minutes on a verified free account. No purchases,
paid plans, signing credentials or full UI suite. No automatic workflow runs.

Prior repair allocation CLOSED on run45252354273 failure: 3/6 executions,
2383/9000 actual runner-seconds ($0); unused capacity is retired. Complete 6A is
NOT ACCEPTED. The four negative capture regressions have narrow verified evidence
on c62d0a8/run45250273849, not current-HEAD full-gate proof.

Observed starting HEAD a7b5fa869f68ab4d6558354c6324b4b6e98ded8d has exact-HEAD
run45252354273 FAILURE: native diagnostic.direct switch hittability error and
18-minute test-step timeout. Seven of eight completed UI cases passed; two fixture
cases not reached. No runner restart. Root activation-point trigger unresolved;
this is not evidence of a product switch binding defect. Original QR Save cause
also unresolved. Artifact14858279146,4184048 bytes,SHA256
 dcd99be3e54964b1cefeab1b8426b5b8cc04bf25dd9621d6044ce66f4a1658fc;
CRC/digest verified, manifest errors=[], live Staging excluded. Three of thirteen
unique PNG inspected. Existing dirty outer checkout remains preserved.

No preview result claimed before the build. Required output: ARM64 iOS Simulator
.app ZIP, exact SHA metadata and launch evidence. Compilation/launch does not
prove editing journeys, alarm delivery, challenge solving or physical-device use.
The requested check_restart_preflight.py is absent in this active branch; record
that limitation, do not invent a preflight pass or add a check just for green CI.
