# Next Phase Plan: Phase 1B Stabilization and M1 Closure

**Purpose:** Close M1 cleanly so external contributors can branch into M2/M3 without foundational rewrites. Strategy is **locked**: M1 closure first, platform-first sequencing, Postgres + Redis as the data layer (already in place).

**As of:** March 2026. Phase 1B implementation is in the repo; this plan covers the **stabilization pass** and **remaining M1 issue closure** so the codebase is ready for structured external work.

---

## 1. Current state (parsed from codebase)

### Backend

- **Stack:** TypeScript, Fastify, Postgres, Redis. No in-memory store; all reads/writes go through DB + cache.
- **Routes:** Auth (signup, login, refresh, /me), catalog (search, albums/:id), opinions (log/recently-played, ratings, reviews), social (follow, feed, react, comment), lists (create, items, get), recaps (weekly/latest, weekly/generate), push (tokens, preferences, notifications, test-recap), trust (export, delete, providers connect/disconnect stubs). Health includes postgres + Redis status.
- **Persistence:** Migrations in `backend/src/db/schema/` (001_phase1b_core.sql, 002_phase1b_notification_hardening.sql). Tables: users, sessions, albums, ratings, reviews, follows, listening_events, activity_events, lists, list_items, idempotency_keys, recap_snapshots, notification_preferences, device_tokens, notification_events, analytics_events.
- **Idempotency:** `withIdempotency` in opinions, social, lists, recaps, push; DB-backed with `idempotency_keys` table.
- **Config:** `backend/src/config/env.ts`; `backend/.env.example` and optional `backend/.env`. Requires `DATABASE_URL` and `REDIS_URL` (defaults point to localhost).

### Android

- **Repository:** Default is `RemoteSoundScoreRepository()` (injected in `SoundScoreRepository.kt`). Uses `ApiClient`, `InMemoryOutboxStore`, `OutboxSyncEngine`; feed/albums/profile/ratings/lists/notificationPreferences/latestRecap backed by StateFlows, seeded from `SeedData` then refreshed from API.
- **Outbox:** Operations RATE_ALBUM, TOGGLE_REACTION, CREATE_LIST, REGISTER_DEVICE_TOKEN, GENERATE_RECAP; flush with retry/backoff; `OutboxSyncEngineTest` covers success/failure paths.
- **Deep links:** `DeepLinkResolver` (lists, recaps, profile, album, default Feed); `SoundScoreApp(startDeepLink)` and `MainActivity` pass intent URI; unit test for resolver.
- **Screens:** Feed, Log, Search, Lists, Profile; ViewModels use repository flows; Profile has notification prefs and recap load/generate.

### CI and tooling

- **CI (`.github/workflows/ci.yml`):** Backend job: Postgres + Redis services, `npm install`, `npm run migrate --workspace backend`, `npm run typecheck`, `npm run test --workspace backend`, `npm run build`. Android job: Java 17, setup-android, `./gradlew :app:assembleDebug`, `./gradlew :app:testDebugUnitTest`.
- **Local run:** `scripts/run-env.sh` (Node + Java from Android Studio JBR); `docs/RUN_LOCALLY.md` (Docker for Postgres/Redis, migrate, dev; Gradle installDebug).
- **Gradle:** Wrapper 8.13; AGP 8.13.2; Kotlin 2.1.0; minSdk 26, targetSdk 35.

### Contracts and docs

- **Contracts:** `packages/contracts` (TypeScript, zod); consumed by backend. API shapes align with /v1 routes.
- **Docs:** PROJECT_OVERVIEW, CONTEXT_01–07, ISSUES_AND_TACKLE_PLAN, PHASE_1B_RELEASE_RUNBOOK, PHASE_1B_CLOSURE_CHECKLIST, PHASE_1B_OWNERSHIP_MAP, RUN_LOCALLY.

---

## 2. Remaining M1 scope (from issues and closure checklist)

