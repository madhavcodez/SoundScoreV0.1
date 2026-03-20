# SoundScore Backend

Provider-free Fastify API for SoundScore with persistent storage (Postgres), cache (Redis), and idempotent `/v1` write behavior. Phase 2 adds Spotify OAuth, canonical album mapping, and listening history sync.

## Quick Start

```bash
# 1. Start Postgres + Redis
docker compose up -d

# 2. Install packages
npm install

# 3. Run migrations
npm run migrate --workspace backend

# 4. Start backend
npm run dev --workspace backend
```

Server: `http://localhost:8080`
OpenAPI docs: `http://localhost:8080/docs`

## Architecture

Fastify + TypeScript modular monolith.

```
backend/src/
+-- server.ts              # App factory: route registration, middleware, hooks
+-- index.ts               # Entry point: starts server
+-- config/
|   +-- env.ts             # Zod-validated environment config
+-- modules/               # 11 domain modules (route handlers)
|   +-- auth.ts            # Signup, login, refresh, profile
|   +-- catalog.ts         # Album search, detail, Spotify upsert
|   +-- opinions.ts        # Ratings, reviews, recently-played
|   +-- social.ts          # Follow, feed, reactions, comments
|   +-- lists.ts           # List CRUD, add items
|   +-- trust.ts           # Account export (GDPR), account deletion
|   +-- recaps.ts          # Weekly recap generation + retrieval
|   +-- push.ts            # Device tokens, preferences, notifications
|   +-- providers.ts       # OAuth connect/callback/status/disconnect
|   +-- mapping.ts         # Canonical album resolution + lookup
|   +-- import.ts          # Sync jobs: start, status, cancel
+-- lib/                   # 18 shared utilities
|   +-- errors.ts          # ApiError class + factory functions
|   +-- idempotency.ts     # Idempotency key middleware
|   +-- rate-limit.ts      # Per-route rate limit configuration
|   +-- pagination.ts      # Cursor-based pagination helpers
|   +-- notifications.ts   # Notification queue + feed cache invalidation
|   +-- audit.ts           # Audit event logging
|   +-- sanitize.ts        # HTML stripping for user content
|   +-- mappers.ts         # DB row to API response mappers
|   +-- normalize.ts       # Text normalization for matching
|   +-- util.ts            # uid() generator, nowIso()
|   +-- retry.ts           # Retry with exponential backoff
|   +-- spotify-catalog.ts # Spotify search + album upsert
|   +-- spotify-adapter.ts # Spotify OAuth adapter
|   +-- musicbrainz-catalog.ts # MusicBrainz search + album upsert
|   +-- provider-adapter.ts    # Provider adapter interface
|   +-- provider-registry.ts   # Provider adapter registry
|   +-- dead-letter.ts     # Dead letter queue operations
|   +-- token-refresh.ts   # Token refresh helper (dead code)
+-- db/
|   +-- client.ts          # Postgres pool + Redis client wrapper
|   +-- runMigrations.ts   # Auto-apply SQL migrations on startup
|   +-- migrate.ts         # Standalone migration CLI
|   +-- schema/            # 8 SQL migration files
+-- tests/                 # 9 test files
```

### Request Flow

1. Fastify receives request, assigns `x-request-id` via `uid("req")`
2. `@fastify/helmet` adds security headers
3. `@fastify/cors` validates origin against allowlist
4. `@fastify/rate-limit` enforces per-route limits
5. Route handler in domain module processes request
6. `withIdempotency()` wraps mutating handlers for dedup
7. `ApiError` handler returns structured `{ error: { code, message, requestId } }`
8. `onResponse` hook logs latency in structured JSON

## Modules

| Module | File | Routes | Description |
|--------|------|--------|-------------|
| auth | `modules/auth.ts` | 4 | Signup, login, refresh tokens, get profile |
| catalog | `modules/catalog.ts` | 3 | Album search (FTS + Spotify + MusicBrainz fallback), album detail, Spotify upsert |
| opinions | `modules/opinions.ts` | 4 | Ratings (0-6), reviews with optimistic concurrency, recently-played log |
| social | `modules/social.ts` | 5 | Follow/unfollow, feed (Redis-cached page 1), reactions, comments |
| lists | `modules/lists.ts` | 3 | Create lists, add items (ordered positions), get list detail |
| trust | `modules/trust.ts` | 2 | GDPR data export, account deletion (cascade) |
| recaps | `modules/recaps.ts` | 2 | Weekly recap generation + retrieval with analytics tracking |
| push | `modules/push.ts` | 6 | Device token CRUD, notification preferences, notification list, test recap |
| providers | `modules/providers.ts` | 4 | OAuth connect/callback/status/disconnect for Spotify/Apple Music |
| mapping | `modules/mapping.ts` | 2 | Canonical album resolution with confidence scoring, mapping lookup |
| import | `modules/import.ts` | 3 | Sync job lifecycle: start, poll status, cancel (background processing) |

