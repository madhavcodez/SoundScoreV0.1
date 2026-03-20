# SoundScore iOS

> Native iOS client — SwiftUI + MVVM + Combine

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      ContentView                            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐             │
│  │ Feed │ │ Log  │ │Search│ │  AI  │ │Profile│             │
│  │Screen│ │Screen│ │Screen│ │Buddy │ │Screen│             │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘             │
│     │        │        │        │        │                   │
│  ┌──▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐ ┌──▼───┐             │
│  │ Feed │ │ Log  │ │Search│ │AIBudy│ │Profle│             │
│  │  VM  │ │  VM  │ │  VM  │ │  VM  │ │  VM  │             │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘             │
│     └────────┴────────┴────┬───┴────────┘                   │
│                            │                                │
│              ┌─────────────▼──────────────┐                 │
│              │   SoundScoreRepository     │                 │
│              │   (shared singleton)       │                 │
│              └──────┬──────────┬──────────┘                 │
│                     │          │                            │
│           ┌────────▼──┐   ┌──▼──────────┐                  │
│           │ APIClient │   │ OutboxStore  │                  │
│           │ + SoundSc │   │ + SyncEngine │                  │
│           │   oreAPI   │   └─────────────┘                  │
│           └────────┬──┘                                     │
│                    │                                        │
│     ┌──────────────┼──────────────┐                         │
│     │              │              │                         │
│  ┌──▼──┐    ┌──────▼──┐    ┌─────▼────┐                    │
│  │Auth │    │ Spotify │    │AIBuddy   │                    │
│  │Mngr │    │ Service │    │Service   │                    │
│  └─────┘    └─────────┘    │(Gemini)  │                    │
│                            └──────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

**Data flow:** Screen observes ViewModel `@Published` properties via Combine.
ViewModel subscribes to `SoundScoreRepository.$property` publishers.
Mutations go through Repository, which queues an `OutboxOperation` for
optimistic local update, then flushes via `OutboxSyncEngine` to the API.

## Screens

| # | Screen | File | ViewModel | Key Features |
|---|--------|------|-----------|--------------|
| 1 | Splash | `SplashScreen.swift` | (none) | Animated theme cycling (12 cycles across 6 themes), logo bounce, "Get Started" CTA |
| 2 | Auth | `AuthScreen.swift` | (none, uses `AuthManager`) | Login/signup toggle, dev credentials pre-filled, 409-conflict fallback to login |
| 3 | Feed | `FeedScreen.swift` | `FeedViewModel` | Trending albums carousel, trending songs toggle, curated lists, activity cards with like/comment/share |
| 4 | Log (Diary) | `LogScreen.swift` | `LogViewModel` | Summary stats row, quick-rate card carousel, album/songs segmented toggle, diary timeline entries, FAB for quick-log search sheet |
| 5 | Search (Discover) | `SearchScreen.swift` | `SearchViewModel` | Pill search bar, genre browse cards, trending chart rows, Spotify-merged search results, debounced 350ms query |
| 6 | AI Buddy (Cadence) | `AIBuddyScreen.swift` | `AIBuddyViewModel` | Chat interface, suggestion chips, agentic action cards (rate/review/search), confirmation toasts, Cadence character avatar |
| 7 | Album Detail | `AlbumDetailScreen.swift` | `AlbumDetailViewModel` | Hero artwork with gradient, Album/Songs tab picker, tracklist with per-song rating, songs breakdown analytics, related albums, lists containing album |
| 8 | Profile | `ProfileScreen.swift` | `ProfileViewModel` | Blurred artwork hero banner, avatar with glow, inline stats, favorite albums carousel, Taste DNA (AI-generated 3-word tagline, genre bar chart, taste stat pills, controversial pick), weekly recap, recent activity timeline |
| 9 | Settings | `SettingsScreen.swift` | `ProfileViewModel` | Swipeable theme preview cards (6 themes), account info, notification toggles (4 categories), quiet hours stepper, data export, account deletion with confirmation, sign out |
| 10 | Lists | `ListsScreen.swift` | `ListsViewModel` | Featured list hero, compact list cards carousel, create list bottom sheet, empty state with CTA |
| 11 | ContentView | `ContentView.swift` | (orchestrator) | NavigationStack, splash gating, auth gating, FloatingTabBar, tab routing, album detail navigation |
| 12 | TabContent | `ContentView.swift` | (none) | Switch on Tab enum to render active screen |
| 13 | QuickLogSearchSheet | `LogScreen.swift` | `SearchViewModel` | Modal sheet with album search for quick logging |

## ViewModels

