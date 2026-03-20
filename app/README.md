# SoundScore Android

> Native Android client — Kotlin + Jetpack Compose + MVVM

## Architecture

```
┌───────────────────────────────────────────────────────────┐
│                     MainActivity                          │
│           AppNavigation (NavHost + Screen)                │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐           │
│  │ Feed │ │ Log  │ │Search│ │Lists │ │Profle│           │
│  │Screen│ │Screen│ │Screen│ │Screen│ │Screen│           │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘           │
│     │        │        │        │        │                 │
│  ┌──▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐           │
│  │ Feed │ │ Log  │ │Search│ │Lists │ │Profle│           │
│  │  VM  │ │  VM  │ │  VM  │ │  VM  │ │  VM  │           │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘           │
│     └────────┴────────┴────┬───┴────────┘                 │
│                            │                              │
│         ┌──────────────────▼───────────────────┐          │
│         │  SoundScoreRepository (interface)     │          │
│         │  RemoteSoundScoreRepository (impl)    │          │
│         │  AppContainer.repository (singleton)  │          │
│         └──────────┬──────────────┬─────────────┘          │
│                    │              │                        │
│          ┌─────────▼───┐    ┌────▼────────────┐           │
│          │  ApiClient   │    │ OutboxSyncEngine │           │
│          │  (Retrofit)  │    │ InMemoryOutbox   │           │
│          └──────┬──────┘    └─────────────────┘           │
│                 │                                         │
│          ┌──────▼──────┐                                  │
│          │ SoundScore  │                                  │
│          │    Api      │                                  │
│          │ (Retrofit   │                                  │
│          │  interface) │                                  │
│          └─────────────┘                                  │
└───────────────────────────────────────────────────────────┘
```

**Data flow:** Each Screen observes its ViewModel's `StateFlow<UiState>` via
`collectAsStateWithLifecycle()`. ViewModels combine repository `StateFlow`s
into a single `UiState`. Mutations dispatch to repository, which applies
optimistic local updates and queues an `OutboxOperation` for server sync.

## Screens

| # | Screen | File | ViewModel | Key Features |
|---|--------|------|-----------|--------------|
| 1 | Feed | `FeedScreen.kt` | `FeedViewModel` | Trending albums carousel (`TrendingHeroCard`), activity cards with like/comment/share chips, staggered fade-in animation |
| 2 | Log (Diary) | `LogScreen.kt` | `LogViewModel` | Summary stats card, quick-rate carousel, diary timeline entries, "Write Later" placeholder card, FAB with bottom sheet for album logging |
| 3 | Search (Discover) | `SearchScreen.kt` | `SearchViewModel` | Pill search bar, trending search cards, genre browse grid (2-column), chart rows, search result cards |
| 4 | Lists | `ListsScreen.kt` | `ListsViewModel` | Featured list hero card, compact list cards carousel, create list bottom sheet with title input, empty state CTA |
| 5 | Profile | `ProfileScreen.kt` | `ProfileViewModel` | Glass profile header with avatar, stat pills row, action buttons (share/export/settings), favorite albums grid (3-column), taste DNA tags row, weekly recap card, recent activity list |

## ViewModels

| ViewModel | File | UiState Type | Key Methods |
|-----------|------|-------------|-------------|
| `FeedViewModel` | `FeedViewModel.kt` | `FeedUiState(items, trendingAlbums, syncMessage)` | `toggleLike(feedItemId)` |
| `LogViewModel` | `LogViewModel.kt` | `LogUiState(quickLogAlbums, ratings, summaryStats, recentLogs, syncMessage)` | `updateRating(albumId, rating)` |
| `SearchViewModel` | `SearchViewModel.kt` | `SearchUiState(query, results, browseGenres, chartEntries, syncMessage)` | `updateQuery(next)` |
| `ListsViewModel` | `ListsViewModel.kt` | `ListsUiState(lists, showcases, syncMessage)` | `createList(title)` |
| `ProfileViewModel` | `ProfileViewModel.kt` | `ProfileUiState(profile, metrics, favoriteAlbums, notificationPreferences, latestRecap, syncMessage, recentActivity)` | `buildShareText()`, `exportDataSnapshot(onComplete)`, `updateNotificationPreferences(prefs)`, `generateRecap()` |
| `ScreenPresentation` | `ScreenPresentation.kt` | (shared data classes + builder functions) | `buildTrendingAlbums()`, `buildLogSummaryStats()`, `buildRecentLogs()`, `buildBrowseGenres()`, `buildChartEntries()`, `resolveSearchResults()`, `resolveListShowcases()`, `buildProfileMetrics()`, `buildFavoriteAlbums()` |
| (Deep Link) | `DeepLinkResolver.kt` | (utility) | Deep link URL resolution for navigation |

