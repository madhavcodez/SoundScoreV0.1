# Phase 1 Issue Evidence Map

Date: 2026-03-11  
Baseline: `4a60d5a`  
Tag: `phase1-complete-2026-03-11`

## Closed with evidence

| Issue | Status | Evidence (code/tests/docs) |
|---:|---|---|
| #79 | Closed | `packages/contracts/src/endpoints.ts`, `packages/contracts/src/models.ts`, `backend/src/modules/push.ts`, `backend/src/lib/notifications.ts`, `backend/src/db/schema/001_phase1b_core.sql`, `backend/src/db/schema/002_phase1b_notification_hardening.sql`, `docs/PHASE_1_COMPLETION_EVIDENCE.md` |
| #80 | Closed | `backend/src/modules/push.ts`, `backend/src/lib/notifications.ts`, `backend/src/db/schema/001_phase1b_core.sql`, `backend/src/db/schema/002_phase1b_notification_hardening.sql`, `app/src/main/java/com/soundscore/app/data/repository/SoundScoreRepository.kt`, `app/src/main/java/com/soundscore/app/data/sync/OutboxSyncEngine.kt`, `app/src/main/java/com/soundscore/app/ui/viewmodel/ProfileViewModel.kt` |
| #93 | Closed | `backend/src/modules/opinions.ts`, `backend/src/lib/idempotency.ts`, `backend/src/db/schema/001_phase1b_core.sql`, `docs/PHASE_1_COMPLETION_EVIDENCE.md` |
| #96 | Closed | `backend/src/modules/social.ts`, `backend/src/db/client.ts`, `backend/src/lib/idempotency.ts`, `backend/src/lib/notifications.ts`, `backend/src/db/schema/002_phase1b_notification_hardening.sql`, `docs/PHASE_1_COMPLETION_EVIDENCE.md` |
| #101 | Closed | `backend/src/modules/recaps.ts`, `backend/src/db/schema/001_phase1b_core.sql`, `packages/contracts/src/endpoints.ts`, `app/src/main/java/com/soundscore/app/ui/navigation/DeepLinkResolver.kt`, `app/src/main/java/com/soundscore/app/ui/viewmodel/ProfileViewModel.kt` |

## Kept open with blocker comments

| Issue | Reason kept open |
|---:|---|
| #69, #72, #75, #78 | Hardening traceability + measurable security/perf/observability evidence still incomplete |
| #81, #99, #102 | Push/lists/recap hardening evidence not fully complete |
| #54, #55, #56, #57 | Epics blocked by corresponding open hardening tasks |
| #61, #62 | Epic-level closure packet (acceptance-to-evidence mapping) still pending |
| #63, #64 | Blocked by open hardening tasks #99 and #102 |
| #65 | Trust/compliance continuation linked to reset Phase 2 stream #121/#122/#123/#124 |
| #66 | Cross-cutting hardening continuation linked to #108 (M3) |
