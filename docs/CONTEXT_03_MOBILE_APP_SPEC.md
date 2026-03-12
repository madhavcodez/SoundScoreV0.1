# Mobile App Spec

Use this when implementing or changing mobile UX, navigation, performance, or offline behavior. Sources: architecture PDF §4–5, current Android codebase.

---

## Important: current stack vs PDF

The **architecture PDF** describes React Native + Expo as the default. **This repo is Android native:** Kotlin, Jetpack Compose, Navigation Compose, Material3. Apply the same principles and journeys below to the existing Compose screens and navigation.

---

## Mobile design principles (from PDF §4)

- **Progressive disclosure:** First session is not a writing assignment.
- **Fast capture:** Logging is the primary call-to-action everywhere.
- **Thumb-first ergonomics:** Key actions in reachable zones; one-hand usage respected.
- **Safe social defaults:** Friend-first; public exposure gradual.
- **Shareability by design:** Every major surface can become a share card.

---

## Core mobile journeys (from PDF §4)

1. **Onboard → identity:** Seed favorites, pick rating scale, optional provider connect.
2. **Log → rate → (optional) review:** Write-later queue for reviews.
3. **Follow friends → feed:** Lightweight reactions (emoji + comments).
4. **Create lists → share list cards:** Drive discovery.
5. **Weekly recap card → share:** Acquisition loop.
6. **Export / delete / disconnect:** Trust and portability.

---

## Current Android implementation

- **Entry:** `MainActivity.kt` → `SoundScoreApp.kt`.
- **Navigation:** Bottom tabs (Feed, Log, Search, Lists, Profile) via sealed `Screen` in `AppNavigation.kt`; `NavHost` in `SoundScoreApp.kt` with composable routes. Floating "liquid glass" bar (glass card with icons).
- **Screens:** `FeedScreen.kt`, `LogScreen.kt`, `SearchScreen.kt`, `ListsScreen.kt`, `ProfileScreen.kt`. All use dummy data from `SeedData` in `DummyData.kt`.
- **Theme:** Dark base (`DarkBase`), glass surfaces (`GlassBg`, `GlassBorder`), accent `ElectricBlue`; `Color.kt`, `Theme.kt`, `Type.kt`.

---

## State management and data flow (from PDF §5; apply to Android)

- **Server-state:** Use a caching layer (e.g. Room + repository, or a client like Retrofit + cache policy) for feed, profile, catalog; retries and background refetch.
- **UI state:** Lightweight (e.g. ViewModel + state, or small state holders) for navigation, drafts, transient flags.
- **Typed APIs:** Prefer OpenAPI-generated or typed API clients to keep mobile and backend aligned.
- **Optimistic updates** for reactions/ratings; back writes with idempotency keys to avoid duplicates on retry.

---

## Offline-first strategy (from PDF §5.4; when implemented)

- **Local DB:** SQLite via Room (or similar) for feed items, profiles, lists, drafts.
- **Outbox pattern:** Every write creates an outbox record with idempotency key; sync engine flushes when online.
- **Conflict policy:** Last-write-wins for reactions; review edits use revision IDs; ratings are upserts keyed by (user, album).
- **Background refresh:** Constrained; prefer push for recap-ready and social events over polling.

---

## Navigation, deep links, share flows (from PDF §5.5)

- **Navigation:** Bottom tabs (Feed, Log, Search, Lists, Profile); stack navigators per tab when you add detail screens.
- **Deep links:** Universal links (iOS) / App Links (Android) for albums, lists, profiles, recaps. Implement in Android via intent filters and navigation to the right screen with IDs.
- **Share cards:** Generated server-side for consistent typography; cached via CDN; share sheet uses image + deep link URL.
- **Provider Listen buttons:** Open external provider app via safe deep links; fall back to web if app not installed.

---

## Push notifications (from PDF §5.6)

- **Unified layer:** FCM; APNs for iOS when you add iOS.
- **Types:** New follower; comment/reaction on my activity; recap ready; write-later nudge.
- **Dedup:** Collapse keys to prevent spammy bursts (e.g. many reactions).
- **User controls:** Per-type toggles; quiet hours.
- **Safety:** Never put sensitive content in push payloads; fetch details in-app after open.

---

## Performance budgets (from PDF §5.7)

| Surface | Target | How to enforce (Android) |
|--------|--------|---------------------------|
| Cold start | < 2.0s to first screen | Minimize init; defer non-critical work; preload fonts/images. |
| Feed scroll | 60fps sustained | LazyColumn/lists; avoid overdraw; image caching (e.g. Coil). |
| Image loading | < 200ms cache hit | Disk + memory cache; CDN thumbnails; prefetch on Wi‑Fi. |
| Write actions | < 150ms UI response | Optimistic updates; outbox sync in background. |

Current app already uses `LazyColumn` on Feed and Coil for images; keep these budgets in mind when adding network and persistence.