| ViewModel | File | @Published Properties | Key Methods |
|-----------|------|-----------------------|-------------|
| `AIBuddyViewModel` | `AIBuddyViewModel.swift` | `messages`, `inputText`, `isThinking`, `cadenceState`, `errorMessage`, `suggestions`, `actionConfirmation`, `searchResults` | `sendMessage()`, `executeRating(_:)`, `executeBatchRatings(_:)`, `executeReview(...)`, `discardAction(...)`, `addSearchResultToLibrary(_:)`, `tapSuggestion(_:)` |
| `AlbumDetailViewModel` | `AlbumDetailViewModel.swift` | `tracks`, `trackRatings`, `userRating`, `isLoadingTracks` | `updateAlbumRating(_:)`, `updateTrackRating(trackId:rating:)` |
| `FeedViewModel` | `FeedViewModel.swift` | `items`, `trendingAlbums`, `trendingSongs`, `featuredLists`, `syncMessage`, `isLoading`, `errorMessage` | `toggleLike(_:)`, `refresh()` |
| `ListsViewModel` | `ListsViewModel.swift` | `lists`, `showcases`, `syncMessage`, `isLoading`, `errorMessage` | `createList(title:)` |
| `LogViewModel` | `LogViewModel.swift` | `quickLogAlbums`, `ratings`, `summaryStats`, `recentLogs`, `recentSongLogs`, `syncMessage`, `isLoading`, `errorMessage` | `updateRating(albumId:rating:)` |
| `ProfileViewModel` | `ProfileViewModel.swift` | `profile`, `metrics`, `favoriteAlbums`, `genres`, `notificationPreferences`, `recap`, `recentActivity`, `syncMessage`, `isLoading`, `errorMessage`, `tasteDNA`, `soundDNASummary`, `showExportSuccess`, `showDeleteConfirm` | `shareProfileText()`, `generateSoundDNA()`, `saveNotificationPreferences()` |
| `SearchViewModel` | `SearchViewModel.swift` | `query`, `results`, `browseGenres`, `chartEntries`, `syncMessage`, `isSearching`, `errorMessage` | `updateQuery(_:)` (debounced 350ms, local + Spotify merge) |

## Services

| Service | File | Description |
|---------|------|-------------|
| `AuthManager` | `AuthManager.swift` | Singleton. JWT login/signup/refresh/logout. Persists tokens in UserDefaults (`ss_accessToken`, `ss_refreshToken`, `ss_handle`). Includes `devAutoSignup()` for DEBUG builds. |
| `AIBuddyService` | `AIBuddyService.swift` | Actor singleton. Calls Gemini 2.5 Flash via REST. Builds system prompt with personality, album catalog, and user context. Parses `[RATE:...]`, `[REVIEW:...]`, `[SEARCH:...]` action tags from response text. |
| `APIClient` | `APIClient.swift` | Generic HTTP client. GET/POST/PUT/DELETE with typed Decodable returns + void variants. Auto-retries on 401 via `AuthManager.refresh()`. Snake-case key decoding. Debug request logging. |
| `SoundScoreAPI` | `SoundScoreAPI.swift` | Typed API facade over `APIClient`. Endpoints: search, albums, tracks, track-ratings, ratings, reviews, lists, feed, reactions, comments, follow/unfollow, profile, recaps, push tokens, notification preferences, export, delete account. DTOs: `AlbumDto`, `TrackDto`, `TrackRatingDto`, `UserProfileDto`, `ActivityEventDto`, `WeeklyRecapDto`, `ListDetailDto`, `NotificationPreferenceDto`, `CursorPage<T>`. |
| `SoundScoreRepository` | `SoundScoreRepository.swift` | Central data store singleton. `@Published` state for albums, feedItems, profile, ratings, tracksByAlbum, trackRatings, lists, latestRecap, syncMessage, isLoading, errorMessage. Optimistic mutations + outbox queue. Spotify artwork enrichment on init. Mapper functions for DTO-to-domain. |
| `SpotifyService` | `SpotifyService.swift` | Actor singleton. Client Credentials OAuth flow. Album search, artwork lookup (with in-memory cache), album detail, track listing. Response types fully decoded. |
| `OutboxStore` | `OutboxStore.swift` | `InMemoryOutboxStore` with enqueue/markDispatched/markFailed. `OutboxSyncEngine` flushes pending ops with exponential backoff. 8 operation types: rateAlbum, rateTrack, createReview, toggleReaction, createList, exportData, registerDeviceToken, updateNotificationPreferences. |
| `ThemeManager` | `ThemeManager.swift` | Observable singleton. 6 themes (Emerald, Bonfire, Rose, Amethyst, Midnight, Gilt). Persists selection in UserDefaults. Provides `primary`, `secondary`, `colors` (darkBase/darkSurface/darkElevated), backdrop glow. Legacy migration from old theme names. |

