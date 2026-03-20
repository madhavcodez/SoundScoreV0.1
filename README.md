# SoundScore

> Letterboxd for music -- log, rate, review, discover.

SoundScore is a cross-platform music logging and social discovery app. Users rate albums (0-6 scale), write reviews, curate lists, follow friends, and receive weekly recap insights. The project spans an Android app (Kotlin/Compose), an iOS app (Swift/SwiftUI), a shared TypeScript backend (Fastify), and typed API contracts.

## Project Status

| Phase | Scope | Status |
|-------|-------|--------|
| **Phase 1** | Provider-free beta: auth, ratings, reviews, lists, feed, recaps, push notifications | Complete |
| **Phase 2** | Spotify integration: OAuth connect, canonical mapping, listening history sync | In progress -- backend routes done, mobile clients pending |

- Backend: 36 routes operational across 11 domain modules
- iOS: 10 screens, 22 API routes wired, BUILD SUCCEEDED (0 warnings)
- Android: 5 screens, 18 API routes wired, MVVM architecture solid
- Phase 2 provider/mapping/sync routes are backend-only -- zero mobile coverage yet

## Architecture

```
                    +-------------------+
                    |   Android (Kotlin) |
                    |   Jetpack Compose  |
                    +--------+----------+
                             |
                             | HTTPS /v1/*
                             |
                    +--------v----------+
                    |   Backend (TS)     |
                    |   Fastify 4.x      |
                    |   Pino logging     |
                    +--+-----+------+---+
                       |     |      |
              +--------+  +--+--+  +--------+
              |           |     |           |
         +----v----+ +---v---+ +---v-----+ +----v--------+
         | Postgres | | Redis | | Spotify | | MusicBrainz |
         | (data)   | |(cache)| | (OAuth) | | (catalog)   |
         +----------+ +-------+ +---------+ +-------------+
                             |
                             | HTTPS /v1/*
                             |
                    +--------v----------+
                    |    iOS (Swift)     |
                    |    SwiftUI         |
                    +-------------------+
```

## Tech Stack

| Platform | Language | Framework | Key Libraries |
|----------|----------|-----------|---------------|
| Android | Kotlin | Jetpack Compose | StateFlow, Hilt, OkHttp, Room |
| iOS | Swift | SwiftUI | Combine, URLSession |
| Backend | TypeScript | Fastify 4.x | Pino, pg, ioredis, bcryptjs, Zod |
| Contracts | TypeScript | -- | Zod (shared validation schemas) |
| Database | SQL | PostgreSQL 15 | Full-text search (tsvector/GIN) |
| Cache | -- | Redis | Session/feed/profile caching |
| Infra | YAML | Docker Compose | Postgres + Redis containers |
| Deploy | JSON | Railway | Docker-based production deploy |

## Module Map

```
SoundScorev0.1/
+-- app/                        # Android app (Kotlin + Compose)
|   +-- src/main/java/.../
|       +-- data/               #   Repository, API client, DTOs
|       +-- ui/                 #   Screens, ViewModels, theme
+-- ios/                        # iOS app (Swift + SwiftUI)
|   +-- SoundScore/
|       +-- API/                #   APIClient, DTOs
|       +-- Screens/            #   10 screens + ViewModels
|       +-- Components/         #   Reusable UI components
|       +-- Theme/              #   SSColors, ThemeManager
+-- backend/                    # Fastify API server
|   +-- src/
|       +-- modules/            #   11 domain modules (route handlers)
|       +-- lib/                #   18 shared utilities
|       +-- db/                 #   Schema migrations + client
|       +-- config/             #   Zod-validated env config
|       +-- tests/              #   9 test files
+-- packages/
|   +-- contracts/              # Shared Zod schemas for API payloads
+-- docs/                       # Architecture, context, phase plans
+-- supabase/                   # Edge functions + migrations
+-- scripts/                    # Bootstrap, env, CI helpers
+-- docker-compose.yml          # Local Postgres + Redis
+-- docker-compose.prod.yml     # Production compose
+-- railway.json                # Railway deployment config
```

## Quick Start

### Backend

Requires Node.js 20+ and Docker.