## Data Layer

### Repository

**Interface** — `SoundScoreRepository` (13 methods):
- `feedItems`, `albums`, `profile`, `ratings`, `lists`, `pendingOutboxOps`, `notificationPreferences`, `latestRecap`, `syncMessage` (all `StateFlow`)
- `searchAlbums(query)`, `refresh()`, `updateRating(albumId, rating)`, `toggleLike(feedItemId)`, `createList(title)`, `exportSnapshot()`, `updateNotificationPreferences(prefs)`, `registerDeviceToken(platform, token)`, `loadLatestRecap()`, `generateLatestRecap()`, `syncOutbox()`

**Implementation** — `RemoteSoundScoreRepository`:
- Seeds from `SeedData` on init, then launches `refresh()` + `syncOutbox()` in background
- `ensureAuth()`: auto-login with env vars or hardcoded dev credentials (login, fallback to signup on 409)
- Optimistic updates for `updateRating()`, `toggleLike()`, `createList()` — local state changes before server sync
- `mapAlbumDto()` and `mapFeedItem()` convert DTOs to domain models, falling back to seed data for colors

**Singleton** — `AppContainer.repository` (`lazy` initialization)

### API Client

| File | Description |
|------|-------------|
| `ApiClient.kt` | Retrofit builder with `kotlinx.serialization` JSON converter. `OkHttpClient` with `HttpLoggingInterceptor` (DEBUG only). Base URL from `BuildConfig.API_BASE_URL`. |
| `SoundScoreApi.kt` | Retrofit interface — 20 endpoints: `signUp`, `login`, `refresh`, `me`, `searchAlbums`, `getAlbum`, `rateAlbum`, `createReview`, `updateReview`, `createList`, `addListItem`, `feed`, `reactToActivity`, `exportData`, `deleteAccount`, `latestRecap`, `generateRecap`, `registerDeviceToken`, `unregisterDeviceToken`, `getNotificationPreferences`, `upsertNotificationPreferences`, `getNotifications` |
| `ApiModels.kt` | DTOs: `AuthRequest`, `AuthResponse`, `RefreshRequest`, `RatingRequest`, `ReviewRequest`, `UpdateReviewRequest`, `CreateListRequest`, `AddListItemRequest`, `ReactionRequest`, `DeviceTokenRequest`, `AlbumDto`, `UserProfileDto`, `ActivityEventDto`, `WeeklyRecapDto`, `NotificationPreferenceDto`, `CursorPage<T>` |

### Offline-First

| File | Description |
|------|-------------|
| `OutboxSyncEngine.kt` | Flushes pending operations with handler callback. Marks dispatched or failed with exponential backoff. |
| `InMemoryOutboxStore.kt` | `MutableStateFlow<List<OutboxOperation>>` with `enqueue()`, `markDispatched()`, `markFailed()`. Backoff: `2^min(attempt, 6)` seconds. |
| `OutboxOperation.kt` | Data class with `id`, `type`, `payload: Map<String, String>`, `idempotencyKey`, `createdAtMs`, `attemptCount`, `nextAttemptAtMs`, `lastError`. 7 operation types: `RATE_ALBUM`, `TOGGLE_REACTION`, `CREATE_LIST`, `EXPORT_DATA`, `REGISTER_DEVICE_TOKEN`, `UPSERT_NOTIFICATION_PREFERENCES`, `GENERATE_RECAP`. |

