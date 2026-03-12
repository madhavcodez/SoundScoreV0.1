# Architecture and System

Use this when designing or implementing backend, APIs, or data flow. Source: architecture PDF §6–8.

---

## Architecture philosophy

- Ship V1 fast without painting into a corner.
- **Providers are adapters** — product survives API/policy shifts; SoundScore core data model is independent of any provider.
- **Modular monolith** with strict domain boundaries; add services only when thresholds force it.
- Mobile-first: backend exists to make the mobile experience instant (fast feeds, reliable imports, durable drafts, share cards).

---

## Domain module map (backend)

- Identity & Auth
- Catalog & Mapping
- Listening Import
- Ratings & Reviews
- Social Graph
- Activity Feed
- Lists
- Recaps & Share Cards
- Notifications
- Moderation & Safety
- **Trust Stack** (export, delete, disconnect)

---

## Data flow: import → log → social

1. **Fetch** provider listens (polling; webhook-like later if available).
2. **Normalize** into `listening_event` schema (append-only).
3. **Resolve** catalog mapping (provider IDs → SoundScore canonical album IDs).
4. **Deduplicate and compress** (e.g. avoid feed spam when user loops an album).
5. **Persist**; on user rate/review **emit activity** → feed and notifications.

---

## Provider adapter interface (from PDF)

Each external provider (Spotify, Apple Music, MusicBrainz) implements the same interface so multi-provider is incremental:

```
provider_name(): string
// Identity
exchange_oauth_code(code): TokenBundle
refresh_token(refresh_token): TokenBundle
revoke(token): void
// Listening
fetch_recent_plays(user_provider_identity, since_ts, limit): RawListen[]
// Catalog
lookup_album(provider_album_id): RawAlbum
search_album(query): RawAlbum[]
```

---

## Catalog and ID mapping (provider independence)

- **SoundScore owns canonical entities:** Artist, Album (release), Track (recording).
- **Mapping table:** canonical ID ↔ provider IDs, with confidence and provenance.

**V1 mapping algorithm:**
1. If provider includes a stable external ID already mapped → use it.
2. Else: deterministic match using normalized artist/title, release-year window (±1), track count.
3. If confidence ≥ threshold → create mapping; else mark pending, request user confirmation only when needed.

---

## Listening events (ground truth)

- **Schema:** append-only; what was played, when, from which source.
- Ratings and reviews attach to **albums** and can reference a listening event.
- **Dedup key:** `(user_id, album_id, floor(played_at to 10 minutes))`; store count to avoid feed flooding.

---

## Activity feed (ranking and scaling)

**V1:** Fan-out-on-read with strong cache.

- Query: activity from users I follow, ordered by `created_at` DESC, cursor pagination.
- **Cache** feed page 1 per user 30–120s in Redis.
- **Ranking (V1):** boost reviews over ratings, boost mutuals, downrank repetitive events.
- **When to change:** When graphs grow (e.g. median follows > ~200 or p95 breaks), move to fan-out-on-write with feed inbox tables.

---

## Lists and recaps

- **Lists:** First-class; fast creation, ordered items, notes, share card generation. Internal discovery (trending lists) and external acquisition (share cards).
- **Recaps:** Weekly job per-user aggregates (top albums, rating distribution, taste deltas, streaks). Store recap JSON; render share cards **server-side** for consistent visual identity; serve via CDN; open via universal/app links back into app.

---

## Trust stack

- **Export:** Snapshot bundle (ratings, reviews, lists, follows, listening history where allowed).
- **Deletion:** Background job that removes or anonymizes content per policy.
- **Provider disconnect:** Revoke tokens; cease processing that provider’s personal data.

---

## API design (implementation-ready)

**Conventions:**
- Cursor-based pagination for feeds and comments.
- **Idempotency keys** for all writes (critical for mobile retries/offline outbox).
- Consistent error envelope; typed error codes for client UX.
- Versioned endpoints: `/v1/...`

**Starter endpoint set (from PDF §8):**

| Area | Endpoints |
|------|-----------|
| Auth | `POST /v1/auth/signup`, `POST /v1/auth/login`, `POST /v1/auth/refresh` |
| Providers | `POST /v1/providers/:provider/connect`, `POST /v1/providers/:provider/disconnect` |
| Catalog | `GET /v1/search?q=...`, `GET /v1/albums/:id` |
| Log & opinions | `GET /v1/log/recently-played`, `POST /v1/ratings`, `POST /v1/reviews`, `PUT /v1/reviews/:id` |
| Social | `POST /v1/follow/:user_id`, `DELETE /v1/follow/:user_id`, `GET /v1/feed`, `POST /v1/activity/:id/react`, `POST /v1/activity/:id/comment` |
| Lists | `POST /v1/lists`, `POST /v1/lists/:id/items`, `GET /v1/lists/:id` |
| Recaps | `GET /v1/recaps/weekly/latest`, `GET /v1/share/profile/:handle` |
| Trust | `POST /v1/account/export`, `DELETE /v1/account` |

---

## Recommended stack (from PDF §9)

- **Backend:** TypeScript (Fastify/NestJS) or Go; modular monolith.
- **Data:** Postgres + Redis + OpenSearch/Meilisearch.
- **Queue:** SQS for V1.
- **Storage/CDN:** S3 + CloudFront (share cards, thumbnails).
- **Observability:** OpenTelemetry + Sentry/Crashlytics + dashboards (p95 latency, queue lag).
