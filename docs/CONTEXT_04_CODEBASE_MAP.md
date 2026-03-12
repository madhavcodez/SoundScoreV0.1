# Codebase Map

Use this when adding a feature, refactoring, or finding where to change code. All paths are under `app/src/main/` unless noted.

---

## Package layout

- **Root:** `com.soundscore.app`
- **Entry points:** `MainActivity.kt`, `SoundScoreApp.kt` (Compose root, nav, bottom bar).
- **data.model:** `DummyData.kt` — data classes and `SeedData`; replace with Room/network models and repositories when wiring backend.
- **ui.screens:** One Kotlin file per main screen.
- **ui.components:** Reusable Composables.
- **ui.theme:** Colors, typography, theme.
- **ui.navigation:** Screen sealed interface and tab list.

---

## Screens (and files)

| Screen | File | Description |
|--------|------|-------------|
| Feed | `java/.../ui/screens/FeedScreen.kt` | LazyColumn of feed items (username, action, album, rating, snippet, likes, time); uses `SeedData.feedItems`. |
| Log | `java/.../ui/screens/LogScreen.kt` | "Recently played" grid (albums + star rating); "Write later queue" section; ratings held in mutable state. |
| Search | `java/.../ui/screens/SearchScreen.kt` | Search UI; currently uses seed data. |
| Lists | `java/.../ui/screens/ListsScreen.kt` | Lists surface; placeholder/seed. |
| Profile | `java/.../ui/screens/ProfileScreen.kt` | User profile: handle, bio, counts, top albums, genres; uses `SeedData.myProfile`. |

Navigation: `AppNavigation.kt` defines sealed `Screen` (Feed, Log, Search, Lists, Profile) with labels and icons. `SoundScoreApp.kt` builds `NavHost` with `composable<Screen.Feed>` etc. and `FloatingNavigationBar` with `Screen.all`.

---

## Data models (current)

**File:** `java/.../data/model/DummyData.kt`

- **Album:** `id`, `title`, `artist`, `year`, `artColors` (list of `Color` for gradient placeholder), `avgRating`, `logCount`.
- **FeedItem:** `id`, `username`, `action`, `album`, `rating`, `reviewSnippet?`, `likes`, `comments`, `timeAgo`, `isLiked`.
- **UserProfile:** `handle`, `bio`, `logCount`, `reviewCount`, `listCount`, `topAlbums` (list of Pair<Album, Float>), `genres`, `avgRating`.
- **SeedData:** object with `albums`, `feedItems`, `logInitialRatings`, `myProfile`.

When you add a backend: replace with Room entities or DTOs + repositories; keep or mirror these shapes for UI binding.

---

## Theme

- **Color.kt:** `DarkBase`, `DarkSurface`, `DarkElevated`; `GlassBg`, `GlassBorder`, `GlassHeavy`, `FeedItemBorder`; `ChromeLight/Medium/Dim/Faint`; `ElectricBlue`, `ElectricBlueGlow`, `ElectricBlueDim`; `TextPrimary/Secondary/Tertiary`; `Destructive`, `Success`; `AlbumColors` (purple, teal, pink, blue, gold, indigo as gradient pairs).
- **Theme.kt:** MaterialTheme setup (dark theme, colors, shapes).
- **Type.kt:** Typography definitions.

Use these tokens for new UI so the app stays consistent.

---

## Reusable components

- **GlassCard.kt:** Liquid-glass style card: optional tint, corner radius, border, optional onClick; used for bottom nav and feed cards.
- **StarRating.kt:** Star rating input/display.
- **AlbumArtPlaceholder.kt:** Placeholder for album art (e.g. gradient from `AlbumColors`).
- **SoundScoreButton.kt:** Primary button styling.

Prefer these (or extend them) instead of raw Material3 when the design matches.

---

## Build and manifest

- **app/build.gradle.kts:** Compose BOM, Material3, Navigation Compose, Coil, kotlinx.serialization. minSdk 26, targetSdk 35. No backend or auth dependencies yet.
- **AndroidManifest.xml:** `INTERNET` permission; single `MainActivity` with launcher intent; theme `Theme.SoundScore`.

---

## "Add X → edit Y" quick reference

- **New main screen/tab:** Add a new `Screen` object in `AppNavigation.kt` (label, icons). Add `composable<Screen.NewTab>` in `SoundScoreApp.kt` and include in `Screen.all` (or the list passed to `FloatingNavigationBar`). Create `NewScreen.kt` in `ui.screens`.
- **New data model for API:** Add in `data.model` (e.g. DTO or Room entity); use in screens or ViewModels. Later add repository and optional local DB.
- **New reusable UI block:** Add in `ui.components`; use theme colors and types from `ui.theme`.
- **New color or type token:** Add in `Color.kt` or `Type.kt`; use in theme and components.
- **Deep link for a screen:** Add intent filter in manifest and handle in Activity; parse ID and navigate to the right composable with arguments (e.g. album ID, list ID).
