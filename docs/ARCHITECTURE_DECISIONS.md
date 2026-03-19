# Architecture Decisions: Edge Function Migration

> **Purpose**: Explain the architectural rationale behind every major decision
> in the SoundScore backend migration from Fastify/Node.js to Hono/Deno on
> Supabase Edge Functions. Every overnight agent MUST read this document before
> writing any code.

---

## Table of Contents

1. [Why a Single Edge Function with Hono](#1-why-a-single-edge-function-with-hono)
2. [Why Raw SQL via deno-postgres](#2-why-raw-sql-via-deno-postgres)
3. [Why Custom Auth Stays](#3-why-custom-auth-stays)
4. [Why Upstash REST for Redis](#4-why-upstash-rest-for-redis)
5. [Rate Limiting Without @fastify/rate-limit](#5-rate-limiting-without-fastifyrate-limit)
6. [CORS Without @fastify/cors](#6-cors-without-fastifycors)
7. [Security Headers Without @fastify/helmet](#7-security-headers-without-fastifyhelmet)
8. [What We Intentionally Drop](#8-what-we-intentionally-drop)
9. [What We Intentionally Keep](#9-what-we-intentionally-keep)
10. [File Structure Convention](#10-file-structure-convention)
11. [Environment Variable Strategy](#11-environment-variable-strategy)
12. [Idempotency Key Handling](#12-idempotency-key-handling)
13. [Background Processing Constraints](#13-background-processing-constraints)
14. [bcrypt in Deno](#14-bcrypt-in-deno)
15. [Import Map Strategy](#15-import-map-strategy)

---

## 1. Why a Single Edge Function with Hono

**Decision**: Deploy all 11 route modules as ONE Edge Function (`supabase/functions/api/`)
with Hono as the router, not one function per module.

**Rationale**:

- **Cold start multiplier**: Each Edge Function has its own cold start. With 11
  separate functions, the worst-case cold start cost is 11x for a user session
  that touches multiple endpoints. A single function amortizes the cold start
  across all requests after the first.

- **Shared connection pool**: The deno-postgres `Pool` (3 connections, lazy) is
  initialized once and shared across all route handlers within one invocation.
  Separate functions would each maintain their own pool, multiplying connection
  pressure on Supabase Postgres.

- **Shared Upstash client**: Same reasoning -- one Redis REST client instance.

- **Code sharing**: The `_shared/` directory (auth, db, redis, errors, util,
  pagination, idempotency, notifications, audit) is imported directly by route
  modules. No need for Deno Deploy bundle/link gymnastics.

- **Hono is lightweight**: Hono's tree-based router adds negligible overhead.
  The entire Hono framework is ~14KB. It's purpose-built for edge runtimes.

- **Deployment simplicity**: One `supabase functions deploy api` command deploys
  everything. Route changes don't require updating Supabase function routing config.

**Trade-off acknowledged**: A single function's bundle size is larger than any
individual module. If any one module has a bug that crashes the function, all
routes are affected. We accept this because:
- The Hono error handler isolates request-level errors (no process crash)
- Edge Functions are ephemeral workers -- a crash only affects one request
- We can split later if bundle size becomes a deploy-time concern

---

## 2. Why Raw SQL via deno-postgres

**Decision**: Use `deno-postgres` with raw parameterized SQL queries, not the
Supabase JS client (`@supabase/supabase-js`).

**Rationale**:

- **Query preservation**: The Fastify backend has ~80+ hand-written SQL queries
  across 11 modules. Every single one uses standard PostgreSQL features:
  parameterized `$1` placeholders, `ON CONFLICT ... DO UPDATE`, `plainto_tsquery`,
  `ANY($1::text[])`, `COALESCE`, `AVG`, aggregate subqueries, etc.
  Rewriting these into Supabase JS client `.from().select().eq()` chains would be
  a massive, error-prone effort with subtle behavioral differences.

- **Full-text search**: The catalog search uses `search_vector @@ plainto_tsquery('english', $1)`.
  The Supabase JS client has `.textSearch()` but its behavior differs from raw
  `plainto_tsquery` in edge cases. Keeping the raw SQL preserves exact behavior.

- **Complex aggregates**: Multiple modules use aggregate subqueries:
  ```sql
  UPDATE users SET log_count = stat.log_count, avg_rating = stat.avg_rating
  FROM (SELECT COUNT(*)::int AS log_count, ...) stat WHERE users.id = $1
  ```
  These are not expressible with the Supabase JS client.

- **Transaction support**: The import module's `processSync()` and the migration
  runner use explicit `BEGIN`/`COMMIT`/`ROLLBACK`. The Supabase JS client
  does not support explicit transactions.

- **Type safety**: Both `pg` (Node) and `deno-postgres` support generic type
  parameters: `query<{ id: string }>(sql, params)`. The adapter in
  `_shared/db.ts` preserves this interface.

- **Already implemented**: `_shared/db.ts` already provides a `query<T>()`
  function that returns `{ rows: T[], rowCount: number }` -- the same shape as
  the Node.js `pg` library. Zero SQL rewrites needed.

**Trade-off acknowledged**: We bypass Supabase's Row Level Security (RLS). This
is acceptable because:
- The existing backend has its own auth layer (sessions table, Bearer tokens)
- All authorization checks are explicit in route handlers
- RLS would add complexity without matching the existing auth model

---

## 3. Why Custom Auth Stays

**Decision**: Keep the custom `sessions` table + Bearer token auth system.
Do NOT migrate to Supabase Auth.

**Rationale**:

- **Mobile clients are hard-coded**: Both iOS and Android apps send
  `Authorization: Bearer <access_token>` headers and call `/v1/auth/login`,
  `/v1/auth/signup`, `/v1/auth/refresh`. Migrating to Supabase Auth would require
  simultaneous mobile app updates -- a coordinated release we want to avoid.

- **Session management**: The current system has:
  - Custom session table with access tokens and expiry
  - Refresh token rotation (stored on `users` table)
  - Expired session cleanup on login/refresh
  - Audit logging of auth events
  All of this works and is well-tested.

- **Auth middleware is already ported**: `_shared/auth.ts` implements the same
  session-lookup logic as Hono middleware. It queries `sessions WHERE
  access_token = $1 AND expires_at > NOW()` and sets `c.set("userId", ...)`.

- **Password hashing**: The system uses `bcryptjs` for password hashing with
  configurable salt rounds. Supabase Auth uses its own hashing. Migrating would
  require a password reset for all users or a complex hash-migration scheme.

**Future consideration**: A migration to Supabase Auth can happen later as a
separate project, with a transition period where both auth systems are accepted.

---

## 4. Why Upstash REST for Redis

**Decision**: Replace `ioredis` (TCP-based Redis client) with Upstash REST SDK.

**Rationale**:

- **Edge Functions do not support persistent TCP connections**: Supabase Edge
  Functions (Deno Deploy) run in V8 isolates that cannot open raw TCP sockets.
  The `ioredis` library requires a TCP connection to Redis. This is a hard
  technical constraint -- there is no workaround.

- **Upstash REST SDK**: Upstash provides a Redis-compatible service with an
  HTTP/REST API. The `@upstash/redis` Deno SDK communicates over HTTPS, which
  works in edge runtimes. Each Redis operation is one HTTP request.

- **Already implemented**: `_shared/redis.ts` provides `cacheGet`, `cacheSet`,
  `cacheDel` using the Upstash SDK. These map to the ioredis operations used in
  the Fastify backend.

**API mapping** (see EDGE_MIGRATION_LOG.md section 4 for full details):

| ioredis                              | Upstash REST via _shared/redis.ts    |
| ------------------------------------ | ------------------------------------ |
| `redis.get(key)` returns string      | `cacheGet<T>(key)` returns parsed T  |
| `redis.setex(key, ttl, jsonString)`  | `cacheSet(key, value, ttl)`          |
| `redis.del(key1, key2)`             | `cacheDel(key1, key2)`               |
| `redis.status === "ready"`           | Always ready (stateless REST)        |

**Important behavioral difference**: `cacheGet` auto-parses JSON. Code that
previously did `JSON.parse(await redis.get(key))` must simply do
`await cacheGet<Type>(key)` -- no `JSON.parse` wrapper.

**Performance note**: Each Redis op is an HTTP round-trip (~5-20ms depending on
region). The existing codebase uses Redis for:
- Profile cache (TTL 90s) -- 1 read per `/v1/me` request
- Feed page1 cache (TTL 90s) -- 1 read per `/v1/feed` request
- Spotify search cache (TTL 300s) -- 1 read per search
- Cache invalidation on writes -- 1-N deletes

This is acceptable for the current usage pattern. We are NOT using Redis for
high-frequency operations.

---

## 5. Rate Limiting Without @fastify/rate-limit

**Decision**: Implement rate limiting using Upstash Rate Limit SDK.

**Rationale**:

- `@fastify/rate-limit` is a Fastify plugin that uses in-memory or Redis-backed
  counters. It cannot be used with Hono.

- Upstash provides `@upstash/ratelimit` which uses their Redis REST API for
  distributed rate limiting. This works in edge runtimes and provides the same
  sliding-window semantics.

**Implementation approach**:

```typescript
import { Ratelimit } from "https://cdn.skypack.dev/@upstash/ratelimit";
import { getRedis } from "./redis.ts";

// Tier definitions (from backend/src/lib/rate-limit.ts):
const globalLimit = new Ratelimit({ redis: getRedis(), limiter: Ratelimit.slidingWindow(100, "1 m") });
const authLimit = new Ratelimit({ redis: getRedis(), limiter: Ratelimit.slidingWindow(10, "1 m") });
const sensitiveLimit = new Ratelimit({ redis: getRedis(), limiter: Ratelimit.slidingWindow(3, "1 h") });
const providerLimit = new Ratelimit({ redis: getRedis(), limiter: Ratelimit.slidingWindow(10, "1 m") });
const writeLimit = new Ratelimit({ redis: getRedis(), limiter: Ratelimit.slidingWindow(30, "1 m") });
```

**Rate limit tiers** (from `backend/src/lib/rate-limit.ts`):

| Tier       | Routes                                         | Max | Window   |
| ---------- | ----------------------------------------------- | --- | -------- |
| Global     | All routes (fallback)                           | 100 | 1 minute |
| Auth       | `/v1/auth/signup`, `/v1/auth/login`, `/v1/auth/refresh` | 10  | 1 minute |
| Sensitive  | `/v1/account/export`, `/v1/account` (DELETE)    | 3   | 1 hour   |
| Provider   | `/v1/providers/*`                               | 10  | 1 minute |
| Write      | All non-GET/HEAD not in above tiers             | 30  | 1 minute |

**Rate limit key**: Use IP address from `x-forwarded-for` header (Supabase Edge
Functions run behind a load balancer). For authenticated routes, could also use
`userId` as the key for per-user limiting.

**Response headers**: The Fastify backend returns `x-ratelimit-limit`,
`x-ratelimit-remaining`, `x-ratelimit-reset`, `retry-after`. The Upstash SDK
provides this data in the response object. Set headers manually in middleware.

**Phase note**: Rate limiting can be implemented as a Phase 1 item (foundation)
or deferred to a hardening phase. For MVP launch, the global Supabase rate limit
(set in project settings) provides basic protection.

---

## 6. CORS Without @fastify/cors

**Decision**: Use Hono's built-in `cors()` middleware.

**Implementation**:

```typescript
import { cors } from "jsr:@hono/hono/cors";

// From backend/src/server.ts lines 105-108:
// CORS with explicit origin allowlist
const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "http://localhost:3000")
  .split(",").map(s => s.trim());

app.use("*", cors({
  origin: allowedOrigins.includes("*") ? "*" : allowedOrigins,
  credentials: true,
}));
```

This is a 1:1 mapping of the Fastify CORS configuration.

---

## 7. Security Headers Without @fastify/helmet

**Decision**: Use Hono's built-in `secureHeaders()` middleware.

**Implementation**:

```typescript
import { secureHeaders } from "jsr:@hono/hono/secure-headers";

// From backend/src/server.ts lines 99-102:
// API-only, no CSP needed
app.use("*", secureHeaders({
  // Hono secure-headers does not enable CSP by default, which matches
  // the Fastify config: contentSecurityPolicy: false
  crossOriginResourcePolicy: "cross-origin",
}));
```

---

## 8. What We Intentionally Drop

### Swagger/OpenAPI Documentation

**Dropped**: `@fastify/swagger` and `@fastify/swagger-ui` (server.ts lines 78-96).

**Why**: Swagger auto-generation from Fastify schemas does not translate to Hono.
Hono has OpenAPI support via `@hono/zod-openapi` but integrating it requires
reworking all route definitions. This is a post-launch enhancement.

**Impact**: No `/docs` endpoint. API documentation continues to live in the
contracts package and project docs.

### In-Memory Rate Limit Counters

**Dropped**: `@fastify/rate-limit`'s in-memory counter mode.

**Why**: Edge Functions are ephemeral -- in-memory state does not persist between
requests. All rate limiting must use external state (Upstash Redis).

### Process-Level Lifecycle Hooks

**Dropped**: `app.addHook("onClose", ...)` for connection pool cleanup.

**Why**: Edge Functions are ephemeral workers. There is no process lifecycle --
the runtime manages connection cleanup. The deno-postgres pool is lazy and
connections are released after each query (see `_shared/db.ts` `finally { client.release() }`).

### Migration Runner

**Dropped**: `backend/src/db/runMigrations.ts` -- file-system-based SQL migration.

**Why**: Edge Functions do not have file system access. Database migrations should
be run via Supabase CLI (`supabase db push`) or the Supabase dashboard, not at
application startup. Migration files in `backend/src/db/schema/` are still the
source of truth for the schema.

### Dotenv

**Dropped**: `dotenv` package.

**Why**: Supabase Edge Functions receive environment variables via the Supabase
runtime. Use `Deno.env.get("KEY")` directly.

### Request Latency Logging via hrtime

**Dropped**: `process.hrtime.bigint()` timing (server.ts lines 159-181).

**Replaced with**: `performance.now()` in middleware. Supabase also provides
built-in request duration logging in the dashboard.

---

## 9. What We Intentionally Keep

### All SQL Queries -- Verbatim

Every SQL query from the Fastify backend is preserved exactly. The deno-postgres
driver uses the same `$1, $2, ...` parameterized syntax. Zero SQL rewrites.

### Error Response Format

The `{ error: { code, message, requestId } }` envelope is preserved.
`_shared/errors.ts` already implements this.

### Auth Flow

Bearer token lookup in `sessions` table. Custom `requireAuth` middleware.
Already ported in `_shared/auth.ts`.

### Idempotency System

The `withIdempotency` wrapper using the `idempotency_keys` table. Ported with
Hono `Context` instead of `FastifyRequest`.

### Notification Queue

The `notification_events` table with dedup keys, collapse keys, and the
`queueNotification` / `queueFollowerNotifications` helpers.

### Audit Logging

The `audit_events` table with scrubbed details. The `logAuditEvent` function.

### Dead Letter Queue

The `dead_letter_events` table for failed notification processing.

### Cursor-Based Pagination

The `parsePaginationParams` / `buildPaginatedResponse` system with
limit+1 over-fetch pattern.

### All Zod Validation Schemas

From `packages/contracts/src/`. Copied into `_shared/contracts/`.

### Spotify Client Credentials Flow

For catalog search. Ported with `btoa()` instead of `Buffer.from().toString("base64")`.

### Spotify OAuth Flow

For provider connections. Same port approach.

### MusicBrainz Search Fallback

Throttled fetch with 1-second rate limit. Cover Art Archive integration.

### Canonical Mapping System

`resolveMapping()`, `scoreMatch()`, `findOrCreateArtist()`, and the full
provider-mapping tables. All SQL queries preserved.

---

## 10. File Structure Convention

```
supabase/functions/api/
  index.ts                    # Hono app, middleware, route mounting, app.onError
  _shared/
    db.ts                     # [DONE] deno-postgres pool + query<T>()
    redis.ts                  # [DONE] Upstash REST cacheGet/cacheSet/cacheDel
    auth.ts                   # [DONE] requireAuth middleware
    errors.ts                 # [DONE] ApiError class + handleError
    util.ts                   # uid(), nowIso()
    sanitize.ts               # stripHtml()
    normalize.ts              # normalizeText()
    pagination.ts             # parsePaginationParams(), buildPaginatedResponse()
    idempotency.ts            # withIdempotency()
    notifications.ts          # queueNotification(), queueFollowerNotifications(), invalidateFeedCacheForUserAndFollowers()
    audit.ts                  # logAuditEvent()
    dead-letter.ts            # moveToDeadLetter(), listRecentDeadLetters()
    retry.ts                  # withRetry()
    mappers.ts                # mapUserProfile(), tryJsonParse()
    rate-limit.ts             # Upstash rate limit middleware
    spotify-catalog.ts        # searchSpotify(), upsertAlbumFromSpotify()
    spotify-adapter.ts        # SpotifyAdapter class
    musicbrainz-catalog.ts    # searchMusicBrainz(), upsertAlbumFromMusicBrainz()
    provider-adapter.ts       # ProviderAdapter interface, TokenBundle
    provider-registry.ts      # getAdapter(), SUPPORTED_PROVIDERS
    token-refresh.ts          # ensureFreshToken()
    contracts/                # Copied from packages/contracts/src/
      index.ts
      common.ts
      models.ts
      endpoints.ts
      events.ts
      provider.ts
      mapping.ts
      sync.ts
      compliance.ts
  routes/
    auth.ts                   # /v1/auth/signup, /v1/auth/login, /v1/auth/refresh, /v1/me
    catalog.ts                # /v1/search, /v1/albums/from-spotify, /v1/albums/:id
    opinions.ts               # /v1/log/recently-played, /v1/ratings, /v1/reviews, /v1/reviews/:id
    social.ts                 # /v1/follow/:userId, /v1/feed, /v1/activity/:id/react, /v1/activity/:id/comment
    lists.ts                  # /v1/lists, /v1/lists/:id/items, /v1/lists/:id
    trust.ts                  # /v1/account/export, /v1/account (DELETE)
    recaps.ts                 # /v1/recaps/weekly/latest, /v1/recaps/weekly/generate
    push.ts                   # /v1/push/tokens, /v1/push/preferences, /v1/notifications, etc.
    providers.ts              # /v1/providers/:provider/connect|callback|status|disconnect
    import.ts                 # /v1/sync/start, /v1/sync/status/:sync_id, /v1/sync/cancel
    mapping.ts                # /v1/mappings/lookup, /v1/mappings/resolve
```

---

## 11. Environment Variable Strategy

### Fastify Backend (backend/src/config/env.ts)

Uses `dotenv` + Zod validation:
- `PORT`, `HOST`, `DATABASE_URL`, `REDIS_URL`, `AUTH_SALT_ROUNDS`,
  `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, `ALLOWED_ORIGINS`,
  `NODE_ENV`, `LOG_LEVEL`

### Supabase Edge Functions

Environment variables are set via `supabase secrets set` and accessed via
`Deno.env.get()`. Required variables:

| Variable                    | Fastify Equivalent       | Notes                                      |
| --------------------------- | ------------------------ | ------------------------------------------ |
| `SUPABASE_DB_URL`           | `DATABASE_URL`           | Supabase provides this automatically       |
| `UPSTASH_REDIS_REST_URL`    | `REDIS_URL`              | Upstash REST endpoint (not TCP)            |
| `UPSTASH_REDIS_REST_TOKEN`  | (new)                    | Upstash auth token                         |
| `SPOTIFY_CLIENT_ID`         | `SPOTIFY_CLIENT_ID`      | Same value                                 |
| `SPOTIFY_CLIENT_SECRET`     | `SPOTIFY_CLIENT_SECRET`  | Same value                                 |
| `ALLOWED_ORIGINS`           | `ALLOWED_ORIGINS`        | Comma-separated origins                    |
| `AUTH_SALT_ROUNDS`          | `AUTH_SALT_ROUNDS`       | bcrypt rounds (default: 10)                |

**Do NOT use a Zod env schema with `process.exit()`**. Instead, fail fast at
the point of use: the singleton constructors in `_shared/db.ts` and
`_shared/redis.ts` already throw if their required env vars are missing.

---

## 12. Idempotency Key Handling

The Fastify backend requires an `idempotency-key` header on all mutating
endpoints. The `withIdempotency()` function in `backend/src/lib/idempotency.ts`:

1. Reads `request.headers["idempotency-key"]`
2. Builds a compound key: `userId + routeKey + idempotencyKey`
3. Inserts into `idempotency_keys` table with `ON CONFLICT ... DO NOTHING`
4. If already exists, returns the cached `response_json`
5. If new, executes the handler, stores the result, marks complete
6. On error, marks failed and re-throws

**Hono port changes**:
- `request.headers["idempotency-key"]` becomes `c.req.header("Idempotency-Key")`
- `request.method` becomes `c.req.method`
- `request.url.split("?")[0]` becomes `c.req.path`
- `db.query(...)` becomes `query(...)`

The function signature changes from:
```typescript
withIdempotency<T>(request: FastifyRequest, db: Db, userId: string, handler: () => Promise<T>)
```
To:
```typescript
withIdempotency<T>(c: Context, userId: string, handler: () => Promise<T>)
```

---

## 13. Background Processing Constraints

The `processSync()` function in `backend/src/modules/import.ts` is fire-and-forget:

```typescript
processSync(db, jobId).catch((err) => { app.log.error(...) });
```

**Edge Function constraint**: Edge Functions have a maximum execution time
(typically 150 seconds on Supabase free tier, configurable higher on paid).
The sync process iterates over listening events, resolves mappings, and
inserts records -- this can take longer than the request timeout.

**Options**:
1. **Use `EdgeRuntime.waitUntil()`** (if available): Keeps the function alive
   after the response is sent. The sync runs in the background.
2. **Inline sync**: Process the sync within the request, accepting the timeout
   risk for small syncs (the mock provider only returns 2 items).
3. **Separate Edge Function**: Create a `supabase/functions/sync-worker/`
   function invoked via `Deno.connect()` or Supabase's `invoke()`.

**Decision for V1**: Use option 2 (inline) since the mock provider returns only
2 items. Document this as a known limitation. Real provider integration will
need option 3.

---

## 14. bcrypt in Deno

**Fastify**: Uses `bcryptjs` (pure JavaScript bcrypt implementation).

**Deno**: Use `https://deno.land/x/bcrypt@v0.4.1/mod.ts` which provides the
same API:

```typescript
import * as bcrypt from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

// Hash:
const hash = await bcrypt.hash(password, saltRounds);
// Compare:
const matches = await bcrypt.compare(password, hash);
```

**Note**: The Deno bcrypt library's `hash()` and `compare()` are async (return
Promises), same as `bcryptjs`. No API change needed.

**Salt rounds**: Read from `Deno.env.get("AUTH_SALT_ROUNDS")` with default 10.

---

## 15. Import Map Strategy

Supabase Edge Functions support import maps via `supabase/config.toml` or a
`deno.json` file. Use an import map to simplify imports:

```json
{
  "imports": {
    "hono": "jsr:@hono/hono",
    "hono/": "jsr:@hono/hono/",
    "zod": "npm:zod",
    "@upstash/redis": "https://deno.land/x/upstash_redis@v1.34.3/mod.ts",
    "postgres": "https://deno.land/x/postgres@v0.19.3/mod.ts",
    "bcrypt": "https://deno.land/x/bcrypt@v0.4.1/mod.ts"
  }
}
```

This allows clean imports like:
```typescript
import { Hono } from "hono";
import { cors } from "hono/cors";
import { z } from "zod";
```

If the import map approach causes issues with Supabase deployment, fall back to
full URL specifiers in each file.
