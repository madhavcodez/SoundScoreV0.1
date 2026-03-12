# Data Models and Events

Use this when defining or changing API payloads, event schemas, or mapping from backend to app. Sources: architecture PDF §7, Appendix A; current `DummyData.kt`.

---

## Activity event (from PDF Appendix A)

Feed and notifications are driven by activity events. Schema:

```json
{
  "id": "01J...",
  "actor_id": "01J...",
  "type": "RATED_ALBUM" | "WROTE_REVIEW" | "CREATED_LIST" | "ADDED_LIST_ITEM",
  "object": { "type": "album" | "review" | "list", "id": "01J..." },
  "created_at": "2026-03-05T12:34:56Z",
  "payload": { "album_id": "01J...", "rating": 4.5, "review_id": null }
}
```

- **actor_id:** User who performed the action.
- **type:** One of the four; use for feed ranking (e.g. boost WROTE_REVIEW over RATED_ALBUM).
- **object:** Target entity type and ID for deep links and display.
- **payload:** Type-specific data (e.g. album_id, rating, review_id for RATED_ALBUM / WROTE_REVIEW).

---

## Listening event (from PDF Appendix A + §7.4)

Append-only record of “user played album at time from source.” Used for recently played, logs, and optional link to ratings/reviews.

```json
{
  "id": "01J...",
  "user_id": "01J...",
  "album_id": "01J...",
  "played_at": "2026-03-05T12:10:00Z",
  "source": "spotify" | "apple" | "manual",
  "source_ref": { "provider_item_id": "...", "raw": {} }
}
```

- **Dedup key:** `(user_id, album_id, floor(played_at to 10 minutes))`; store count to avoid feed flooding when user loops an album.

---

## Canonical entities (from PDF §7.3)

SoundScore owns these; providers map into them via a mapping table.

- **Artist:** Canonical artist (name, etc.).
- **Album:** Release; has artist(s), title, release year, track count, etc.
- **Track:** Recording; belongs to an album.

**Mapping table:** Links canonical IDs to provider-specific IDs (e.g. Spotify album ID, Apple Music ID) with confidence and provenance. Enables “same album” across providers and resilient catalog when a provider changes.

---

## Current app models (DummyData.kt) and future mapping

When you wire the backend, map API/events to existing or extended UI models:

- **Album:** Already has `id`, `title`, `artist`, `year`, `artColors` (placeholder); add or swap to `artworkUrl` when using real catalog. Map from canonical Album + optional provider art URL.
- **FeedItem:** Maps from **activity event** + resolved **album** (and optionally review snippet). `username` ← actor’s handle; `action` ← human-readable from `type`; `album`, `rating`, `reviewSnippet` from payload and linked entities.
- **UserProfile:** Maps from profile API (handle, bio, counts, top albums with ratings, genres, avg rating). Keep shape similar so ProfileScreen can keep using a single profile type.

Keep `SeedData` for previews and UI tests; replace data source with repository/API when backend is live.

---

## Idempotency and writes

All writes (ratings, reviews, follows, reactions, list items) should send an **idempotency key** (e.g. client-generated UUID) so that:
- Mobile retries after network failure don’t create duplicates.
- Offline outbox replay is safe.

Server should treat same idempotency key as “already applied” and return the same result (e.g. 200 with existing resource or 201 with created resource).