```bash
# 1. Start infrastructure
docker compose up -d

# 2. Load local Node/Java paths
source scripts/run-env.sh

# 3. Install dependencies
npm install

# 4. Run database migrations
npm run migrate --workspace backend

# 5. Start development server
npm run dev --workspace backend
```

Backend runs at `http://localhost:8080`. API docs at `http://localhost:8080/docs`.

Copy `backend/.env.example` to `backend/.env` to override defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Bind address |
| `DATABASE_URL` | `postgresql://soundscore:soundscore@localhost:5432/soundscore` | Postgres connection |
| `REDIS_URL` | `redis://localhost:6379` | Redis connection |
| `AUTH_SALT_ROUNDS` | `10` | bcrypt cost factor |
| `SPOTIFY_CLIENT_ID` | (empty) | Spotify OAuth client ID |
| `SPOTIFY_CLIENT_SECRET` | (empty) | Spotify OAuth client secret |
| `ALLOWED_ORIGINS` | `http://localhost:3000` | CORS allowlist (comma-separated) |
| `NODE_ENV` | `development` | Environment mode |
| `LOG_LEVEL` | `info` | Pino log level |

### Android

```bash
# From terminal (after source scripts/run-env.sh):
./gradlew installDebug

# Or open in Android Studio and Run on device/emulator
```

### iOS

Open `ios/SoundScore/SoundScore.xcodeproj` in Xcode, select a simulator or device, and Build & Run. The app auto-authenticates against the local backend in DEBUG mode.

## API Endpoints

All 36 routes registered in `backend/src/server.ts`. Mutating routes require an `idempotency-key` header.

### Auth (3 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/auth/signup` | No | No | Register new account |
| POST | `/v1/auth/login` | No | No | Login with email/password |
| POST | `/v1/auth/refresh` | No | No | Refresh access token |

### Profile (1 route)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/v1/me` | Yes | No | Get current user profile (Redis-cached) |

### Catalog (3 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/v1/search` | No | No | Search albums (FTS + Spotify + MusicBrainz fallback) |
| GET | `/v1/albums/:id` | No | No | Get album by ID |
| POST | `/v1/albums/from-spotify` | No | No | Upsert album from Spotify data |

### Opinions (4 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/v1/log/recently-played` | Yes | No | Get user listening history (paginated) |
| POST | `/v1/ratings` | Yes | Yes | Create or update album rating |
| POST | `/v1/reviews` | Yes | Yes | Create album review |
| PUT | `/v1/reviews/:id` | Yes | Yes | Update review (optimistic concurrency) |

### Social (4 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/follow/:userId` | Yes | Yes | Follow a user |
| DELETE | `/v1/follow/:userId` | Yes | Yes | Unfollow a user |
| GET | `/v1/feed` | Yes | No | Get activity feed (Redis-cached first page) |
| POST | `/v1/activity/:id/react` | Yes | Yes | React to an activity event |
| POST | `/v1/activity/:id/comment` | Yes | Yes | Comment on an activity event |

### Lists (3 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/lists` | Yes | Yes | Create a new list |
| POST | `/v1/lists/:id/items` | Yes | Yes | Add album to list |
| GET | `/v1/lists/:id` | No | No | Get list with items |

### Trust / Account (2 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/account/export` | Yes | No | Export all user data (GDPR) |
| DELETE | `/v1/account` | Yes | No | Delete account and all data |

### Recaps (2 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/v1/recaps/weekly/latest` | Yes | No | Get latest weekly recap |
| POST | `/v1/recaps/weekly/generate` | Yes | Yes | Force-generate weekly recap |

### Push / Notifications (6 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/push/tokens` | Yes | Yes | Register device push token |
| DELETE | `/v1/push/tokens/:deviceToken` | Yes | Yes | Remove device push token |
| GET | `/v1/push/preferences` | Yes | No | Get notification preferences |
| PUT | `/v1/push/preferences` | Yes | Yes | Update notification preferences |
| GET | `/v1/notifications` | Yes | No | List recent notifications (limit 50) |
| POST | `/v1/notifications/test-recap` | Yes | Yes | Queue test recap notification |

### Providers -- Phase 2 (4 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/providers/:provider/connect` | Yes | No | Start OAuth flow for provider |
| POST | `/v1/providers/:provider/callback` | Yes | No | Complete OAuth exchange |
| GET | `/v1/providers/:provider/status` | Yes | No | Check provider connection status |
| POST | `/v1/providers/:provider/disconnect` | Yes | No | Disconnect provider (soft delete) |