## Lib Utilities

| Utility | File | Description |
|---------|------|-------------|
| errors | `lib/errors.ts` | `ApiError` class with `notFound()`, `unauthorized()`, `conflict()`, `badRequest()` factories |
| idempotency | `lib/idempotency.ts` | Wraps write handlers; deduplicates by `idempotency-key` header per user+route |
| rate-limit | `lib/rate-limit.ts` | Route-level rate limits: auth (10/min), sensitive (3/hr), writes (30/min), providers (10/min) |
| pagination | `lib/pagination.ts` | `parsePaginationParams()` + `buildPaginatedResponse()` for cursor-based pagination |
| notifications | `lib/notifications.ts` | `queueNotification()`, `queueFollowerNotifications()`, feed cache invalidation |
| audit | `lib/audit.ts` | `logAuditEvent()` -- writes to `audit_events` table (IP, user-agent, details) |
| sanitize | `lib/sanitize.ts` | `stripHtml()` -- removes HTML tags from user-submitted content |
| mappers | `lib/mappers.ts` | `mapUserProfile()` -- transforms DB user row to API response shape |
| normalize | `lib/normalize.ts` | `normalizeText()` -- lowercases, trims, strips diacritics for fuzzy matching |
| util | `lib/util.ts` | `uid(prefix)` -- generates prefixed unique IDs; `nowIso()` -- current ISO timestamp |
| retry | `lib/retry.ts` | `withRetry()` -- exponential backoff with configurable attempts |
| spotify-catalog | `lib/spotify-catalog.ts` | `searchSpotify()`, `upsertAlbumFromSpotify()` -- Spotify search + local catalog sync |
| musicbrainz-catalog | `lib/musicbrainz-catalog.ts` | `searchMusicBrainz()`, `upsertAlbumFromMusicBrainz()` -- free catalog fallback |
| spotify-adapter | `lib/spotify-adapter.ts` | Spotify OAuth adapter: `getOAuthUrl()`, `exchangeCode()`, `revokeToken()` |
| provider-adapter | `lib/provider-adapter.ts` | Abstract `ProviderAdapter` interface for multi-provider support |
| provider-registry | `lib/provider-registry.ts` | `getAdapter()`, `SUPPORTED_PROVIDERS` -- adapter lookup by provider name |
| dead-letter | `lib/dead-letter.ts` | Dead letter queue for failed async operations |
| token-refresh | `lib/token-refresh.ts` | Token refresh helper (currently dead code -- ISSUE-002) |

## Database Schema

8 migration files, 24+ tables. Migrations run automatically on server startup via `runMigrations.ts`.

| Table | Migration | Key Columns | Purpose |
|-------|-----------|-------------|---------|
| `users` | 001 | id, email, password_hash, handle, bio, log_count, review_count, avg_rating | User accounts with aggregate counters |
| `sessions` | 001, 006 | access_token, user_id, expires_at | Bearer token sessions (24h expiry) |
| `albums` | 001, 006, 007, 008 | id, title, artist, year, artwork_url, avg_rating, search_vector, spotify_id | Album catalog with FTS + Spotify metadata |
| `ratings` | 001 | id, user_id, album_id, value (0-6) | Album ratings (unique per user+album) |
| `reviews` | 001 | id, user_id, album_id, body, revision | Reviews with optimistic concurrency |
| `follows` | 001 | follower_id, followee_id | Social follow graph (composite PK) |
| `listening_events` | 001, 004 | id, user_id, album_id, played_at, source, dedup_key | Play history from manual + provider sync |
| `activity_events` | 001 | id, actor_id, type, object_type, payload, reactions, comments | Feed events for social timeline |
| `lists` | 001 | id, owner_id, title, note | User-curated album lists |
| `list_items` | 001 | id, list_id, album_id, position, note | Ordered items within lists |
| `idempotency_keys` | 001 | user_id, route_key, idempotency_key, response_json | Write deduplication |
| `recap_snapshots` | 001 | id, user_id, week_start, week_end, payload | Weekly recap JSON snapshots |
| `notification_preferences` | 001 | user_id, social_enabled, recap_enabled, quiet_hours_* | Per-user notification settings |
| `device_tokens` | 001 | id, user_id, platform, device_token | Push notification device registrations |
| `notification_events` | 001, 002 | id, user_id, event_type, payload, collapse_key, dedupe_key | Notification queue with dedup |
| `analytics_events` | 001 | id, user_id, event_type, payload | Analytics tracking |
| `audit_events` | 003 | id, user_id, event_type, details, ip_address | Security audit trail (no FK for compliance) |
| `dead_letter_events` | 003 | id, event_type, payload, error, attempt_count | Failed async operation queue |
| `canonical_artists` | 004 | id, name, normalized_name | Normalized artist identities for mapping |
| `canonical_albums` | 004 | id, title, normalized_title, artist_id, year, track_count | SoundScore-owned canonical album IDs |
| `provider_mappings` | 004 | canonical_id, provider, provider_id, confidence, status | Provider-to-canonical mappings with confidence (0-1) |
| `sync_cursors` | 004 | user_id, provider, cursor_value | Sync resume points |
| `sync_jobs` | 004 | id, user_id, provider, status, progress, items_processed | Sync job state machine |
| `tracks` | 004 (tracks) | id, album_id, title, track_number, duration_ms, spotify_id | Per-track data |
| `track_ratings` | 004 (tracks) | id, user_id, track_id, album_id, value (0-6) | Per-track ratings |
| `provider_connections` | 005 | id, user_id, provider, access_token, refresh_token, scopes | OAuth tokens per provider |
| `oauth_states` | 005 | state, user_id, provider, redirect_uri, expires_at | CSRF state (10-min expiry) |
| `album_genres` | 007 | album_id, genre | Genre junction table |