- **Issue snapshot:** 36 open total (22 M1, 13 M2, 1 M3) per last GitHub pull. M1 epics: M01 Mobile Foundation, M02 Navigation/Deep Links, M03 Offline/Outbox, M04 Performance/Reliability, M05 Push, M09 Ratings/Reviews, M10 Social/Feed, M11 Lists, M12 Recaps, M13 Trust, M14 CI/Observability.
- **Phase 1B already delivers:** Platform baseline (Postgres/Redis, migrations, CI), backend durability (no in-memory store, idempotency, rate limit, logging), mobile remote+outbox, deep links, push APIs + preferences, recaps generate/retrieve, trust export/delete stubs, runbook and ownership map.
- **Gap to “M1 closed”:** (1) All M1 **task** issues (#67–#107 range) either closed or explicitly deferred to M2/M3 with a blocker issue. (2) **Hardening** evidence: tests + metrics/observability where checklist asks for them. (3) **Build/config** and **contributor onboarding** verified with no hidden dependency surprises.

---

## 3. Next phase: Phase 1B Stabilization and M1 Closure

Single phase with six tracks. Order is platform-first so all streams can branch safely.

### Track A: Platform and delivery baseline (do first)

- **Goal:** Reproducible local bootstrap, deterministic CI, release runbook used in at least one staging dry run.
- **Issues (examples):** #66, #69, #72, #75, #78 (M01–M04 hardening / CI / observability).
- **Implementation:**
  - **Local:** Document and verify “clone → install → docker compose up -d → migrate → dev” and “run-env.sh + gradlew installDebug” with no extra hidden steps; add any missing env or version pins to RUN_LOCALLY and, if needed, to `scripts/bootstrap-phase1b.sh`.
  - **CI:** Ensure required checks are named and enforced (typecheck, migrate, backend tests, Android assemble + unit tests); no flaky steps; Java/Node versions and Android SDK setup explicit in workflow.
  - **Release:** Use PHASE_1B_RELEASE_RUNBOOK for one dry run (e.g. “staging” = local + migrated DB); record any gaps in runbook or checklist.
- **Exit criteria:** Clean clone bootstrap works; CI pass/fail is deterministic; runbook has been executed once and updated if needed.
- **Exact integration steps:**
  - Root: `npm install` (workspaces: backend, packages/contracts).
  - Backend: Copy `backend/.env.example` → `backend/.env` if not present; `npm run migrate --workspace backend`; `npm run dev`.
  - Android: `source scripts/run-env.sh` (or set JAVA_HOME + PATH manually); `./gradlew installDebug`. No extra repos or Gradle plugins beyond current `build.gradle.kts` / root plugins.
  - Optional: `scripts/bootstrap-phase1b.sh` (requires Docker) runs compose + migrate.

### Track B: Backend durability and hardening

- **Goal:** Restart-safe data, idempotent writes survive retries/restarts, feed/profile p95 (or equivalent) observable.
- **Issues (examples):** #93, #96, #99 (M09/M10/M11 hardening).
- **Implementation:**
  - Confirm all write paths use `idempotency_keys` and that replay of the same key returns stored response (add or extend backend tests).
  - Confirm feed and profile hot paths use Redis where intended; add or extend integration tests for cache invalidation/restart.
  - Add or document a minimal observability hook (e.g. request timing or error count) so “p95” or error rate can be tracked later (no heavy infra required in this phase).
- **Exit criteria:** Idempotency replay tests pass; no write path bypasses idempotency; feed/profile read path is covered by tests; observability hook documented or implemented.
- **Files:** `backend/src/lib/idempotency.ts`, `backend/src/modules/opinions.ts`, `social.ts`, `lists.ts`, `recaps.ts`, `push.ts`; `backend/src/db/` (repos/cache if any); backend test dir.

### Track C: Mobile reliability and navigation

- **Goal:** Offline write replay E2E, deep links resolve deterministically, no screen depends on in-memory-only behavior for core flows.
- **Issues (examples):** #69, #72, #75, #78 (M01–M04).
- **Implementation:**
  - Ensure outbox flush is triggered on app foreground and after each enqueue; backoff/failure state visible or logged.
  - Verify DeepLinkResolver + MainActivity handle all supported URI patterns and that share entry (e.g. recap link) opens the correct screen; add tests for any new patterns.
  - Replace any remaining “seed-only” assumptions in ViewModels/screens with repository flows (already true for default RemoteSoundScoreRepository; verify Lists/Profile/Feed/Log/Search).
- **Exit criteria:** Outbox replay works E2E (rate, list create, push prefs, recap generate); deep link tests pass; core flows use repository, not raw SeedData.
- **Files:** `app/.../data/repository/SoundScoreRepository.kt`, `app/.../data/sync/OutboxSyncEngine.kt`, `app/.../ui/navigation/DeepLinkResolver.kt`, `MainActivity.kt`, `SoundScoreApp.kt`, ViewModels and screens under `app/.../ui/`.

### Track D: Push notifications (contract + core + hardening)

- **Goal:** Test notifications for social + recap; user controls respected; no sensitive payload in push.
- **Issues (examples):** #57, #79, #80, #81 (M05).
- **Implementation:**
  - Device token registration and preference APIs are in place; verify test-recap and social notification paths end-to-end (or document FCM setup needed for real device).
  - Confirm payload sanitization and dedupe/collapse (002_phase1b_notification_hardening.sql and backend notification code) are covered by tests or runbook.
- **Exit criteria:** Test notification path works or is documented; preference toggles and quiet hours respected; payload policy documented and enforced in code.
- **Files:** `backend/src/modules/push.ts`, notifications/events code; `backend/src/db/schema/002_phase1b_notification_hardening.sql`; Android push preference UI and token registration.

### Track E: Recaps (core + hardening)

- **Goal:** Weekly recap generated and retrievable; share entry opens correct in-app destination; recap metrics visible or logged.
- **Issues (examples):** #64, #101, #102 (M12).
- **Implementation:**
  - Confirm `/v1/recaps/weekly/latest` and generate path work with persisted recap_snapshots; add or extend tests.
  - Ensure recap share payload/deep link matches DeepLinkResolver (e.g. `/recaps/` → Profile); add test.
  - Add or document a simple growth event (e.g. analytics_events) when recap is generated or viewed.
- **Exit criteria:** Recap generation and retrieval tested; share link resolves in app; recap events logged or documented.
- **Files:** `backend/src/modules/recaps.ts`, `backend/src/db/schema/` (recap_snapshots); Android Profile recap load/generate and DeepLinkResolver.

### Track F: Epic closure and contributor structure

- **Goal:** All M1 task issues closed or explicitly deferred; epics have closure checklist tied to code/tests/docs; “ready-for-external” and ownership clear.
- **Issues:** Remaining open M1 epics and tasks (#54–#66, #67–#107).
- **Implementation:**
  - For each M1 task: close with a comment referencing the implementing PR or “deferred to M2/M3” with blocker issue link.
  - Ensure PHASE_1B_CLOSURE_CHECKLIST items are checked where done; add “External contributor readiness” section to docs (e.g. CONTRIBUTING or PROJECT_OVERVIEW) with: how to run locally, where contracts live, how to run CI, ownership map link.
  - Add labels (e.g. `ready-for-external`, `m1-done`) and keep PHASE_1B_OWNERSHIP_MAP as the subsystem ownership reference.
- **Exit criteria:** M1 task list closed or deferred; closure checklist updated; contributor-facing doc points to runbook, contracts, CI, and ownership.

---

## 4. Build and config verification (no hidden surprises)

- **Node:** 20 LTS (CI and RUN_LOCALLY). Project-local install under `.local/node` is optional; CI uses `actions/setup-node`.
- **Java:** 17 for Android (CI); 21 from Android Studio JBR is acceptable for local (Gradle 8.13 compatible). No other JDK required.
- **Gradle:** 8.13 (wrapper); AGP 8.13.2; Kotlin 2.1.0. No extra plugin repos beyond default + Android.
- **Backend:** No native deps; `tsx` for dev and tests. Migrations run with `tsx src/db/migrate.ts`; require Postgres and Redis.
- **Android:** No optional native modules or NDK in current build; Coil, Retrofit, kotlinx.serialization, Navigation Compose. All in `app/build.gradle.kts`; no hidden BOM or version overrides elsewhere.
- **Contracts:** TypeScript only; built before backend in `npm run build`. No runtime dependency from Android on `packages/contracts` (Android uses its own DTOs in `app/.../data/api/`).

Run before calling the phase done:

1. `npm install` at root → no peer/build errors.
2. `npm run migrate --workspace backend` (with Postgres/Redis up) → success.
3. `npm run typecheck` and `npm run test --workspace backend` → pass.
4. `./gradlew :app:assembleDebug` and `./gradlew :app:testDebugUnitTest` (with JAVA_HOME set) → pass.
5. Optional: full local bootstrap from clone using only RUN_LOCALLY + run-env.sh.

---

## 5. Public APIs and types (lock for external work)

- **Backend:** All /v1 routes and request/response shapes are the contract. Idempotency-key header required for mutating endpoints. Error envelope and versioning as in CONTEXT_02.
- **Contracts package:** `packages/contracts` — keep aligned with backend route types; no breaking change without a version bump or changelog note.
- **Android:** `SoundScoreRepository` interface and `RemoteSoundScoreRepository`; ApiClient and DTOs in `app/.../data/api/`. New features (M2/M3) should extend repository and API, not replace the core flow.

---

## 6. Test and acceptance summary

- **Contract/API:** Snapshot or smoke tests for /v1 endpoints; idempotency replay and conflict behavior covered in backend tests.
- **Persistence:** Migration and repo integration tests; Redis/cache behavior where applicable; restart durability.
- **Mobile:** ViewModel/sync state and outbox replay tests; deep link resolver tests; optional UI smoke for Feed/Log/Lists/Profile.
- **E2E (manual or scripted):** Signup/login → rate/review → feed → list create → share entry → export/delete; recap generate and open via link; notification preference respected.
- **Gates:** CI required checks green; no new linter/type errors; RUN_LOCALLY and runbook validated once.

---

## 7. Assumptions and priorities

- **Source of truth for issues:** GitHub (re-pull with `gh issue list` or API when closing M1).
- **Phase 2 (Spotify/provider)** does not start until M1 is closed; provider work remains in M2 (#58–#60, #82–#90, #105).
- **If scope must be cut:** Order of priority is Track A → Track B → Track C → Track D → Track E → Track F (platform first, then durability, then mobile, then push/recaps, then epic hygiene).

---

## 8. Handoff for external contributors

After this phase:

- **M2 (Spotify/provider):** Branch from main; Identity/Provider and Catalog/Listening Import epics can start; backend provider adapter interface and mobile “Connect Spotify” can be designed against current auth and catalog endpoints.
- **M3 (multi-provider / scale):** Same base; add adapters and scale work on top of stable M1 APIs and data model.
- **Docs to read first:** PROJECT_OVERVIEW, CONTEXT_02 (architecture), CONTEXT_04 (codebase map), RUN_LOCALLY, PHASE_1B_OWNERSHIP_MAP. Then CONTEXT_06 (roadmap) and ISSUES_AND_TACKLE_PLAN for milestone mapping.

---

*This plan is derived from the current codebase (backend, Android, contracts, CI, docs), ISSUES_AND_TACKLE_PLAN, CONTEXT_02/06, and the Phase 1B closure checklist. Update this doc when M1 closure or build/config changes.*