### Mapping -- Phase 2 (2 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/v1/mappings/lookup` | No | No | Lookup canonical mapping by provider ID |
| POST | `/v1/mappings/resolve` | No | No | Resolve provider album to canonical album |

### Sync / Import -- Phase 2 (3 routes)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| POST | `/v1/sync/start` | Yes | No | Start provider listening history sync |
| GET | `/v1/sync/status/:sync_id` | Yes | No | Check sync job progress |
| POST | `/v1/sync/cancel` | Yes | No | Cancel running/queued sync job |

### Infrastructure (1 route)

| Method | Path | Auth | Idempotency | Description |
|--------|------|------|-------------|-------------|
| GET | `/health` | No | No | Health check (Postgres + Redis probes) |

## Database Schema

8 migration files across `backend/src/db/schema/`. 24 tables total.

| Table | Migration | Purpose |
|-------|-----------|---------|
| `schema_migrations` | 001 | Migration version tracking |
| `users` | 001 | User accounts (email, handle, bio, aggregates) |
| `sessions` | 001, 006 | Access tokens with expiry |
| `albums` | 001, 006, 007, 008 | Album catalog (FTS, Spotify metadata, timestamps) |
| `ratings` | 001 | Album ratings (0-6 scale, unique per user+album) |
| `reviews` | 001 | Album reviews with optimistic concurrency (revision) |
| `follows` | 001 | Social follow graph |
| `listening_events` | 001, 004 | Play history (manual + provider sync, dedup key) |
| `activity_events` | 001 | Feed events (ratings, reviews, lists, reactions, comments) |
| `lists` | 001 | User-curated album lists |
| `list_items` | 001 | Albums within lists (ordered positions) |
| `idempotency_keys` | 001 | Idempotent write deduplication |
| `recap_snapshots` | 001 | Weekly recap JSON snapshots |
| `notification_preferences` | 001 | Per-user notification settings |
| `device_tokens` | 001 | Push notification device tokens |
| `notification_events` | 001, 002 | Notification queue (collapse/dedupe keys) |
| `analytics_events` | 001 | Analytics event log |
| `audit_events` | 003 | Security audit trail (no FK to users for compliance) |
| `dead_letter_events` | 003 | Failed async operation retry queue |
| `canonical_artists` | 004 | Normalized artist identities |
| `canonical_albums` | 004 | SoundScore-owned canonical album IDs |
| `provider_mappings` | 004 | Provider ID to canonical ID mappings with confidence |
| `sync_cursors` | 004 | Resume point per user per provider |
| `sync_jobs` | 004 | Sync job state machine (queued/running/completed/failed) |
| `tracks` | 004 (tracks) | Per-track data within albums |
| `track_ratings` | 004 (tracks) | Per-track ratings (0-6 scale) |
| `provider_connections` | 005 | OAuth tokens per provider (Spotify, Apple Music) |
| `oauth_states` | 005 | CSRF state for OAuth flows (10-min expiry) |
| `album_genres` | 007 | Genre junction table for normalized queries |

## Audit Summary (2026-03-19)

Full audit log: `docs/AUDIT_LOG.md`

| Pass | Focus | Issues Found | Issues Fixed |
|------|-------|-------------|-------------|
| 1 | Bootstrap + Baseline | 4 | 0 |
| 2 | Backend Deep Audit | 6 | 0 |
| 3 | iOS Deep Audit + Auth Fix | 9 | 1 |
| 4 | Android Static Audit | 9 | 0 |
| 5 | Cross-Platform Consistency | 9 | 0 |
| 6 | Build Verification | 0 | 0 |
| 7 | Second-Pass Fixes | 0 | 2 |
| **Total** | **7/9 passes** | **33 issues** | **3 fixed** |

### Key Metrics

| Metric | Android | iOS | Backend | Contracts |
|--------|---------|-----|---------|-----------|
| Source files | 33 | 67 | 45 | 9 |
| Lines of code | 4,874 | 8,295 | 5,531 | 520 |
| Test files | 4 | 0 | 9 | 0 |
| Test functions | 9 | 0 | 96 | 0 |

### Critical Open Issues