## API Routes

All 36 routes. Auth = requires `Authorization: Bearer <token>` header. Idempotency = requires `idempotency-key` header.

| Method | Path | Module | Auth | Idempotency | Description |
|--------|------|--------|------|-------------|-------------|
| GET | `/health` | server | No | No | Health check (Postgres + Redis probes) |
| POST | `/v1/auth/signup` | auth | No | No | Register new account |
| POST | `/v1/auth/login` | auth | No | No | Login with credentials |
| POST | `/v1/auth/refresh` | auth | No | No | Refresh access token |
| GET | `/v1/me` | auth | Yes | No | Get current user profile |
| GET | `/v1/search` | catalog | No | No | Search albums (FTS + external fallback) |
| GET | `/v1/albums/:id` | catalog | No | No | Get album by ID |
| POST | `/v1/albums/from-spotify` | catalog | No | No | Upsert album from Spotify data |
| GET | `/v1/log/recently-played` | opinions | Yes | No | User listening history |
| POST | `/v1/ratings` | opinions | Yes | Yes | Create/update album rating |
| POST | `/v1/reviews` | opinions | Yes | Yes | Create album review |
| PUT | `/v1/reviews/:id` | opinions | Yes | Yes | Update review (optimistic lock) |
| POST | `/v1/follow/:userId` | social | Yes | Yes | Follow user |
| DELETE | `/v1/follow/:userId` | social | Yes | Yes | Unfollow user |
| GET | `/v1/feed` | social | Yes | No | Activity feed (cached page 1) |
| POST | `/v1/activity/:id/react` | social | Yes | Yes | React to activity |
| POST | `/v1/activity/:id/comment` | social | Yes | Yes | Comment on activity |
| POST | `/v1/lists` | lists | Yes | Yes | Create list |
| POST | `/v1/lists/:id/items` | lists | Yes | Yes | Add item to list |
| GET | `/v1/lists/:id` | lists | No | No | Get list detail |
| POST | `/v1/account/export` | trust | Yes | No | Export all user data |
| DELETE | `/v1/account` | trust | Yes | No | Delete account |
| GET | `/v1/recaps/weekly/latest` | recaps | Yes | No | Latest weekly recap |
| POST | `/v1/recaps/weekly/generate` | recaps | Yes | Yes | Generate weekly recap |
| POST | `/v1/push/tokens` | push | Yes | Yes | Register device token |
| DELETE | `/v1/push/tokens/:deviceToken` | push | Yes | Yes | Remove device token |
| GET | `/v1/push/preferences` | push | Yes | No | Get notification prefs |
| PUT | `/v1/push/preferences` | push | Yes | Yes | Update notification prefs |
| GET | `/v1/notifications` | push | Yes | No | List notifications |
| POST | `/v1/notifications/test-recap` | push | Yes | Yes | Test recap notification |
| POST | `/v1/providers/:provider/connect` | providers | Yes | No | Start OAuth flow |
| POST | `/v1/providers/:provider/callback` | providers | Yes | No | Complete OAuth exchange |
| GET | `/v1/providers/:provider/status` | providers | Yes | No | Check connection status |
| POST | `/v1/providers/:provider/disconnect` | providers | Yes | No | Disconnect provider |
| GET | `/v1/mappings/lookup` | mapping | No | No | Lookup canonical mapping |
| POST | `/v1/mappings/resolve` | mapping | No | No | Resolve provider to canonical |
| POST | `/v1/sync/start` | import | Yes | No | Start sync job |
| GET | `/v1/sync/status/:sync_id` | import | Yes | No | Check sync progress |
| POST | `/v1/sync/cancel` | import | Yes | No | Cancel sync job |