## Components

| Component | File | Description |
|-----------|------|-------------|
| `GlassCard` | `GlassCard.kt` | Glass-morphic card with tint, frosted material, configurable corners/border/padding, optional onClick |
| `AlbumArtPlaceholder` | `AlbumArtPlaceholder.kt` | Gradient placeholder using album art colors when artwork URL is unavailable |
| `AppBackdrop` | `AppBackdrop.kt` | Full-screen radial gradient background |
| `StarRating` | `StarRating.kt` | 6-star interactive rating with optional `onRate` callback |
| `SoundScoreButton` | `SoundScoreButton.kt` | Primary CTA button with accent color fill |
| `NewComponents` | `NewComponents.kt` | `ScreenHeader`, `SectionHeader`, `SyncBanner`, `EmptyState`, `AlbumArtwork`, `AvatarCircle`, `ActionChip`, `PillSearchBar`, `StatPill`, `TimelineEntry`, `TrendChartRow`, `MosaicCover` |
| `PremiumComponents` | `PremiumComponents.kt` | `GlassIconButton`, `BlueButton`, `FloatingNavigationBar` |

## Theme

| File | Description |
|------|-------------|
| `Color.kt` | Material3 color tokens: `DarkBase`, `DarkSurface`, `DarkElevated`, `GlassBg`, `GlassBorder`, `ChromeLight`, `ChromeMedium`, `TextSecondary`, `TextTertiary`, `AccentGreen`, `AccentAmber`, `AccentCoral`, `AccentViolet`, `FeedItemBorder`, overlay levels. `AlbumColors` object with 10 named palettes (forest, lime, ember, orchid, lagoon, rose, midnight, slate, coral, amber). |
| `Theme.kt` | `SoundScoreTheme` composable wrapping `MaterialTheme` with dark color scheme. Sets system bar colors. |
| `Type.kt` | Material3 typography configuration. |

## Navigation

| File | Description |
|------|-------------|
| `AppNavigation.kt` | `Screen` sealed interface with 5 destinations: `Feed`, `Log`, `Search`, `Lists`, `Profile`. Each has `label`, `iconFilled`, `iconOutlined`. `Screen.all` provides ordered list. Uses `@Serializable` for type-safe nav. |
| `DeepLinkResolver.kt` | Deep link URL parsing utility for navigation routing. |

`FloatingNavigationBar` (in `PremiumComponents.kt`) renders the tab bar at the bottom of the screen with glass-morphic styling.

## Build

```bash
# Load environment variables (API base URL, dev credentials)
source scripts/run-env.sh

# Build debug APK
./gradlew assembleDebug

# Run unit tests
./gradlew testDebugUnitTest

# Run instrumented tests
./gradlew connectedDebugAndroidTest

# API endpoints
# Debug:   http://10.0.2.2:8080  (Android emulator localhost)
# Release: https://soundscore-api.up.railway.app

# Requirements
# Min SDK: 26 (Android 8.0)
# Target SDK: 35
# Kotlin: 1.9+
# Jetpack Compose BOM
# Dependencies: Retrofit, OkHttp, kotlinx.serialization, Coil (image loading)
```

## Testing

### Unit Tests (4 files)

| File | Functions | Description |
|------|-----------|-------------|
| `SoundScoreRepositoryMappingTest.kt` | Tests for `mapAlbumDto()` | Verifies DTO-to-domain mapping, fallback to seed colors |
| `OutboxSyncEngineTest.kt` | Tests for enqueue, dispatch, failure backoff | Verifies exponential backoff, idempotency key propagation |
| `DeepLinkResolverTest.kt` | Tests for deep link URL parsing | Verifies route extraction from URLs |
| `ScreenPresentationTest.kt` | Tests for `buildTrendingAlbums()`, `buildLogSummaryStats()`, etc. | Verifies presentation helper logic |

### Instrumented Tests (1 file)