## Component Library

### Navigation

| Component | File | Description |
|-----------|------|-------------|
| `FloatingTabBar` | `FloatingTabBar.swift` | Glass-morphic floating tab bar with 5 tabs, haptic feedback, animated selection indicator |
| `Tab` | `Tab.swift` | Enum: `.feed`, `.log`, `.search`, `.aiBuddy`, `.profile` with icons and labels |
| `ScreenHeader` | `ScreenHeader.swift` | Title + subtitle header with optional action button |
| `SectionHeader` | `SectionHeader.swift` | Eyebrow text + title + optional trailing text |

### Cards

| Component | File | Description |
|-----------|------|-------------|
| `GlassCard` | `GlassCard.swift` | Glassmorphic container with tint color, corner radius, border, optional frosted material |
| `ListCards` | `ListCards.swift` | `FeaturedListHero` and `CompactListCard` for list showcases with mosaic covers |
| `MosaicCover` | `MosaicCover.swift` | 2x2 album art grid for list thumbnails |
| `AlbumArtwork` | `AlbumArtwork.swift` | AsyncImage with gradient fallback from `artColors`, configurable corner radius |
| `TimelineEntry` | `TimelineEntry.swift` | Date/time sidebar with connected line and content slot |
| `TrendChartRow` | `TrendChartRow.swift` | Ranked album row with rank badge, artwork, stats, and movement label |

### Input

| Component | File | Description |
|-----------|------|-------------|
| `PillSearchBar` | `PillSearchBar.swift` | Capsule-shaped text field with magnifying glass icon |
| `GlassSegmentedControl` | `GlassSegmentedControl.swift` | Glass-style 2-segment picker (Albums/Songs) |
| `StarRating` | `StarRating.swift` | 6-star interactive rating with half-star support, optional `onRate` callback |
| `AlbumRatingSheet` | `AlbumRatingSheet.swift` | Bottom sheet with slider rating, review text editor, save button |
| `SongRatingSheet` | `SongRatingSheet.swift` | Bottom sheet for per-track rating |
| `ReviewSheet` | `ReviewSheet.swift` | Text editor sheet for reviews |

### Buttons

| Component | File | Description |
|-----------|------|-------------|
| `SSButton` | `SSButton.swift` | Primary CTA button with gradient fill |
| `ActionChip` | `ActionChip.swift` | Small tappable chip with icon + text (like, comment, share) |
| `GlassIconButton` | `GlassIconButton.swift` | Circular glass button with icon and label |

### Display

| Component | File | Description |
|-----------|------|-------------|
| `AvatarCircle` | `AvatarCircle.swift` | Gradient circle with initials text |
| `StatPill` | `StatPill.swift` | Glass pill showing value + label metric |
| `EmptyState` | `EmptyState.swift` | Icon + title + subtitle + optional CTA for empty lists |
| `SyncBanner` | `SyncBanner.swift` | Amber banner showing offline/sync status |
| `SkeletonView` | `SkeletonView.swift` | Shimmer loading placeholder |
| `AppBackdrop` | `AppBackdrop.swift` | Full-screen gradient background with theme-adaptive glow |

### AI

| Component | File | Description |
|-----------|------|-------------|
| `CadenceCharacter` | `CadenceCharacter.swift` | Animated AI avatar with idle/thinking/happy states |
| `CadenceActionCards` | `CadenceActionCards.swift` | `CadenceReviewCard`, `CadenceQuickRateCard`, `CadenceBatchRatingCard`, `CadenceSearchResultsCard` — interactive action cards rendered inline in chat |

## Models

