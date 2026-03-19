# SoundScore Edge Function API -- Security Review

**Reviewed**: 2026-03-19
**Scope**: `supabase/functions/api/` (all `_shared/` and `routes/` files)
**Runtime**: Deno (Supabase Edge Functions) + Hono framework

---

## Executive Summary

The Edge Function API is **well-architected** for a production mobile backend. All SQL
queries use parameterized statements, authentication middleware is consistently applied
to mutation routes, rate limiting covers write and sensitive paths, and error responses
do not leak internal details. The codebase follows defense-in-depth principles with
audit logging, HTML sanitization, and idempotency support.

Several **medium-severity** items and a few **low-severity** observations are noted
below. No critical vulnerabilities were found.

---

## 1. SQL Injection

**Verdict: PASS**

Every SQL query across all files uses parameterized placeholders (`$1`, `$2`, ...).
The `query()` helper in `_shared/db.ts` enforces this pattern by accepting a `params`
array and delegating to `client.queryObject({ text, args })`.

Files verified:
- `_shared/db.ts` -- query helper only accepts parameterized calls
- `routes/auth.ts` -- all INSERT/SELECT/UPDATE/DELETE parameterized
- `routes/catalog.ts` -- dynamic cursor/limit positions built via `$N` index math, not string interpolation
- `routes/opinions.ts` -- all parameterized including dynamic WHERE clause construction
- `routes/social.ts` -- uses `ANY($1::text[])` for array parameters (safe)
- `routes/lists.ts` -- all parameterized
- `routes/trust.ts` -- all parameterized
- `routes/recaps.ts` -- all parameterized
- `routes/push.ts` -- all parameterized
- `routes/providers.ts` -- all parameterized
- `routes/mapping.ts` -- all parameterized
- `routes/import.ts` -- all parameterized
- `_shared/spotify-catalog.ts` -- all parameterized
- `_shared/musicbrainz-catalog.ts` -- all parameterized

No string interpolation is used in any SQL statement.

---

## 2. Authentication Bypass

**Verdict: PASS**

The `requireAuth` middleware (`_shared/auth.ts`) validates Bearer tokens against the
`sessions` table with expiry check (`expires_at > NOW()`). It is applied to all
mutation and user-scoped routes:

| Route Module    | Auth Method                                     |
|-----------------|------------------------------------------------|
| opinions        | `router.use("/*", requireAuth)` -- blanket     |
| social          | `router.use("/*", requireAuth)` -- blanket     |
| push            | `router.use("/*", requireAuth)` -- blanket     |
| providers       | `router.use("/*", requireAuth)` -- blanket     |
| import          | `router.use("/*", requireAuth)` -- blanket     |
| recaps          | Per-route `requireAuth` on all GET endpoints   |
| trust           | Per-route `requireAuth` on export and delete   |
| lists           | Per-route `requireAuth` on POST/GET/DELETE      |
| auth            | `requireAuth` on GET `/me` only (correct)       |
| catalog         | No auth required (public search/read -- correct)|
| mapping         | **No auth on GET or POST** -- see finding M-01  |

### Finding M-01 (MEDIUM): Mapping routes lack authentication

`routes/mapping.ts` does not apply `requireAuth` to either `GET /mappings/lookup` or
`POST /mappings/resolve`. The resolve endpoint creates new canonical albums and
provider mappings, which could be abused to pollute the catalog without authentication.

**Recommendation**: Add `requireAuth` middleware to `POST /mappings/resolve`. The
`GET /mappings/lookup` can remain public if desired for client pre-checks.

### Finding L-01 (LOW): `GET /lists/:listId` does not require auth

`routes/lists.ts` line 302 -- the single-list detail endpoint is public. This may be
intentional (shareable lists), but should be confirmed. If lists are meant to be
private, add `requireAuth`.

---

## 3. Rate Limiting

**Verdict: PASS (with gaps)**

Rate limiting is implemented via Upstash Redis (`_shared/rate-limit.ts`) using an
atomic INCR + EXPIRE pattern. Pre-defined tiers exist:

| Tier           | Max  | Window | Applied To                        |
|----------------|------|--------|-----------------------------------|
| GLOBAL_LIMIT   | 100  | 60s    | All routes (global middleware)     |
| AUTH_LIMIT      | 10   | 60s    | **Not applied** -- see finding M-02|
| WRITE_LIMIT     | 30   | 60s    | lists POST, lists items, lists DELETE |
| SENSITIVE_LIMIT | 3    | 3600s  | account/export, account delete    |
| PROVIDER_LIMIT  | 10   | 60s    | **Not applied** -- see finding M-02|

### Finding M-02 (MEDIUM): AUTH_LIMIT and PROVIDER_LIMIT defined but not applied

`AUTH_LIMIT` (10 req/min) is defined in `_shared/rate-limit.ts` but never imported or
applied to `/auth/signup`, `/auth/login`, or `/auth/refresh`. These endpoints rely
only on the global 100 req/min limit, making brute-force attacks against login more
feasible.

Similarly, `PROVIDER_LIMIT` is defined but never applied to the provider routes.

**Recommendation**: Apply rate limiters to auth and provider routes:
```ts
// In routes/auth.ts
import { rateLimiter, AUTH_LIMIT } from "../_shared/rate-limit.ts";
authRoutes.post("/auth/signup", rateLimiter(AUTH_LIMIT), async (c) => { ... });
authRoutes.post("/auth/login", rateLimiter(AUTH_LIMIT), async (c) => { ... });
authRoutes.post("/auth/refresh", rateLimiter(AUTH_LIMIT), async (c) => { ... });
```

### Finding L-02 (LOW): Opinion write routes have no WRITE_LIMIT

`routes/opinions.ts` applies `requireAuth` globally but does not apply `WRITE_LIMIT`
to POST `/ratings`, POST `/track-ratings`, POST `/reviews`, or PUT `/reviews/:id`.
These rely solely on the global 100 req/min limit.

**Recommendation**: Add `rateLimiter(WRITE_LIMIT)` to opinion write endpoints.

---

## 4. Input Validation

**Verdict: PASS (with observations)**

Request bodies are validated for required fields before processing. Examples:
- Signup validates email, password, handle presence
- Ratings validate albumId presence and value range (0-6)
- Reviews validate albumId and body presence
- List creation validates title presence
- Push token registration validates platform against allowlist
- Provider routes validate provider against `SUPPORTED_PROVIDERS` set

### Finding M-03 (MEDIUM): No password strength validation on signup

`routes/auth.ts` line 146 checks that password is not empty but does not enforce
minimum length or complexity. A single-character password would be accepted.

**Recommendation**: Add minimum password length (8+ characters) and consider basic
complexity requirements.

### Finding L-03 (LOW): No email format validation

Email is trimmed and lowercased but not validated as a proper email format. Malformed
emails would be stored in the database.

**Recommendation**: Add a basic email regex or use a validation library.

### Finding L-04 (LOW): Review body length is not bounded

`POST /reviews` and `PUT /reviews/:id` sanitize HTML via `stripHtml()` but do not
enforce a maximum length. A malicious client could submit extremely large review
bodies.

**Recommendation**: Add a max length check (e.g., 10,000 characters) before insertion.

---

## 5. Error Leakage

**Verdict: PASS**

The global error handler (`_shared/errors.ts`) correctly separates known `ApiError`
instances (which return structured error codes and user-facing messages) from
unexpected errors (which log to stderr but return a generic "Unexpected server error"
message with no stack trace or internal details).

One observation:

### Finding L-05 (LOW): Spotify adapter error messages include raw response text

In `_shared/spotify-adapter.ts`, error messages like
`Spotify token exchange failed (${response.status}): ${text}` include the raw Spotify
API error response. If these propagate as uncaught exceptions, the global handler will
catch them and return a generic 500. However, they will appear in server logs (via
`console.error`), which is acceptable. They should never reach clients, and the
current error handler ensures this.

---

## 6. Password Handling

**Verdict: PASS**

- bcrypt is used for hashing (`bcrypt.hash(password, SALT_ROUNDS)`)
- Salt rounds default to 10, configurable via `AUTH_SALT_ROUNDS` env var
- Password comparison uses `bcrypt.compare()` (timing-safe)
- Login returns the same error message for wrong email and wrong password
  ("Invalid credentials"), preventing user enumeration
