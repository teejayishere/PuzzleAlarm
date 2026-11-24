# Final representative management and integration allocation

Owner-approved autonomous milestones. This is a fresh $0 allocation for the
remaining M1 representative journeys and final integration, not reuse of native
or playable development budgets. Record before any new validation:

Maximum SIX workflow executions: THREE distinct initial groups (lifecycle,
configuration,settings), with at most THREE changed-candidate follow-up executions across affected groups
(including previously passing groups if shared source changes);
each failed group gets at most ONE correction; zero unchanged failing reruns. Each job30min maximum,180 aggregate actual runner-
minutes on standard free public runners. Stop on exhaustion; diagnose each failure
before correction; do not dispatch initial groups until playable candidate result
has been inspected. Local max4diff reviews,10source/evidence reviews,4artifact
metadata/download reviews. No physical-device claims.

lifecycle: complete Core tests+coverage report,all app-unit tests,unsigned device
and Simulator builds; UI testCreateEditEnableDisableDeleteAndRelaunch.
configuration: UI testChallengeConfigurationOrderingSoundAndPersistence and
ChallengeSettingsUITests/testQRTargetRetainsExactTokenThroughSaveAndReopen.
settings: UI testMathSettingsSaveAndReopen,testMemorySettingsSaveAndReopen and
the full playable three-challenge UI journey.

These five existing scenarios retain all assertions; full-three playable flow and
two native-picker journeys are covered by the prior playable candidate selection.
A source change requires its affected regressions again; a workflow-only follow-up
must identify the assessed app source and its identical files. This is targeted
functional acceptance, not an assertion that every legacy UI/diagnostic test ran.
Retain unresolved failures individually. Source CI, Simulator, Appetize, unsigned
artifact, free provisioning and physical-phone verification remain separate.