| Model | File | Key Properties |
|-------|------|---------------|
| `Album` | `Album.swift` | `id`, `title`, `artist`, `year`, `artColors: [Color]`, `artworkUrl?`, `avgRating`, `logCount`, `spotifyId?`, `genres` |
| `Track` | `Track.swift` | `id`, `albumId`, `title`, `trackNumber`, `durationMs?`, `spotifyId?`, computed `formattedDuration` |
| `FeedItem` | `FeedItem.swift` | `id`, `username`, `action`, `album`, `rating`, `reviewSnippet?`, `likes`, `comments`, `timeAgo`, `isLiked` |
| `UserProfile` | `UserProfile.swift` | `handle`, `bio`, `logCount`, `reviewCount`, `listCount`, `topAlbums`, `genres`, `avgRating`, `albumsCount`, `followingCount`, `followersCount`, `favoriteAlbums` |
| `UserList` | `UserList.swift` | `id`, `title`, `note?`, `albumIds`, `curatorHandle`, `saves` |
| `WeeklyRecap` | `WeeklyRecap.swift` | `id`, `weekStart`, `weekEnd`, `totalLogs`, `averageRating`, `shareText`, `deepLink` |
| `NotificationPreferences` | `NotificationPreferences.swift` | `socialEnabled`, `recapEnabled`, `commentEnabled`, `reactionEnabled`, `quietHoursStart`, `quietHoursEnd` |
| `SeedData` | `SeedData.swift` | 20 albums with real artwork URLs, 10 feed items with review snippets, 5 lists, sample tracks for 6 albums, initial ratings, default profile |
| `PresentationHelpers` | `PresentationHelpers.swift` | `LogSummaryStat`, `RecentLogEntry`, `BrowseGenre`, `ChartEntry`, `ListShowcase`, `ProfileMetric`, `TrendingSong`, `RecentSongLogEntry`, `TasteDNA` + builder functions |

## Configuration

### AppConfig (`Config/AppConfig.swift`)
- **DEBUG**: `http://localhost:8080`
- **Release**: `https://soundscore-api.up.railway.app`

### Secrets (`Config/Secrets.swift`)
- **Gitignored** (should be, but currently contains real keys)
- `spotifyClientId` — Spotify Client Credentials for artwork + search
- `spotifyClientSecret` — Spotify Client Credentials secret
- `geminiAPIKey` — Google Gemini 2.5 Flash key for Cadence AI

## Theme System

### SSColors (`Theme/SSColors.swift`)
- Theme-adaptive backgrounds: `darkBase`, `darkSurface`, `darkElevated` (delegate to ThemeManager)
- Glass tokens: `glassBg` (7% white), `glassBorder` (18% white), `glassFrosted`, `glassSheet`
- Chrome text: `chromeLight` (94%), `chromeMedium` (70%), `chromeDim` (44%), `chromeFaint` (24%)
- Semantic accents: `accentGreen`, `accentAmber`, `accentCoral`, `accentViolet` (fixed, not theme-dependent)
- Overlay levels: `overlayDark` (70% black), `overlayMedium`, `overlayLight`
- 10 album color palettes: forest, lime, ember, orchid, lagoon, rose, midnight, slate, coral, amber
- `Color(hex:alpha:)` extension for hex initialization

### SSTypography (`Theme/SSTypography.swift`)
- System font with `.rounded` design throughout
- Display: 22pt bold, 28pt bold
- Headline: 18pt semibold, 22pt semibold
- Title: 14pt medium, 16pt semibold
- Body: 12pt regular, 14pt regular, 16pt regular
- Label: 10pt medium, 12pt medium, 14pt semibold

### ThemeManager (`Theme/ThemeManager.swift`)
- 6 swipeable themes: Emerald, Bonfire, Rose, Amethyst, Midnight, Gilt
- Each theme provides: `primary`, `secondary`, `backdropGlow`, `colors` (ThemeColorScheme with darkBase/darkSurface/darkElevated)
- Persisted in UserDefaults under `ss_accentTheme`
- Legacy migration from old names (mint -> emerald, sunset -> bonfire, etc.)
- Settings screen renders swipeable `TabView` with live theme preview cards

## Cadence AI

### How It Works
1. **Model**: Gemini 2.5 Flash (`generativelanguage.googleapis.com/v1beta`)
2. **System prompt**: Includes personality instructions ("dorky, passionate music nerd"), album catalog with IDs, user taste context (ratings, genres, avg rating)
3. **Action parsing**: Response text is scanned for bracket-tagged actions:
   - `[RATE:album_id:Album Title:4.5]` — renders `CadenceQuickRateCard`
   - `[REVIEW:album_id:Album Title:review text]` — renders `CadenceReviewCard`
   - `[SEARCH:query]` — triggers Spotify search, renders `CadenceSearchResultsCard`
4. **Batch ratings**: 3+ rate actions in one message render as `CadenceBatchRatingCard`
5. **Suggestion chips**: Context-aware follow-ups generated after each response
6. **Sound DNA Summary**: Separate Gemini call generates a 3-word sonic identity tagline, cached in UserDefaults