- Passwords are never logged (the audit event scrubber explicitly filters
  "password" and "passwordHash" fields)

---

## 7. Token Security

**Verdict: PASS**

- Session tokens are generated using `crypto.randomUUID()` (CSPRNG) with a prefix
  (`atk_`, `rtk_`) for type identification
- Tokens are stored in the `sessions` table with `expires_at` set to 24 hours
- Token validation checks both existence and expiry (`expires_at > NOW()`)
- Refresh tokens are rotated on each use (old refresh token is replaced)
- Expired sessions are cleaned up on login and refresh
- OAuth state tokens use 32 bytes of `crypto.getRandomValues()` for CSRF protection
- OAuth states are single-use (deleted after consumption)
- OAuth states have server-side expiry checked before use

### Finding L-06 (LOW): Old sessions are not invalidated on new login

When a user logs in, a new session is created, but old non-expired sessions for that
user remain valid. This means a user cannot "log out everywhere" without a dedicated
endpoint.

**Recommendation**: Consider adding a `POST /auth/logout` endpoint that deletes the
current session, and a `POST /auth/logout-all` that deletes all sessions for the user.

---

## 8. CORS Configuration

**Verdict: PASS (for mobile)**

CORS is configured with `origin: "*"` which is appropriate for a mobile-only API where
requests come from native apps (not browsers). The configuration correctly:
- Allows necessary headers (Authorization, Content-Type, Idempotency-Key, X-Request-Id)
- Allows all REST methods
- Exposes rate-limit and request-id headers
- Sets `maxAge: 86400` for preflight caching

If a web frontend is added in the future, `origin` should be restricted to specific
domains.

---

## 9. Additional Findings

### Finding M-04 (MEDIUM): `POST /albums/from-spotify` lacks authentication

`routes/catalog.ts` line 196 -- the endpoint that persists Spotify albums into the
local catalog is unauthenticated. While it uses upsert (ON CONFLICT), an
unauthenticated caller could bulk-insert albums to pollute the catalog.

**Recommendation**: Add `requireAuth` to this endpoint.

### Finding L-07 (LOW): Audit event for list delete uses wrong event type

`routes/lists.ts` line 436 -- the audit event for list deletion uses type
`"list.create"` instead of `"list.delete"`.

### Finding L-08 (LOW): `credentials: true` in CORS with `origin: "*"`

Setting `credentials: true` with `origin: "*"` is technically a no-op in browsers
(browsers ignore credentials when origin is `*`). This is harmless but misleading.
Remove `credentials: true` or set explicit origins.

### Finding L-09 (LOW): No request body size limit

Hono does not enforce a request body size limit by default. A malicious client could
send extremely large JSON bodies to exhaust memory on the edge worker. Supabase Edge
Functions have a built-in body size limit (varies by plan), so this is partially
mitigated by the platform.

**Recommendation**: Add explicit body size validation for write endpoints.

---

## Summary Table

| ID   | Severity | Category          | Description                                      |
|------|----------|-------------------|--------------------------------------------------|
| M-01 | MEDIUM   | Auth              | Mapping routes lack authentication                |
| M-02 | MEDIUM   | Rate Limiting     | AUTH_LIMIT and PROVIDER_LIMIT not applied          |
| M-03 | MEDIUM   | Input Validation  | No password strength validation                    |
| M-04 | MEDIUM   | Auth              | POST /albums/from-spotify is unauthenticated       |
| L-01 | LOW      | Auth              | GET /lists/:listId is public (may be intentional)  |
| L-02 | LOW      | Rate Limiting     | Opinion write routes lack WRITE_LIMIT              |
| L-03 | LOW      | Input Validation  | No email format validation                         |
| L-04 | LOW      | Input Validation  | Review body length unbounded                       |
| L-05 | LOW      | Error Leakage     | Spotify error text in server logs (not client-facing)|
| L-06 | LOW      | Token Security    | No logout / session invalidation endpoint          |
| L-07 | LOW      | Code Quality      | Audit event type wrong for list delete             |
| L-08 | LOW      | CORS              | credentials: true with origin: * is misleading     |
| L-09 | LOW      | Input Validation  | No explicit request body size limit                |

**Critical**: 0 | **High**: 0 | **Medium**: 4 | **Low**: 9
