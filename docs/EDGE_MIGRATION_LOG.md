# Edge Migration Log: Fastify/Node.js to Hono/Deno

> **Purpose**: Comprehensive mapping document for 9 overnight agents migrating
> the SoundScore backend from `backend/src/` (Fastify + Node.js) to
> `supabase/functions/api/` (Hono + Deno Edge Functions).

---

## Table of Contents

1. [Import Mappings: Node.js to Deno](#1-import-mappings-nodejs-to-deno)
2. [Framework Pattern Mappings: Fastify to Hono](#2-framework-pattern-mappings-fastify-to-hono)
3. [Database Access Pattern Mappings](#3-database-access-pattern-mappings)
4. [Redis Operation Mappings: ioredis to Upstash REST](#4-redis-operation-mappings-ioredis-to-upstash-rest)
5. [Route Registration Pattern](#5-route-registration-pattern)
6. [Request / Reply Handling](#6-request--reply-handling)
7. [Error Handling Pattern](#7-error-handling-pattern)
8. [Auth Middleware Pattern](#8-auth-middleware-pattern)
9. [Complete Endpoint Inventory](#9-complete-endpoint-inventory)
10. [Shared Utility Mappings](#10-shared-utility-mappings)
11. [Zod Schema Re-use Strategy](#11-zod-schema-re-use-strategy)

---

## 1. Import Mappings: Node.js to Deno

### Core Runtime

| Node.js (backend/src)                         | Deno (supabase/functions/api)                                  |
| ---------------------------------------------- | -------------------------------------------------------------- |
| `import crypto from "node:crypto"`              | `crypto` is a global in Deno (`crypto.randomUUID()`)            |
| `import { createHash } from "node:crypto"`      | `new Uint8Array(...)` + `crypto.subtle.digest("SHA-256", ...)`  |
| `import fs from "node:fs/promises"`             | `Deno.readTextFile()` / `Deno.readDir()` (not needed for Edge) |
| `import path from "node:path"`                  | Not needed (no file system access in Edge Functions)            |
| `import { fileURLToPath } from "node:url"`      | Not needed                                                     |
| `process.env.XXX`                               | `Deno.env.get("XXX")`                                          |
| `process.hrtime.bigint()`                       | `performance.now()` (returns ms float)                         |
| `Buffer.from(str).toString("base64")`           | `btoa(str)` (global)                                           |

### NPM Packages to Deno Equivalents

| NPM Package                  | Deno Equivalent                                          | Notes                                          |
| ----------------------------- | -------------------------------------------------------- | ---------------------------------------------- |
| `fastify`                     | `jsr:@hono/hono`                                          | Already chosen, see `_shared/errors.ts`         |
| `@fastify/cors`               | Hono `cors()` middleware from `jsr:@hono/hono/cors`       | Built-in                                       |
| `@fastify/helmet`             | Hono `secureHeaders()` from `jsr:@hono/hono/secure-headers` | Built-in                                    |
| `@fastify/rate-limit`         | Custom middleware using Upstash `@upstash/ratelimit`      | See architecture doc                           |
| `@fastify/swagger`            | Drop for now (post-launch)                               |                                                |
| `@fastify/swagger-ui`         | Drop for now (post-launch)                               |                                                |
| `pg` (Pool)                   | `https://deno.land/x/postgres@v0.19.3/mod.ts`            | Already implemented in `_shared/db.ts`          |
| `ioredis`                     | `https://deno.land/x/upstash_redis@v1.34.3/mod.ts`       | Already implemented in `_shared/redis.ts`       |
| `bcryptjs`                    | `https://deno.land/x/bcrypt@v0.4.1/mod.ts`               | API is nearly identical                        |
| `dotenv`                      | Not needed (Deno env handled by Supabase runtime)         |                                                |
| `zod`                         | `npm:zod` or `https://deno.land/x/zod/mod.ts`            | Keep as npm: specifier for compat               |

### Specific `crypto` Replacements

**`uid()` function** (backend/src/lib/util.ts line 5):
```
// Node: import crypto from "node:crypto";
// Node: `${prefix}_${crypto.randomUUID().replace(/-/g, "")}`
// Deno: crypto is a global
export const uid = (prefix: string) =>
  `${prefix}_${crypto.randomUUID().replace(/-/g, "")}`;
```

**SHA-256 hash** (backend/src/lib/notifications.ts line 47):
```
// Node: createHash("sha256").update(input).digest("hex").slice(0, 32)
// Deno:
const encoder = new TextEncoder();
const data = encoder.encode(input);
const hashBuffer = await crypto.subtle.digest("SHA-256", data);
const hashArray = Array.from(new Uint8Array(hashBuffer));
const hex = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
return hex.slice(0, 32);
```
Note: `crypto.subtle.digest` is async in Deno. The `toDedupeKey` function must become `async`.

**`crypto.randomBytes(32).toString("hex")`** (backend/src/modules/providers.ts line 45):
```
// Deno:
const bytes = new Uint8Array(32);
crypto.getRandomValues(bytes);
const hex = Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
```

---

## 2. Framework Pattern Mappings: Fastify to Hono

### App Initialization

**Fastify** (server.ts lines 50-64):
```
const app = Fastify({ logger: {...}, requestIdHeader: "x-request-id", genReqId: () => uid("req") });
```

**Hono**:
```
import { Hono } from "jsr:@hono/hono";
const app = new Hono();
```
Hono has no built-in logger or request ID generation. Use middleware.

### Plugin Registration

**Fastify** (server.ts lines 78-127):
```
await app.register(swagger, {...});
await app.register(helmet, {...});
await app.register(cors, {...});
app.register(rateLimit, {...});
```

**Hono**:
```
import { cors } from "jsr:@hono/hono/cors";
import { secureHeaders } from "jsr:@hono/hono/secure-headers";

app.use("*", cors({ origin: [...], credentials: true }));
app.use("*", secureHeaders());
// Rate limit is custom middleware (see section 4 of ARCHITECTURE_DECISIONS.md)
```

### Decorated Properties

**Fastify** (server.ts lines 74-75):
```
app.decorate("db", db);
app.decorate("requireAuth", (request) => resolveUserIdFromRequest(request, db));
```

**Hono**: No decoration pattern. Pass `db` and `redis` as module-level singletons
(already done in `_shared/db.ts` and `_shared/redis.ts`). Auth is middleware
(already done in `_shared/auth.ts`).

### Hooks

**Fastify** (server.ts lines 159-181):
```
app.addHook("onRequest", ...)   // request timing
app.addHook("onResponse", ...)  // latency logging
app.addHook("onClose", ...)     // cleanup
```

**Hono**:
```
// Timing middleware
app.use("*", async (c, next) => {
  const start = performance.now();
  await next();
  const ms = (performance.now() - start).toFixed(2);
  console.log(`${c.req.method} ${c.req.path} ${c.res.status} ${ms}ms`);
});
// No onClose needed - Edge Functions are ephemeral
```

### Error Handler

**Fastify** (server.ts lines 187-206):
```
app.setErrorHandler((error, request, reply) => {
  if (error instanceof ApiError) {
    return reply.status(error.statusCode).send({ error: {...} });
  }
  return reply.status(500).send({ error: {...} });
});
```

**Hono** (already implemented in `_shared/errors.ts` lines 43-73):
```
app.onError((err, c) => handleError(err, c));
```

---

## 3. Database Access Pattern Mappings

### Query Pattern

**Fastify/Node pg** (db/client.ts):
```
db.query<T>(text, params) → Promise<QueryResult<T>>
// QueryResult has: rows: T[], rowCount: number
```

**Deno postgres** (already in `_shared/db.ts`):
```
query<T>(text, params) → Promise<QueryResult<T>>
// Same shape: rows: T[], rowCount: number
```

The `_shared/db.ts` adapter already normalizes the deno-postgres result into
the same `{ rows, rowCount }` shape. All SQL queries can be used as-is.

### Critical Difference: How Modules Access `db`

**Fastify pattern** (every module):
```
export const registerXxxRoutes = (app: FastifyInstance, db: Db) => { ... }
```
The `Db` object bundles `pool`, `redis`, and `query`.

**Hono pattern**: Import singletons directly:
```
import { query } from "../_shared/db.ts";
import { cacheGet, cacheSet, cacheDel } from "../_shared/redis.ts";
```

Every `db.query(...)` call becomes `query(...)`.
Every `db.redis.get(...)` call becomes `cacheGet(...)`.
Every `db.redis.setex(key, ttl, value)` call becomes `cacheSet(key, value, ttl)`.
Every `db.redis.del(...keys)` call becomes `cacheDel(...keys)`.

### SQL Queries That Need No Changes

All SQL queries use standard PostgreSQL syntax with `$1`, `$2` parameterized
placeholders. The deno-postgres driver uses the same parameter syntax.
**Zero SQL rewrites needed.**

### Connection Pool Lifecycle

**Fastify**: Pool created in `createDb()`, closed via `onClose` hook.
**Deno Edge**: Pool is lazy singleton in `_shared/db.ts`. No explicit close
needed -- Edge Functions are ephemeral workers. Pool size is 3 (already set).

---

## 4. Redis Operation Mappings: ioredis to Upstash REST

The existing `_shared/redis.ts` provides `cacheGet`, `cacheSet`, `cacheDel`.
Here is the complete mapping of every Redis call in the codebase:

| Fastify Code                                        | Hono Equivalent                                  | Source File(s)                                    |
| ---------------------------------------------------- | ------------------------------------------------ | -------------------------------------------------- |
| `db.redis.get(key)`                                  | `cacheGet<string>(key)`                           | auth.ts:198, social.ts:61                          |
| `db.redis.setex(key, ttl, JSON.stringify(value))`     | `cacheSet(key, value, ttl)`                       | auth.ts:44,224, social.ts:119, catalog.ts:89       |
| `db.redis.del(key1, key2, ...)`                       | `cacheDel(key1, key2, ...)`                       | opinions.ts:146, social.ts:31,49, lists.ts:26, trust.ts:216-219 |
| `db.redis.status === "ready"`                         | Always "ready" (REST is stateless)                | server.ts:132 (health check only)                  |

### Important: `cacheGet` Returns Parsed JSON

The ioredis `.get()` returns a raw string. The Upstash `cacheGet<T>` in
`_shared/redis.ts` auto-parses JSON. So code like:
```
const cached = await db.redis.get(key);
if (cached) return JSON.parse(cached);
```
Becomes:
```
const cached = await cacheGet<SomeType>(key);
if (cached) return cached;  // Already parsed
```

### Feed Cache Pattern (social.ts lines 59-121)

```
// Read: cacheGet<FeedResponse>(`feed:${actorId}:page1`)
// Write: cacheSet(`feed:${actorId}:page1`, response, 90)
// Invalidate: cacheDel(`feed:${actorId}:page1`)
```

### Spotify Search Cache (catalog.ts lines 81-89)

```
// Read: cacheGet<SpotifyAlbumData[]>(`spotify_search:${query}`)
// Write: cacheSet(`spotify_search:${query}`, spotifyResults, 300)
```

### Profile Cache (auth.ts lines 23-48, 196-224)

```
// Read: cacheGet<UserProfile>(`profile:${userId}`)
// Write: cacheSet(`profile:${userId}`, profile, 90)
// Invalidate: cacheDel(`profile:${userId}`)
```

---

## 5. Route Registration Pattern

### Fastify Pattern

Each module exports a `registerXxxRoutes(app, db)` function that calls
`app.get(...)`, `app.post(...)`, etc., directly on the Fastify instance:

```typescript
// backend/src/modules/auth.ts
export const registerAuthRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/auth/signup", async (request, reply) => { ... });
  app.post("/v1/auth/login", async (request) => { ... });
};

// backend/src/server.ts
registerAuthRoutes(app, db);
registerCatalogRoutes(app, db);
// ... 11 register calls total
```

### Hono Pattern

Each module exports a Hono router (sub-app) that is mounted on the main app:

```typescript
// supabase/functions/api/routes/auth.ts
import { Hono } from "jsr:@hono/hono";
const auth = new Hono();

auth.post("/v1/auth/signup", async (c) => { ... });
auth.post("/v1/auth/login", async (c) => { ... });

export default auth;

// supabase/functions/api/index.ts
import auth from "./routes/auth.ts";
import catalog from "./routes/catalog.ts";

app.route("/", auth);
app.route("/", catalog);
```

Alternative: Use `app.route("/v1/auth", auth)` with relative paths in sub-routers.
Recommended: Keep full paths (`/v1/auth/signup`) in each router for clarity since
the mobile clients already hard-code full paths.

---

## 6. Request / Reply Handling

### Reading Request Data

| Fastify                                              | Hono                                              |
| ---------------------------------------------------- | -------------------------------------------------- |
| `request.body`                                        | `await c.req.json()`                                |
| `request.query as { q?: string }`                     | `c.req.query("q")` or `c.req.queries()`            |
| `request.params as { id: string }`                    | `c.req.param("id")`                                |
| `request.headers.authorization`                       | `c.req.header("Authorization")`                     |
| `request.headers["user-agent"]`                       | `c.req.header("User-Agent")`                        |
| `request.headers["idempotency-key"]`                  | `c.req.header("Idempotency-Key")`                   |
| `request.ip`                                          | `c.req.header("x-forwarded-for") ?? "unknown"`      |
| `request.id`                                          | `c.req.header("x-request-id") ?? crypto.randomUUID()` |
| `request.method`                                      | `c.req.method`                                      |
| `request.url`                                         | `c.req.url` or `c.req.path`                         |
| `request.routeOptions.url`                            | `c.req.routePath` (Hono pattern path)               |

### Sending Responses

| Fastify                                              | Hono                                              |
| ---------------------------------------------------- | -------------------------------------------------- |
| `return { ... }` (auto-JSON)                          | `return c.json({ ... })`                            |
| `reply.status(201).send({ ... })`                     | `return c.json({ ... }, 201)`                       |
| `reply.code(204).send()`                              | `return c.body(null, 204)`                          |
| `reply.status(503).send({ ... })`                     | `return c.json({ ... }, 503)`                       |
| `reply.status(400).send({ error: "..." })`            | `return c.json({ error: "..." }, 400)`              |

### Critical: Fastify Auto-Return vs. Hono Explicit Return

In Fastify, returning a plain object from a handler auto-serializes it to JSON.
In Hono, you MUST use `c.json(...)`. Every route handler that does
`return { ... }` must become `return c.json({ ... })`.

---

## 7. Error Handling Pattern

### Error Classes (Identical)

The `ApiError` class and factory functions (`badRequest`, `unauthorized`,
`notFound`, `conflict`) are already ported in `_shared/errors.ts`. The API is
identical:

```typescript
throw unauthorized();
throw notFound("Album");
throw conflict("EMAIL_ALREADY_IN_USE", "Email is already registered");
throw badRequest("MISSING_PARAMS", "provider and provider_id are required");
```

### Global Error Handler

**Fastify** (server.ts lines 187-206): `app.setErrorHandler(...)`
**Hono** (already in `_shared/errors.ts`): `app.onError((err, c) => handleError(err, c))`

The `handleError` function in `_shared/errors.ts` already produces the same
`{ error: { code, message, requestId } }` envelope.

---

## 8. Auth Middleware Pattern

### Fastify Pattern

Auth is a decorated function called explicitly in each handler:

```typescript
// server.ts line 75
app.decorate("requireAuth", (request) => resolveUserIdFromRequest(request, db));

// In route handlers:
const userId = await app.requireAuth(request);
```

### Hono Pattern (Already Implemented in `_shared/auth.ts`)

Auth is a Hono middleware that sets `c.set("userId", ...)`:

```typescript
// Apply to all protected routes:
app.use("/v1/*", requireAuth);

// Or selectively:
auth.post("/v1/auth/signup", async (c) => { ... }); // No auth
auth.get("/v1/me", requireAuth, async (c) => { ... }); // With auth

// In route handlers:
const userId = c.get("userId");
```

### Routes That Do NOT Require Auth

These routes must NOT have the `requireAuth` middleware:
- `POST /v1/auth/signup` (auth.ts)
- `POST /v1/auth/login` (auth.ts)
- `POST /v1/auth/refresh` (auth.ts)
- `GET /v1/search` (catalog.ts)
- `GET /v1/albums/:id` (catalog.ts)
- `GET /v1/lists/:id` (lists.ts)
- `GET /health` (server.ts)
- `GET /v1/mappings/lookup` (mapping.ts)
- `POST /v1/mappings/resolve` (mapping.ts)

---

## 9. Complete Endpoint Inventory

### Module: auth (backend/src/modules/auth.ts)

| Method | Path              | Auth | Rate Limit Tier           | Key SQL Queries                                                                                          |
| ------ | ----------------- | ---- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| POST   | /v1/auth/signup   | No   | 10/min (AUTH_ROUTES)      | `SELECT id FROM users WHERE email = $1`; `INSERT INTO users(...)` ; `INSERT INTO sessions(...)` ; `INSERT INTO notification_preferences(...)` |
| POST   | /v1/auth/login    | No   | 10/min (AUTH_ROUTES)      | `SELECT id, password_hash, handle FROM users WHERE email = $1`; `UPDATE users SET refresh_token...`; `INSERT INTO sessions(...)` ; `DELETE FROM sessions WHERE user_id = $1 AND expires_at < NOW()` |
| POST   | /v1/auth/refresh  | No   | 10/min (AUTH_ROUTES)      | `SELECT id, handle FROM users WHERE refresh_token = $1`; `UPDATE users SET refresh_token...`; `INSERT INTO sessions(...)` ; `DELETE FROM sessions WHERE ...` |
| GET    | /v1/me            | Yes  | Global 100/min            | `SELECT id, handle, bio, log_count, review_count, list_count, avg_rating FROM users WHERE id = $1` |

**Redis ops**: `cacheGet("profile:$userId")`, `cacheSet("profile:$userId", profile, 90)`
**Audit**: `user.signup`, `user.login`
**External deps**: `bcryptjs` (hash, compare)

### Module: catalog (backend/src/modules/catalog.ts)

| Method | Path                    | Auth | Rate Limit Tier      | Key SQL Queries                                                                                    |
| ------ | ----------------------- | ---- | -------------------- | -------------------------------------------------------------------------------------------------- |
| GET    | /v1/search              | No   | Global 100/min       | FTS: `SELECT ... FROM albums WHERE (search_vector @@ plainto_tsquery('english', $1) OR LOWER(title) LIKE ...)` |
| POST   | /v1/albums/from-spotify | No   | 30/min (write)       | `INSERT INTO albums (...) ON CONFLICT (spotify_id) DO UPDATE ...`; `INSERT INTO album_genres ...`  |
| GET    | /v1/albums/:id          | No   | Global 100/min       | `SELECT id, title, artist, year, artwork_url, avg_rating, log_count FROM albums WHERE id = $1`     |

**Redis ops**: `cacheGet("spotify_search:$query")`, `cacheSet("spotify_search:$query", results, 300)`
**External deps**: Spotify Search API (client credentials), MusicBrainz API
**Pagination**: cursor-based on `log_count`

### Module: opinions (backend/src/modules/opinions.ts)

| Method | Path                       | Auth | Rate Limit Tier | Key SQL Queries                                                                         |
| ------ | -------------------------- | ---- | --------------- | --------------------------------------------------------------------------------------- |
| GET    | /v1/log/recently-played    | Yes  | Global 100/min  | `SELECT ... FROM listening_events WHERE user_id = $1 ORDER BY played_at DESC`           |
| POST   | /v1/ratings                | Yes  | 30/min (write)  | `INSERT INTO ratings (...) ON CONFLICT (user_id, album_id) DO UPDATE ...`; `INSERT INTO listening_events(...)`; `INSERT INTO activity_events(...)`; `UPDATE users SET log_count = ..., avg_rating = ...`; `UPDATE albums SET avg_rating = ..., log_count = ...` |
| POST   | /v1/reviews                | Yes  | 30/min (write)  | `INSERT INTO reviews(...)`; `INSERT INTO activity_events(...)`; `UPDATE users SET review_count = ...` |
| PUT    | /v1/reviews/:id            | Yes  | 30/min (write)  | `SELECT ... FROM reviews WHERE id = $1`; `UPDATE reviews SET body = $2, revision = revision + 1 ...` |

**Redis ops**: `cacheDel("profile:$userId")`, feed cache invalidation
**Idempotency**: All POST/PUT routes wrapped in `withIdempotency`
**Notifications**: `queueFollowerNotifications` for SOCIAL_RATING, SOCIAL_REVIEW
**Audit**: `rating.create`, `review.create`, `review.update`

### Module: social (backend/src/modules/social.ts)

| Method | Path                      | Auth | Rate Limit Tier | Key SQL Queries                                                                           |
| ------ | ------------------------- | ---- | --------------- | ----------------------------------------------------------------------------------------- |
| POST   | /v1/follow/:userId        | Yes  | 30/min (write)  | `SELECT id FROM users WHERE id = $1`; `INSERT INTO follows(...) ON CONFLICT DO NOTHING`   |
| DELETE | /v1/follow/:userId        | Yes  | 30/min (write)  | `DELETE FROM follows WHERE follower_id = $1 AND followee_id = $2`                         |
| GET    | /v1/feed                  | Yes  | Global 100/min  | `SELECT followee_id FROM follows WHERE follower_id = $1`; `SELECT ... FROM activity_events WHERE actor_id = ANY($1::text[]) ORDER BY created_at DESC` |
| POST   | /v1/activity/:id/react    | Yes  | 30/min (write)  | `UPDATE activity_events SET reactions = reactions + 1 WHERE id = $1 RETURNING ...`; `SELECT reaction_enabled FROM notification_preferences ...` |
| POST   | /v1/activity/:id/comment  | Yes  | 30/min (write)  | `UPDATE activity_events SET comments = comments + 1 WHERE id = $1 RETURNING ...`; `SELECT comment_enabled FROM notification_preferences ...` |

**Redis ops**: `cacheGet("feed:$actorId:page1")`, `cacheSet(...)`, `cacheDel(...)`
**Feed cache TTL**: 90 seconds
**Idempotency**: All POST/DELETE routes wrapped in `withIdempotency`
**Notifications**: `queueNotification` for REACTION, COMMENT

### Module: lists (backend/src/modules/lists.ts)

| Method | Path                 | Auth    | Rate Limit Tier | Key SQL Queries                                                                                          |
| ------ | -------------------- | ------- | --------------- | -------------------------------------------------------------------------------------------------------- |
| POST   | /v1/lists            | Yes     | 30/min (write)  | `INSERT INTO lists(...)`; `UPDATE users SET list_count = ...`; `INSERT INTO activity_events(...)`         |
| POST   | /v1/lists/:id/items  | Yes     | 30/min (write)  | `SELECT id, owner_id FROM lists WHERE id = $1`; `SELECT id FROM albums WHERE id = $1`; `SELECT COALESCE(MAX(position), 0) + 1 ...`; `INSERT INTO list_items(...)`; `UPDATE lists SET updated_at = NOW()`; `INSERT INTO activity_events(...)` |
| GET    | /v1/lists/:id        | No      | Global 100/min  | `SELECT ... FROM lists WHERE id = $1`; `SELECT album_id, position, note FROM list_items WHERE list_id = $1 ORDER BY position ASC` |

**Redis ops**: `cacheDel("profile:$userId")`, feed cache invalidation
**Idempotency**: POST routes wrapped in `withIdempotency`
**Notifications**: `queueFollowerNotifications` for SOCIAL_LIST
**Audit**: `list.create`

### Module: trust (backend/src/modules/trust.ts)

| Method | Path              | Auth | Rate Limit Tier           | Key SQL Queries                                                                                          |
| ------ | ----------------- | ---- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| POST   | /v1/account/export | Yes | 3/hour (SENSITIVE_ROUTES) | Reads from: `users`, `ratings`, `reviews`, `lists`, `list_items`, `follows`, `listening_events`, `activity_events` |
| DELETE | /v1/account       | Yes  | 3/hour (SENSITIVE_ROUTES) | `DELETE FROM users WHERE id = $1`                                                                         |

**Redis ops**: `cacheDel("profile:$userId", "feed:$userId:page1")`
**Audit**: `account.export`, `account.delete`

### Module: recaps (backend/src/modules/recaps.ts)

| Method | Path                          | Auth | Rate Limit Tier | Key SQL Queries                                                                                          |
| ------ | ----------------------------- | ---- | --------------- | -------------------------------------------------------------------------------------------------------- |
| GET    | /v1/recaps/weekly/latest      | Yes  | Global 100/min  | `SELECT payload FROM recap_snapshots WHERE user_id = $1 ORDER BY week_end DESC LIMIT 1`; `INSERT INTO analytics_events(...)` |
| POST   | /v1/recaps/weekly/generate    | Yes  | 30/min (write)  | `SELECT COUNT(*)::int FROM listening_events WHERE user_id = $1 AND played_at >= $2`; `SELECT album_id, value FROM ratings WHERE user_id = $1 AND updated_at >= $2 ORDER BY value DESC LIMIT 6`; `SELECT COALESCE(AVG(value), 0)::real FROM ratings ...`; `INSERT INTO recap_snapshots(...) ON CONFLICT(user_id, week_start, week_end) DO UPDATE ...`; `INSERT INTO analytics_events(...)` |

**Idempotency**: POST wrapped in `withIdempotency`
**Notifications**: `queueNotification` for RECAP_READY

### Module: push (backend/src/modules/push.ts)

| Method | Path                            | Auth | Rate Limit Tier | Key SQL Queries                                                                       |
| ------ | ------------------------------- | ---- | --------------- | ------------------------------------------------------------------------------------- |
| POST   | /v1/push/tokens                 | Yes  | 30/min (write)  | `INSERT INTO device_tokens(...) ON CONFLICT(device_token) DO UPDATE ...`; `SELECT ... FROM device_tokens WHERE device_token = $1` |
| DELETE | /v1/push/tokens/:deviceToken    | Yes  | 30/min (write)  | `DELETE FROM device_tokens WHERE user_id = $1 AND device_token = $2`                  |
| GET    | /v1/push/preferences            | Yes  | Global 100/min  | `SELECT ... FROM notification_preferences WHERE user_id = $1`; (upsert if missing)    |
| PUT    | /v1/push/preferences            | Yes  | 30/min (write)  | `INSERT INTO notification_preferences(...) ON CONFLICT(user_id) DO UPDATE SET ...`     |
| GET    | /v1/notifications               | Yes  | Global 100/min  | `SELECT ... FROM notification_events WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50` |
| POST   | /v1/notifications/test-recap    | Yes  | 30/min (write)  | `INSERT INTO analytics_events(...)`                                                    |

**Idempotency**: POST/PUT/DELETE wrapped in `withIdempotency`

### Module: providers (backend/src/modules/providers.ts)

| Method | Path                                  | Auth | Rate Limit Tier            | Key SQL Queries                                                                          |
| ------ | ------------------------------------- | ---- | -------------------------- | ---------------------------------------------------------------------------------------- |
| POST   | /v1/providers/:provider/connect       | Yes  | 10/min (PROVIDER_PREFIX)   | `SELECT id, connected_at FROM provider_connections WHERE user_id = $1 AND provider = $2 AND disconnected_at IS NULL`; `INSERT INTO oauth_states(...)` |
| POST   | /v1/providers/:provider/callback      | Yes  | 10/min (PROVIDER_PREFIX)   | `SELECT ... FROM oauth_states WHERE state = $1`; `DELETE FROM oauth_states WHERE state = $1`; `INSERT INTO provider_connections(...) ON CONFLICT(user_id, provider) DO UPDATE ...` |
| GET    | /v1/providers/:provider/status        | Yes  | 10/min (PROVIDER_PREFIX)   | `SELECT id, provider, connected_at, scopes FROM provider_connections WHERE ...`           |
| POST   | /v1/providers/:provider/disconnect    | Yes  | 10/min (PROVIDER_PREFIX)   | `SELECT id, access_token FROM provider_connections WHERE ...`; `UPDATE provider_connections SET disconnected_at = NOW() WHERE id = $1`; optional: `DELETE FROM listening_events/sync_cursors/sync_jobs WHERE ...` |

**External deps**: Provider OAuth adapter (Spotify: token exchange, refresh, revoke)

### Module: import (backend/src/modules/import.ts)

| Method | Path                     | Auth | Rate Limit Tier | Key SQL Queries                                                                                    |
| ------ | ------------------------ | ---- | --------------- | -------------------------------------------------------------------------------------------------- |
| POST   | /v1/sync/start           | Yes  | 30/min (write)  | `SELECT id FROM sync_jobs WHERE user_id = $1 AND provider = $2 AND status IN ('queued', 'running')`; `INSERT INTO sync_jobs (...)`; (background: `UPDATE sync_jobs ...`; `SELECT cursor_value FROM sync_cursors ...`; `INSERT INTO listening_events (...)`) |
| GET    | /v1/sync/status/:sync_id | Yes  | Global 100/min  | `SELECT * FROM sync_jobs WHERE id = $1 AND user_id = $2`                                          |
| POST   | /v1/sync/cancel          | Yes  | 30/min (write)  | `SELECT id, status FROM sync_jobs WHERE id = $1 AND user_id = $2`; `UPDATE sync_jobs SET status = 'cancelled' ...` |

**Background processing**: `processSync()` runs fire-and-forget. In Edge Functions,
this may need to be converted to a separate invocation or use `EdgeRuntime.waitUntil()`.

### Module: mapping (backend/src/modules/mapping.ts)

| Method | Path                   | Auth | Rate Limit Tier | Key SQL Queries                                                                                          |
| ------ | ---------------------- | ---- | --------------- | -------------------------------------------------------------------------------------------------------- |
| GET    | /v1/mappings/lookup    | No   | Global 100/min  | `SELECT ... FROM provider_mappings WHERE provider = $1 AND provider_id = $2`; `SELECT ... FROM provider_mappings WHERE canonical_id = $1`; `SELECT ... FROM canonical_albums ...`; `SELECT name FROM canonical_artists ...` |
| POST   | /v1/mappings/resolve   | No   | 30/min (write)  | (calls `resolveMapping()` which queries: `provider_mappings`, `canonical_albums JOIN canonical_artists`, `INSERT INTO canonical_artists/canonical_albums/provider_mappings/albums`) |

### Health Check (server.ts)

| Method | Path    | Auth | Rate Limit Tier | Key Checks                           |
| ------ | ------- | ---- | --------------- | ------------------------------------ |
| GET    | /health | No   | Global 100/min  | `SELECT 1` (postgres); Redis status  |

**Total**: 32 endpoints across 11 modules + health check.

---

## 10. Shared Utility Mappings

### `_shared/util.ts` (from backend/src/lib/util.ts)

```typescript
// Deno: crypto is global, no import needed
export const nowIso = () => new Date().toISOString();
export const uid = (prefix: string) =>
  `${prefix}_${crypto.randomUUID().replace(/-/g, "")}`;
```

### `_shared/sanitize.ts` (from backend/src/lib/sanitize.ts)

No changes needed -- pure string manipulation, no Node.js APIs:

```typescript
export const stripHtml = (text: string): string =>
  text.replace(/<[^>]*>/g, "").replace(/</g, "&lt;").replace(/>/g, "&gt;").trim();
```

### `_shared/normalize.ts` (from backend/src/lib/normalize.ts)

No changes needed -- pure string manipulation:

```typescript
export const normalizeText = (text: string): string =>
  text.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9\s]/g, "").replace(/\s+/g, " ").trim();
```

### `_shared/pagination.ts` (from backend/src/lib/pagination.ts)

Change: Remove `FastifyRequest` dependency. Accept raw query params instead:

```typescript
// Fastify version depends on FastifyRequest type
// Hono version:
export const parsePaginationParams = (c: Context): PaginationParams => {
  const rawLimit = Number(c.req.query("limit"));
  const limit = Number.isFinite(rawLimit) && rawLimit > 0
    ? Math.min(rawLimit, MAX_LIMIT) : DEFAULT_LIMIT;
  const raw = c.req.query("cursor")?.trim() || null;
  const cursor = raw && raw.length <= MAX_CURSOR_LENGTH ? raw : null;
  return { cursor, limit };
};
```

`buildPaginatedResponse` needs no changes -- it's a pure function.

### `_shared/idempotency.ts` (from backend/src/lib/idempotency.ts)

Change: Replace `FastifyRequest` with Hono `Context`. Replace `db.query` with
`query` import. Replace `request.headers["idempotency-key"]` with
`c.req.header("Idempotency-Key")`. Replace `request.method`/`request.url` with
`c.req.method`/`c.req.path`.

### `_shared/notifications.ts` (from backend/src/lib/notifications.ts)

Change: Replace `createHash("sha256")` with `crypto.subtle.digest("SHA-256", ...)`.
The `toDedupeKey` function becomes async. Replace `db.query` calls with `query`
import. Replace `db.redis.del` with `cacheDel`.

### `_shared/audit.ts` (from backend/src/lib/audit.ts)

Change: Replace `db.query` with `query` import. No other changes.

### `_shared/dead-letter.ts` (from backend/src/lib/dead-letter.ts)

Change: Replace `db.query` with `query` import. No other changes.

### `_shared/retry.ts` (from backend/src/lib/retry.ts)

No changes needed -- pure async/await logic, no Node.js APIs.

### `_shared/mappers.ts` (from backend/src/lib/mappers.ts)

Change: Replace `import type { UserProfile } from "@soundscore/contracts"` with
inline type or import from local contracts copy. Replace `import type { UserProfileRow }`
with inline type. Otherwise identical.

### `_shared/spotify-catalog.ts` (from backend/src/lib/spotify-catalog.ts)

Changes:
- Remove `import { env } from "../config/env"` -- use `Deno.env.get()`
- Replace `Buffer.from(...).toString("base64")` with `btoa(...)`
- `fetch` is global in Deno (already global in Node 18+, no change needed)
- Replace `db.query` calls in `upsertAlbumFromSpotify` with `query` import

### `_shared/spotify-adapter.ts` (from backend/src/lib/spotify-adapter.ts)

Changes:
- Remove `import { env } from "../config/env"` -- use `Deno.env.get()`
- Replace `Buffer.from(...).toString("base64")` with `btoa(...)`
- `fetch` is global in both environments

### `_shared/token-refresh.ts` (from backend/src/lib/token-refresh.ts)

Change: Replace `db.query` with `query` import. Otherwise identical.

### `_shared/provider-adapter.ts` (from backend/src/lib/provider-adapter.ts)

No changes needed -- pure TypeScript interfaces.

### `_shared/provider-registry.ts` (from backend/src/lib/provider-registry.ts)

No changes needed beyond import path adjustments.

---

## 11. Zod Schema Re-use Strategy

The `packages/contracts/src/` package contains all Zod schemas used for request
validation and response typing. These schemas are **pure Zod** with no
Node.js-specific dependencies.

**Strategy**: Copy the contracts source files into
`supabase/functions/api/_shared/contracts/` and import from there. This avoids
needing a monorepo build step in the Edge Function deploy.

Files to copy:
- `common.ts` -- `CursorPageSchema`, `ErrorEnvelopeSchema`, `IdempotencyKeyHeaderSchema`
- `models.ts` -- All model schemas (Album, Rating, Review, etc.)
- `endpoints.ts` -- All request validation schemas
- `events.ts` -- `ActivityEventSchema`, `ListeningEventSchema`
- `provider.ts` -- Provider connection schemas
- `mapping.ts` -- Mapping schemas
- `sync.ts` -- Sync job schemas
- `compliance.ts` -- Attribution/compliance schemas

Change `import { z } from "zod"` to `import { z } from "npm:zod"` in each file
(or use an import map).

---

## Appendix A: Rate Limit Tier Summary

| Tier              | Max Requests | Time Window | Applied To                                                         |
| ----------------- | ------------ | ----------- | ------------------------------------------------------------------ |
| Global default    | 100          | 1 minute    | All routes (base)                                                  |
| AUTH_ROUTES       | 10           | 1 minute    | `/v1/auth/signup`, `/v1/auth/login`, `/v1/auth/refresh`            |
| SENSITIVE_ROUTES  | 3            | 1 hour      | `/v1/account/export`, `/v1/account` (DELETE)                       |
| PROVIDER_PREFIX   | 10           | 1 minute    | `/v1/providers/*`                                                  |
| Write operations  | 30           | 1 minute    | All non-GET/HEAD methods not in other tiers                        |

## Appendix B: Tables Touched per Module

| Module    | Tables Read                                                                                    | Tables Written                                                                     |
| --------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| auth      | users, sessions                                                                                | users, sessions, notification_preferences, audit_events                            |
| catalog   | albums, album_genres                                                                           | albums, album_genres                                                               |
| opinions  | albums, ratings, listening_events, activity_events, users, follows, notification_preferences   | ratings, listening_events, activity_events, users, albums, notification_events, idempotency_keys, audit_events |
| social    | users, follows, activity_events, notification_preferences                                      | follows, activity_events, notification_events, idempotency_keys                    |
| lists     | lists, list_items, albums, users, follows                                                      | lists, list_items, activity_events, users, notification_events, idempotency_keys, audit_events |
| trust     | users, ratings, reviews, lists, list_items, follows, listening_events, activity_events          | users, audit_events                                                                |
| recaps    | listening_events, ratings, recap_snapshots, notification_preferences                           | recap_snapshots, analytics_events, notification_events, idempotency_keys           |
| push      | device_tokens, notification_preferences, notification_events, analytics_events                 | device_tokens, notification_preferences, notification_events, analytics_events, idempotency_keys |
| providers | provider_connections, oauth_states, listening_events, sync_cursors, sync_jobs                   | provider_connections, oauth_states, listening_events, sync_cursors, sync_jobs       |
| import    | sync_jobs, sync_cursors, listening_events, canonical_albums, canonical_artists, provider_mappings, albums | sync_jobs, sync_cursors, listening_events, canonical_albums, canonical_artists, provider_mappings, albums |
| mapping   | provider_mappings, canonical_albums, canonical_artists, albums                                  | canonical_albums, canonical_artists, provider_mappings, albums                     |

---

## Appendix C: Integration Audit — Issues Found & Fixed (2026-03-19)

Full end-to-end audit of all 21 files in `supabase/functions/api/`. Each issue
was fixed directly in the source file.

### Issue 1: `catalog.ts` — Wrong generic type for Spotify search cache

**File**: `routes/catalog.ts` line 125
**Severity**: Type error (would produce `Promise<SpotifyAlbumData[]>` as the cache type instead of `SpotifyAlbumData[]`)
**Before**: `cacheGet<ReturnType<typeof searchSpotify>>(cacheKey)`
**After**: `cacheGet<SpotifyAlbumData[]>(cacheKey)`
**Fix**: Added `import type { SpotifyAlbumData }` and used the concrete array type.

### Issue 2: `lists.ts` + `trust.ts` — `c.json(null, 204)` sends body for 204 No Content

**Files**: `routes/lists.ts` line 443, `routes/trust.ts` line 260
**Severity**: Protocol violation (HTTP 204 must have no body; `c.json(null)` sends `"null"`)
**Before**: `return c.json(null, 204);`
**After**: `return c.body(null, 204);`

### Issue 3: `social.ts` — Unused `actorId` variable in react/comment handlers

**File**: `routes/social.ts` lines 159, 192
**Severity**: Warning / dead code
**Before**: `const actorId = c.get("userId");` (unused)
**After**: `const _actorId = c.get("userId");` (underscore-prefixed to suppress lint)

### Issue 4: `auth.ts` — Deno bcrypt `hash()` requires string salt, not number

**File**: `routes/auth.ts` line 165
**Severity**: Runtime error (Deno bcrypt `hash(plaintext, salt)` expects a salt string; passing a number for salt rounds is a Node bcryptjs pattern that does not work in the Deno module)
**Before**: `const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);`
**After**: `const salt = await bcrypt.genSalt(SALT_ROUNDS); const passwordHash = await bcrypt.hash(password, salt);`

### Issue 5: `auth.ts` — Signup validation used 401 instead of 400

**File**: `routes/auth.ts` line 147
**Severity**: Incorrect HTTP status (missing fields should be 400 Bad Request, not 401 Unauthorized)
**Before**: `throw unauthorized("Missing required fields");`
**After**: `throw badRequest("MISSING_FIELDS", "email, password, and handle are required");`
**Fix**: Added `badRequest` to imports.

### Issue 6: `lists.ts` — Wrong audit event type for DELETE

**File**: `routes/lists.ts` line 435
**Severity**: Incorrect audit trail (logged `"list.create"` when deleting a list)
**Before**: `logAuditEvent(userId, "list.create", { listId, action: "delete" }, ...)`
**After**: `logAuditEvent(userId, "list.delete", { listId }, ...)`

### Issue 7: `providers.ts` — Missing `::text[]` cast for `scopes` array parameter

**File**: `routes/providers.ts` line 177
**Severity**: Potential runtime error (deno-postgres may not auto-cast JS arrays to PostgreSQL `text[]`)
**Before**: `VALUES($1, $2, $3, $4, $5, $6, $7, NOW(), NULL)` / `scopes = $7`
**After**: `VALUES($1, $2, $3, $4, $5, $6, $7::text[], NOW(), NULL)` / `scopes = $7::text[]`

### Issue 8: `spotify-catalog.ts` — Missing `::text[]` cast for `genres` array parameter

**File**: `_shared/spotify-catalog.ts` line 153
**Severity**: Potential runtime error (same array-cast issue as Issue 7)
**Before**: `VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, ...)`
**After**: `VALUES ($1, $2, $3, $4, $5, $6, $7::text[], $8, $9, $10, ...)`

### Issue 9: `errors.ts` — Status code type union missing 422 and 429

**File**: `_shared/errors.ts` line 56
**Severity**: TypeScript type narrowing (Hono type hints for status codes)
**Before**: `err.statusCode as 400 | 401 | 404 | 409 | 500`
**After**: `err.statusCode as 400 | 401 | 404 | 409 | 422 | 429 | 500`

### Verified OK — No Issues

The following were verified and found to be correct:

- **All 37 route paths** match client expectations (`POST /api/v1/auth/signup` through `GET /api/health`)
- **All `.ts` file extensions** present in relative imports (Deno requirement)
- **No `process.env`** usage (all use `Deno.env.get()`)
- **No `require()`** calls (all ESM imports)
- **No `Buffer`** usage (all use `btoa()` / `atob()`)
- **All deno.land/x imports** are version-pinned (`postgres@v0.19.3`, `upstash_redis@v1.34.3`, `bcrypt@v0.4.1`)
- **All 11 route exports** match expected names (`authRoutes`, `catalogRoutes`, `opinionRoutes`, `socialRoutes`, `listRoutes`, `trustRoutes`, `recapRoutes`, `pushRoutes`, `providerRoutes`, `mappingRoutes`, `importRoutes`)
- **SQL parameterization** uses `$1`, `$2` syntax consistently (compatible with deno-postgres)
- **Auth middleware** correctly applied: public routes (signup, login, refresh, search, album detail, single list, mappings, health) have no `requireAuth`; all other routes are protected
- **Pagination** uses cursor-based pattern with `limit + 1` fetch and `buildPaginatedResponse` trim
- **Error handling** uses `ApiError` + factory functions consistently; global `app.onError` handler catches all thrown errors

### Known Limitations (Not Fixed — Architectural)

1. **`import.ts` fire-and-forget sync**: `processSync(jobId)` runs without `await`, so the Edge Function may terminate before sync completes. Needs `EdgeRuntime.waitUntil()` or a separate Edge Function invocation.
2. **JSR Hono version unpinned**: `jsr:@hono/hono` imports resolve to latest; the Supabase lock file should pin versions in practice.
3. **Deno bcrypt web worker**: The async `hash`/`compare` functions use web workers internally. Supabase Edge Functions on Deno 2.x support workers, but this should be monitored for compatibility.