## Environment Variables

Validated by Zod in `config/env.ts`. All have defaults for development.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `8080` | Server port |
| `HOST` | No | `0.0.0.0` | Bind address |
| `DATABASE_URL` | Prod only | `postgresql://soundscore:soundscore@localhost:5432/soundscore` | Postgres connection string |
| `REDIS_URL` | Prod only | `redis://localhost:6379` | Redis connection string |
| `AUTH_SALT_ROUNDS` | No | `10` | bcrypt cost factor |
| `SPOTIFY_CLIENT_ID` | No | (empty) | Spotify OAuth client ID |
| `SPOTIFY_CLIENT_SECRET` | No | (empty) | Spotify OAuth client secret |
| `ALLOWED_ORIGINS` | No | `http://localhost:3000` | CORS origins (comma-separated) |
| `NODE_ENV` | No | `development` | `development`, `production`, or `test` |
| `LOG_LEVEL` | No | `info` | Pino log level: fatal, error, warn, info, debug, trace |

In production, `DATABASE_URL` and `REDIS_URL` must be explicitly set (no dev defaults).

## Testing

9 test files, 88 total tests (79 pass, 9 fail as of 2026-03-19).

| Test File | Covers | Status |
|-----------|--------|--------|
| `tests/audit.test.ts` | Audit event logging | Pass |
| `tests/error-handling.test.ts` | Error handler, malformed JSON responses | 1 fail (Fastify returns 500 for invalid JSON instead of 400) |
| `tests/import.test.ts` | Dedup key generation, sync job mapping | Pass |
| `tests/integration.test.ts` | Full request lifecycle, idempotency | 1 fail (idempotency returns 409 instead of cached 200) |
| `tests/mappers.test.ts` | DB-to-API response mappers | Pass |
| `tests/mapping.test.ts` | Canonical album matching, scoring | Pass |
| `tests/production-readiness.test.ts` | Structural checks, security headers | 7 fail (stale expectations) |
| `tests/providers.test.ts` | Provider adapter registry, validation | Pass |
| `tests/retry.test.ts` | Exponential backoff retry logic | Pass |

Test coverage gap: 8/11 modules have zero test files. Only `import`, `mapping`, and `providers` have tests (utility functions only). No route-level integration tests exist for auth, catalog, opinions, social, lists, trust, push, or recaps.

## Deployment

- **Docker**: `docker-compose.prod.yml` for production containers
- **Railway**: `railway.json` config for one-click deploy
- **Supabase**: Edge functions under `supabase/functions/`, migrations under `supabase/migrations/`
- **Migrations**: Run automatically on server startup via `runMigrations.ts`

## Security

| Layer | Implementation |
|-------|---------------|
| Rate limiting | Global 100/min + per-route: auth 10/min, sensitive 3/hr, writes 30/min |
| Auth middleware | Bearer token validation against `sessions` table with expiry check |
| SQL injection | All queries use parameterized `$N` placeholders (zero template-literal SQL) |
| XSS prevention | `stripHtml()` sanitizes all user-submitted content (reviews, list notes) |
| CSRF (OAuth) | Crypto-random state parameter with 10-minute expiry |
| Idempotency | `idempotency-key` header deduplicates all mutating write operations |
| Security headers | `@fastify/helmet` applied globally |
| CORS | Explicit origin allowlist (no wildcard in production) |
| Audit trail | `audit_events` table logs auth, data export, account deletion with IP/UA |
| Password hashing | bcryptjs with configurable salt rounds |

## Known Issues (from audit)

| ID | Priority | Description |
|----|----------|-------------|
| ISSUE-001 | P1 | 10+ Phase 2 route handlers use `as {...}` type assertions instead of Zod `.parse()` |
| ISSUE-002 | P3 | 6 dead exports in lib/ including entirely dead `token-refresh.ts` |
| ISSUE-003 | P1 | 8/11 modules have zero test files; only utility functions tested |
| ISSUE-004 | P3 | 9 console.log calls bypass Pino (acceptable: pre-Fastify startup context) |
| ISSUE-005 | P2 | No account lockout after repeated failed logins |
| ISSUE-030 | P2 | 20/36 backend routes lack typed contract schemas |
| ISSUE-033 | P2 | `fetchRecentPlays()` in import.ts is still a mock (not connected to real Spotify API) |

---

Last audited: 2026-03-19
