# Overnight Progress Tracker

> **Updated by**: Agent 0 (Context Seed) at session start
>
> Each subsequent agent MUST update this file before ending their session:
> - Check off completed items
> - Add issues to "Issues Found"
> - Add decisions to "Decisions Made"
> - Leave notes for the next agent in "Handoff Notes"

---

## Phase 1: Foundation (_shared/ and index.ts)

> **Agent assignment**: Agent 1
>
> All `_shared/` files that are already ported (db.ts, redis.ts, auth.ts, errors.ts)
> should be VERIFIED against the Fastify originals, not rewritten from scratch.

- [x] _shared/db.ts (exists -- verify against backend/src/db/client.ts)
- [x] _shared/redis.ts (exists -- verify against ioredis usage in backend)
- [x] _shared/auth.ts (exists -- verify against server.ts:32-48)
- [x] _shared/errors.ts (exists -- verify against backend/src/lib/errors.ts)
- [ ] _shared/util.ts (port from backend/src/lib/util.ts -- replace `node:crypto` with global `crypto`)
- [ ] _shared/sanitize.ts (port from backend/src/lib/sanitize.ts -- no changes needed)
- [ ] _shared/normalize.ts (port from backend/src/lib/normalize.ts -- no changes needed)
- [ ] _shared/pagination.ts (port from backend/src/lib/pagination.ts -- replace FastifyRequest with Hono Context)
- [ ] _shared/idempotency.ts (port from backend/src/lib/idempotency.ts -- replace FastifyRequest with Hono Context, db.query with query)
- [ ] _shared/notifications.ts (port from backend/src/lib/notifications.ts -- async SHA-256, db.query to query, db.redis to cacheDel)
- [ ] _shared/audit.ts (port from backend/src/lib/audit.ts -- db.query to query)
- [ ] _shared/dead-letter.ts (port from backend/src/lib/dead-letter.ts -- db.query to query)
- [ ] _shared/retry.ts (port from backend/src/lib/retry.ts -- no changes needed)
- [ ] _shared/mappers.ts (port from backend/src/lib/mappers.ts -- inline types)
- [ ] _shared/rate-limit.ts (NEW -- Upstash rate limit middleware, see ARCHITECTURE_DECISIONS.md section 5)
- [ ] _shared/contracts/ (copy from packages/contracts/src/ -- change zod import to npm:zod)
- [ ] index.ts (Hono app setup: cors, secureHeaders, error handler, timing middleware, health check, route mounting)

## Phase 2: Core Modules (routes/)

> **Agent assignment**: Agents 2-5 (one module per agent, or grouped)
>
> Each route file exports a Hono sub-router. See EDGE_MIGRATION_LOG.md section 5
> for the pattern. See section 9 for the complete endpoint inventory per module.

- [ ] routes/auth.ts (4 endpoints -- port from backend/src/modules/auth.ts)
  - POST /v1/auth/signup (NO auth)
  - POST /v1/auth/login (NO auth)
  - POST /v1/auth/refresh (NO auth)
  - GET /v1/me (auth required)
  - Dependencies: bcrypt, contracts/endpoints, util, audit, mappers, redis cache

- [ ] routes/catalog.ts (3 endpoints -- port from backend/src/modules/catalog.ts)
  - GET /v1/search (NO auth)
  - POST /v1/albums/from-spotify (NO auth)
  - GET /v1/albums/:id (NO auth)
  - Dependencies: pagination, spotify-catalog, musicbrainz-catalog, redis cache

- [ ] routes/opinions.ts (4 endpoints -- port from backend/src/modules/opinions.ts)
  - GET /v1/log/recently-played (auth required)
  - POST /v1/ratings (auth required, idempotency)
  - POST /v1/reviews (auth required, idempotency)
  - PUT /v1/reviews/:id (auth required, idempotency)
  - Dependencies: contracts/endpoints, pagination, idempotency, notifications, audit, sanitize, util, redis cache

- [ ] routes/social.ts (5 endpoints -- port from backend/src/modules/social.ts)
  - POST /v1/follow/:userId (auth required, idempotency)
  - DELETE /v1/follow/:userId (auth required, idempotency)
  - GET /v1/feed (auth required)
  - POST /v1/activity/:id/react (auth required, idempotency)
  - POST /v1/activity/:id/comment (auth required, idempotency)
  - Dependencies: contracts/endpoints, pagination, idempotency, notifications, redis cache

- [ ] routes/lists.ts (3 endpoints -- port from backend/src/modules/lists.ts)
  - POST /v1/lists (auth required, idempotency)
  - POST /v1/lists/:id/items (auth required, idempotency)
  - GET /v1/lists/:id (NO auth)
  - Dependencies: contracts/endpoints, idempotency, notifications, audit, sanitize, util, redis cache

- [ ] routes/trust.ts (2 endpoints -- port from backend/src/modules/trust.ts)
  - POST /v1/account/export (auth required)
  - DELETE /v1/account (auth required)
  - Dependencies: audit, redis cache

- [ ] routes/recaps.ts (2 endpoints -- port from backend/src/modules/recaps.ts)
  - GET /v1/recaps/weekly/latest (auth required)
  - POST /v1/recaps/weekly/generate (auth required, idempotency)
  - Dependencies: idempotency, notifications, util

## Phase 3: Remaining Modules