| File | Functions | Description |
|------|-----------|-------------|
| `ScreenSmokeTest.kt` | 5 smoke tests | Renders each screen composable and asserts key UI elements exist |

### Test Status

- **14 test functions** across 5 files
- **5 smoke tests BROKEN** — stale assertions against UI text that has changed (e.g., looking for "Latest Logs" when screen now says "Your diary entries")
- **Coverage: ~15-20%** — only data layer mapping and presentation helpers are tested
- **No ViewModel tests** — no tests for state flow transformations or mutation methods
- **No repository integration tests** — no tests with mock API responses

## Known Issues (from audit)

| ID | Severity | Description |
|----|----------|-------------|
| ISSUE-016 | HIGH | `RemoteSoundScoreRepository.ensureAuth()` stores access token as a plain `var` in memory with no refresh mechanism. If the token expires, all API calls fail until app restart. |
| ISSUE-017 | MEDIUM | `AppContainer.repository` is a `lazy` singleton without dependency injection — not testable. ViewModels directly reference `AppContainer.repository` instead of receiving it via constructor. |
| ISSUE-018 | MEDIUM | `mapFeedItem()` accesses `event.payload["albumId"]` and `event.payload["rating"]` directly from `JsonObject` — fragile parsing with no error handling for missing keys. |
| ISSUE-019 | MEDIUM | `OutboxStore` is in-memory only — all pending operations lost on process death. No Room/DataStore persistence. |
| ISSUE-020 | LOW | 5 smoke tests in `ScreenSmokeTest.kt` are BROKEN due to stale text assertions. Tests assert UI strings that no longer match current screen content. |
| ISSUE-021 | LOW | `LogScreen` "Log an album" bottom sheet is a placeholder — shows "Album search coming soon" text instead of functional search. |
| ISSUE-022 | MEDIUM | No Spotify integration on Android — no artwork enrichment, no remote search, no track listing. Albums display only seed data artwork URLs or gradient placeholders. |

## Feature Parity with iOS

| Feature | Android | iOS | Notes |
|---------|---------|-----|-------|
| Feed (trending + activity) | Yes | Yes | iOS adds trending songs toggle and curated lists in feed |
| Log / Diary | Yes | Yes | iOS adds songs mode toggle with per-track ratings; Android has "Write Later" placeholder |
| Search / Discover | Yes (local only) | Yes (local + Spotify) | iOS merges Spotify search results; Android searches local catalog only |
| Lists | Yes | Yes | Feature parity — both have create, featured hero, compact cards |
| Profile | Yes | Yes | iOS adds Taste DNA (genre bars, AI tagline, controversial pick) |
| Album Detail | No | Yes | **Missing from Android** — no album detail screen, no track-level view |
| AI Buddy (Cadence) | No | Yes | **Missing from Android** — no Gemini integration, no chat interface |
| Settings | No | Yes | **Missing from Android** — no theme switcher, notification config, quiet hours |
| Auth (login/signup) | Auto (in repository) | Dedicated AuthScreen | Android auto-authenticates in init; iOS has full login/signup UI |
| Splash Screen | No | Yes | **Missing from Android** — no animated splash |
| Spotify Integration | No | Yes | **Missing from Android** — no artwork enrichment, search merge, track fetching |
| Per-Track Ratings | No | Yes | **Missing from Android** — no track-level rating |
| Offline Outbox | Yes | Yes | Both use in-memory outbox with idempotency keys and exponential backoff |
| Theme System | Material3 (single dark) | 6 swipeable themes | Android uses stock Material3 dark; iOS has 6 custom glassmorphic themes |
| Weekly Recap | Yes | Yes | Both display and share; Android also has `generateRecap()` |
| Data Export | Yes (via ProfileVM) | Yes (via Settings) | Android exports JSON snapshot; iOS queues via outbox |
| Account Delete | Yes (API exists) | Yes (Settings UI) | Android has API method but no UI trigger |
| Deep Links | Yes (DeepLinkResolver) | No | **Android-only** — deep link URL parsing for navigation |

---

*Last audited: 2026-03-19*