- **ISSUE-001** (P1): 10+ backend route handlers bypass Zod validation
- **ISSUE-003** (P1): 8/11 backend modules have zero test files
- **ISSUE-016** (P1): No `strings.xml` -- all Android strings hardcoded
- **ISSUE-017** (P1): 5 iOS screens missing from Android
- **ISSUE-018** (P1): 12 backend routes missing from Android API client
- **ISSUE-019** (P1): Android smoke tests broken (stale assertions)
- **ISSUE-032** (P1): Phase 2 has zero mobile client coverage

### API Coverage

| Platform | Routes Covered | Percentage |
|----------|---------------|------------|
| Backend | 36 | 100% |
| iOS client | 22 | 61% |
| Android client | 18 | 50% |
| Contract schemas | 16 | 44% |

## Documentation

| File | Description |
|------|-------------|
| `docs/AUDIT_LOG.md` | Full deep audit log with issue registry |
| `docs/ARCHITECTURE_DECISIONS.md` | ADRs for key technical choices |
| `docs/RUN_LOCALLY.md` | Local development setup guide |
| `docs/DEPLOYMENT_GUIDE.md` | Production deployment instructions |
| `docs/SECURITY_REVIEW.md` | Security audit findings |
| `docs/PROJECT_OVERVIEW.md` | High-level project overview |
| `docs/PHASE_1_COMPLETION_EVIDENCE.md` | Phase 1 completion proof |
| `docs/PHASE_1B_CLOSURE_CHECKLIST.md` | Phase 1B closure checklist |
| `docs/PHASE_1B_RELEASE_RUNBOOK.md` | Release runbook for Phase 1B |
| `docs/PHASE_2_EXECUTION_PLAN.md` | Phase 2 Spotify integration plan |
| `docs/NEXT_PHASE_PLAN.md` | Roadmap for future phases |
| `docs/CONTEXT_01_PRODUCT_AND_MARKET.md` | Product vision and market context |
| `docs/CONTEXT_02_ARCHITECTURE_AND_SYSTEM.md` | System architecture documentation |
| `docs/CONTEXT_03_MOBILE_APP_SPEC.md` | Mobile app specification |
| `docs/CONTEXT_04_CODEBASE_MAP.md` | Codebase structure map |
| `docs/CONTEXT_05_CONVENTIONS_AND_CONSTRAINTS.md` | Code conventions and constraints |
| `docs/CONTEXT_06_ROADMAP_AND_PHASES.md` | Product roadmap and phase definitions |
| `docs/CONTEXT_07_DATA_MODELS_AND_EVENTS.md` | Data model and event schema reference |
| `docs/ISSUES_AND_TACKLE_PLAN.md` | Issue triage and resolution plan |
| `docs/PHASE_1_ISSUE_EVIDENCE_MAP.md` | Issue evidence mapping for Phase 1 |
| `docs/PHASE_1B_OWNERSHIP_MAP.md` | Module ownership assignments |
| `docs/PHASE_2_ISSUE_CATALOG.md` | Phase 2 known issues |
| `docs/EDGE_MIGRATION_LOG.md` | Supabase edge function migration log |
| `docs/OVERNIGHT_PROGRESS.md` | Overnight development progress notes |
| `docs/OVERNIGHT_STATUS_REPORT.md` | Overnight status report |

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/run-env.sh` | Sets PATH for local Node.js + Java (source in each terminal) |
| `scripts/ensure-gh-path.sh` | Adds local `gh` CLI to PATH |
| `scripts/bootstrap-phase1b.sh` | One-shot: starts DBs, installs deps, runs migrations |
| `scripts/close-phase1a-issues.sh` | Closes resolved Phase 1A GitHub issues |
| `scripts/phase1b-open-issues.sh` | Lists current open issues with milestones and labels |

## Contributing

### Branch Strategy

- `main` -- stable, production-ready
- `audit/deep-sweep-YYYYMMDD` -- audit branches
- `feat/<description>` -- feature branches
- `fix/<description>` -- bug fix branches

### Commit Format

```
<type>: <description>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### Development Flow

1. Create feature branch from `main`
2. Write tests first (TDD)
3. Implement to pass tests
4. Run `npm run typecheck` (backend) and verify builds
5. Open PR with summary and test plan

---

Last audited: 2026-03-19