> **Agent assignment**: Agents 6-8

- [ ] routes/push.ts (6 endpoints -- port from backend/src/modules/push.ts)
  - POST /v1/push/tokens (auth required, idempotency)
  - DELETE /v1/push/tokens/:deviceToken (auth required, idempotency)
  - GET /v1/push/preferences (auth required)
  - PUT /v1/push/preferences (auth required, idempotency)
  - GET /v1/notifications (auth required)
  - POST /v1/notifications/test-recap (auth required, idempotency)
  - Dependencies: contracts/endpoints, idempotency, notifications, util

- [ ] routes/providers.ts (4 endpoints -- port from backend/src/modules/providers.ts)
  - POST /v1/providers/:provider/connect (auth required)
  - POST /v1/providers/:provider/callback (auth required)
  - GET /v1/providers/:provider/status (auth required)
  - POST /v1/providers/:provider/disconnect (auth required)
  - Dependencies: provider-registry, spotify-adapter, util

- [ ] routes/import.ts (3 endpoints -- port from backend/src/modules/import.ts)
  - POST /v1/sync/start (auth required)
  - GET /v1/sync/status/:sync_id (auth required)
  - POST /v1/sync/cancel (auth required)
  - Dependencies: mapping module (resolveMapping), util
  - NOTE: Background processSync() -- see ARCHITECTURE_DECISIONS.md section 13

- [ ] routes/mapping.ts (2 endpoints -- port from backend/src/modules/mapping.ts)
  - GET /v1/mappings/lookup (NO auth)
  - POST /v1/mappings/resolve (NO auth)
  - Dependencies: normalize, util
  - NOTE: Also exports resolveMapping() used by import.ts

- [ ] _shared/spotify-catalog.ts (port from backend/src/lib/spotify-catalog.ts)
  - Replace Buffer.from with btoa
  - Replace env import with Deno.env.get
  - Replace db.query with query import

- [ ] _shared/spotify-adapter.ts (port from backend/src/lib/spotify-adapter.ts)
  - Replace Buffer.from with btoa
  - Replace env import with Deno.env.get

- [ ] _shared/musicbrainz-catalog.ts (port from backend/src/lib/musicbrainz-catalog.ts)
  - Replace db.query with query import
  - No other changes needed

- [ ] _shared/provider-adapter.ts (port from backend/src/lib/provider-adapter.ts -- no changes)

- [ ] _shared/provider-registry.ts (port from backend/src/lib/provider-registry.ts -- import path changes)

- [ ] _shared/token-refresh.ts (port from backend/src/lib/token-refresh.ts -- db.query to query)

## Phase 4: Integration & Verification (Agent 9)

- [ ] Verify all routes are mounted in index.ts
- [ ] Verify all auth/no-auth annotations match the endpoint inventory
- [ ] Verify no Node.js imports remain (grep for "node:")
- [ ] Verify no `db.query` or `db.redis` references remain (should use `query` and `cacheGet/Set/Del`)
- [ ] Verify all Deno imports use correct URL specifiers or import map
- [ ] Smoke-test health check endpoint
- [ ] Verify error envelope format matches Fastify version
- [ ] Document any known gaps or TODO items

---

## Issues Found

> Each agent should add issues here with their agent number.

(none yet)

---

## Decisions Made

> Each agent should document decisions they make during implementation.

| Agent | Decision | Rationale |
| ----- | -------- | --------- |
| 0     | Already-ported files (_shared/db.ts, redis.ts, auth.ts, errors.ts) should be verified, not rewritten | They exist and appear correct; avoid duplicate work |
| 0     | Contracts copied into _shared/contracts/ rather than using monorepo import | Edge Functions don't have access to the packages/ directory at runtime |
| 0     | processSync() runs inline for V1 (not background) | Mock provider returns only 2 items; real background processing is a follow-up |

---

## Handoff Notes

> Each agent should leave notes for the next agent about what they completed,
> what's partially done, and any gotchas they encountered.

### Agent 0 (Context Seed)
- Read all 30+ source files from backend/src/ and packages/contracts/src/
- Created three seed documents:
  - `docs/EDGE_MIGRATION_LOG.md` -- Complete mapping of every pattern, import, query, and endpoint
  - `docs/ARCHITECTURE_DECISIONS.md` -- Rationale for every architectural choice
  - `docs/OVERNIGHT_PROGRESS.md` -- This file
- Four `_shared/` files already exist in `supabase/functions/api/_shared/`:
  - `db.ts` -- deno-postgres pool + query adapter
  - `redis.ts` -- Upstash REST cacheGet/cacheSet/cacheDel
  - `auth.ts` -- requireAuth Hono middleware
  - `errors.ts` -- ApiError class + handleError for Hono
- These look correct but should be verified against the Fastify originals
- The `index.ts` entry point does NOT exist yet -- Agent 1 should create it
- All SQL queries are portable as-is (parameterized $1 syntax, same in deno-postgres)
- Key gotcha: `crypto.subtle.digest` is async in Deno -- the `toDedupeKey` function in notifications.ts must become async
- Key gotcha: `Buffer.from().toString("base64")` must become `btoa()` in spotify-catalog.ts and spotify-adapter.ts
- Key gotcha: Hono requires explicit `return c.json(...)` -- Fastify auto-serializes plain object returns