### Actions
- Rate albums (single or batch) — writes to `SoundScoreRepository.updateRating()`
- Draft reviews in user's voice — saves via `SoundScoreRepository.saveReview()`
- Search for albums not in catalog — calls `SpotifyService.searchAlbums()`
- Add search results to library — appends to `SoundScoreRepository.albums`

## Build

```bash
# Open in Xcode
open ios/SoundScore/SoundScore.xcodeproj

# Build from command line
xcodebuild -project ios/SoundScore/SoundScore.xcodeproj \
  -scheme SoundScore \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Requirements
# - Xcode 15+
# - iOS 17+ deployment target (uses SwiftUI onChange with new/old value syntax)
# - Swift 5.9+
# - No SPM dependencies — all networking via URLSession
```

## Testing

**0 test files — critical gap.**

No unit tests, integration tests, or UI tests exist for the iOS client.
All ViewModels, Services, and presentation helpers are untested.

## Known Issues (from audit)

| ID | Severity | Description |
|----|----------|-------------|
| ISSUE-007 | HIGH | `Secrets.swift` contains hardcoded Spotify and Gemini API keys in plaintext. Should be gitignored and use `.xcconfig` or a secrets manager. |
| ISSUE-008 | MEDIUM | `SoundScoreRepository` is a mutable singleton with `@Published var albums` — direct mutation of shared state from multiple screens. |
| ISSUE-009 | MEDIUM | `AuthManager` stores access/refresh tokens in `UserDefaults` (unencrypted). Should use Keychain. |
| ISSUE-010 | MEDIUM | `AlbumDetailViewModel` subscribes to repository publishers in `init` without cancellation guard — potential retain cycles. |
| ISSUE-011 | LOW | `ProfileViewModel.generateSoundDNA()` makes a raw Gemini API call with inline response decoding, duplicating `AIBuddyService` logic. |
| ISSUE-012 | LOW | `FeedItem.album` is a `var` — feed items mutated in-place for artwork enrichment. |
| ISSUE-013 | MEDIUM | No error retry UI — `errorMessage` is displayed but "Retry" only exists on `FeedScreen`. Other screens show errors without recovery. |
| ISSUE-014 | LOW | `SpotifyService` artwork cache is in-memory only — lost on app restart, causing re-fetches. |
| ISSUE-015 | MEDIUM | `OutboxStore` is in-memory — all pending operations lost on app termination. No CoreData/SQLite persistence. |
| ISSUE-023 | HIGH | 0% test coverage — no unit, integration, or UI tests. |
| ISSUE-024 | MEDIUM | `SeedData` contains 20 hardcoded albums with real Apple Music/Spotify artwork URLs that may change or break. |
| ISSUE-025 | LOW | `ContentView` creates `@StateObject` for `AuthManager.shared` and `SoundScoreRepository.shared` — wrapping singletons in `StateObject` is an anti-pattern. |
| ISSUE-028 | MEDIUM | `ThemeManager` uses `shared` singleton with `@Published` but is not an `@EnvironmentObject` in all views — some views access it directly via `ThemeManager.shared`. |
| ISSUE-029 | LOW | `buildTasteDNA()` is a global function in `PresentationHelpers.swift` doing genre aggregation, decade breakdown, and controversy detection — should be a method on a dedicated service. |

## Feature Parity with Android

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Feed (trending + activity) | Yes | Yes | iOS adds trending songs toggle and curated lists section |
| Log / Diary | Yes | Yes | iOS adds songs mode toggle with per-track log entries |
| Search / Discover | Yes | Yes | iOS merges Spotify results; Android is local-only |
| Lists | Yes | Yes | Feature parity |
| Profile | Yes | Yes | iOS adds Taste DNA (genre bars, AI tagline, controversial pick) |
| Album Detail | Yes | No | iOS-only: hero artwork, tracklist, per-song ratings, songs breakdown |
| AI Buddy (Cadence) | Yes | No | iOS-only: Gemini-powered chat with agentic actions |
| Settings | Yes | No | iOS-only: theme switcher, notifications, quiet hours, data export, delete account |
| Auth (login/signup) | Yes | No | iOS has dedicated AuthScreen; Android auto-authenticates in repository |
| Splash Screen | Yes | No | iOS-only: animated theme cycling splash |
| Spotify Integration | Yes | No | iOS-only: artwork enrichment, search merge, track fetching |
| Per-Track Ratings | Yes | No | iOS-only: rate individual songs within album detail |
| Offline Outbox | Yes | Yes | Both use in-memory outbox with idempotency keys |
| Theme System | 6 themes (swipeable) | Material3 (single dark) | iOS has 6 custom themes; Android uses stock Material3 |

---

*Last audited: 2026-03-19*
