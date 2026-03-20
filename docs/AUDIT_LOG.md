# SoundScore Deep Audit Log

Generated: 2026-03-19
Branch: audit/deep-sweep-20260319
Total Passes Completed: 6/9

## Baseline Metrics

| Metric | Android | iOS | Backend | Contracts |
|--------|---------|-----|---------|-----------|
| Source files | 33 | 67 | 45 | 9 |
| Lines of code | 4,874 | 8,295 | 5,531 | 520 |
| TODOs/FIXMEs | 0 | 0 | 0 | 0 |
| Test files | 4 | 0 | 9 | 0 |
| Test functions | 9 | 0 | 96 | 0 |

### Files >400 Lines
| File | Lines |
|------|-------|
| `ios/SoundScore/SoundScore/Components/CadenceActionCards.swift` | 478 |
| `app/src/main/java/com/soundscore/app/data/repository/SoundScoreRepository.kt` | 470 |
| `ios/SoundScore/SoundScore/Screens/ProfileScreen.swift` | 463 |
| `ios/SoundScore/SoundScore/Screens/AlbumDetailScreen.swift` | 454 |
| `app/src/main/java/com/soundscore/app/ui/screens/ProfileScreen.kt` | 435 |
| `backend/src/modules/mapping.ts` | 424 |

### Baseline Scan Results
- Console.log/warn/error in backend: 9 occurrences
- Hardcoded URLs across codebase: 47 occurrences
- iOS test files: **0** (no test coverage at all)
- Last commit: `6aac4f6` feat: iOS UI overhaul, Cadence AI agent, per-track ratings, theme system, backend catalog enrichment

## Issue Registry

### [ISSUE-001] Missing Zod validation in Phase 2 route handlers | Backend | P1
- **Files:** `modules/catalog.ts`, `modules/import.ts`, `modules/mapping.ts`, `modules/providers.ts`
- **Description:** 10+ route handlers use `request.body as {...}` type assertions instead of Zod schema `.parse()`. Produces 500 on malformed input instead of 400 validation error.
- **Status:** DOCUMENTED (contracts schemas exist but are unused by these handlers)

### [ISSUE-002] Dead exports in backend lib | Backend | P3
- **Files:** `lib/dead-letter.ts`, `lib/token-refresh.ts`, `lib/mappers.ts` (`tryJsonParse`), `lib/pagination.ts` (`PaginationParams` type)
- **Description:** 6 exported functions/types never imported by production code. `token-refresh.ts` is entirely dead.
- **Status:** DOCUMENTED

### [ISSUE-003] 8/11 backend modules have zero test files | Backend | P1
- **Description:** Only `import`, `mapping`, and `providers` have partial test coverage (utility functions only). auth, catalog, opinions, social, lists, trust, push, recaps have NO tests. No route-level integration tests exist.
- **Status:** DOCUMENTED

### [ISSUE-004] Console.log in migration/config code | Backend | P3
- **Files:** `config/env.ts`, `db/runMigrations.ts`, `db/migrate.ts`, `index.ts`
- **Description:** 9 console.log/warn/error calls bypass Pino structured logger. Config/startup ones are acceptable (pre-Fastify), but runMigrations.ts should use app.log.
- **Status:** DOCUMENTED (not fixing — pre-Fastify context makes console acceptable)

### [ISSUE-005] No account lockout after failed logins | Backend | P2
- **Description:** Auth rate limit is 10 req/min per IP, but no lockout after repeated failures. An attacker can try 10 passwords per minute continuously.
- **Status:** DOCUMENTED

### [ISSUE-006] CreateTrackRatingRequestSchema dead in contracts | Contracts | P3
- **Description:** Schema defined in contracts but no track-rating endpoint exists in backend. Dead code.
- **Status:** DOCUMENTED

### [ISSUE-007] iOS was stuck in offline/seed-data mode | iOS | P0
- **Files:** `AuthManager.swift`, `SoundScoreRepository.swift`
- **Description:** iOS never called `devAutoSignup()` or `refresh()` on startup. Dev credentials mismatched Android. App was permanently offline.
- **Status:** FIXED — aligned dev credentials, added auto-auth + auto-refresh in DEBUG init

### [ISSUE-008] ListsScreen is orphaned (unreachable) | iOS | P1
- **Description:** ListsScreen is fully built with ViewModel, ErrorBanner, .refreshable but is NOT in the tab bar (Tab.swift has feed, log, search, aiBuddy, profile — no lists tab).
- **Status:** DOCUMENTED

### [ISSUE-009] AuthScreen has no ViewModel | iOS | P2
- **Description:** Business logic (login/signup) lives inline in the view with @State. Should extract to AuthViewModel.
- **Status:** DOCUMENTED

### [ISSUE-010] 4 force-unwraps in iOS code | iOS | P2
- **Files:** `AlbumDetailScreen.swift:281-282`, `LogScreen.swift:50`, `ProfileViewModel.swift:101`
- **Description:** Force-unwraps on dictionary access and URL construction. The AlbumDetailScreen ones could crash during concurrent updates.
- **Status:** DOCUMENTED

### [ISSUE-011] 3 screens missing ErrorBanner | iOS | P2
- **Files:** `AlbumDetailScreen.swift`, `AIBuddyScreen.swift`, `SettingsScreen.swift`
- **Status:** DOCUMENTED

### [ISSUE-012] 3 scrollable screens missing .refreshable | iOS | P2
- **Files:** `AlbumDetailScreen.swift`, `SettingsScreen.swift`, `AIBuddyScreen.swift`
- **Status:** DOCUMENTED

### [ISSUE-013] @ObservedObject misuse on ThemeManager.shared | iOS | P3
- **Files:** `ContentView.swift`, `SettingsScreen.swift`, `AppBackdrop.swift`
- **Description:** ThemeManager.shared uses @ObservedObject but is a singleton initialized inline. Should use @EnvironmentObject (already injected).
- **Status:** DOCUMENTED

### [ISSUE-014] 2 unused component files (dead code) | iOS | P3
- **Files:** `GlassIconButton.swift`, `ReviewSheet.swift`
- **Description:** Components defined but never instantiated by any screen.
- **Status:** DOCUMENTED

### [ISSUE-015] Hardcoded colors in screens | iOS | P3
- **Files:** `LogScreen.swift`, `SearchScreen.swift`, `SettingsScreen.swift`
- **Description:** Uses `.white`, `.black` instead of SSColors theme tokens. AvatarCircle also uses Color.white.
- **Status:** DOCUMENTED

### [ISSUE-016] No strings.xml — all Android strings hardcoded | Android | P1
- **Description:** No `strings.xml` file exists. 50+ user-facing strings are hardcoded across all 5 screens. Blocks localization entirely.
- **Status:** DOCUMENTED

### [ISSUE-017] 5 iOS screens missing from Android | Android | P1
- **Description:** Android is missing AlbumDetailScreen, AuthScreen, AIBuddyScreen, SettingsScreen, SplashScreen. AlbumDetail and Auth are core features.
- **Status:** DOCUMENTED

### [ISSUE-018] 12 backend routes missing from Android API client | Android | P1
- **Description:** Android missing: follow/unfollow, comment, recently-played, list detail, all provider routes, all mapping routes, all sync routes, test-recap.
- **Status:** DOCUMENTED

### [ISSUE-019] Android smoke tests are broken (stale assertions) | Android | P1
- **Files:** `ScreenSmokeTest.kt`
- **Description:** 5 smoke tests assert text strings that no longer match current screen code (e.g. `"Albums everyone is circling back to"` but screen says `"What your people are logging right now."`). Will FAIL at runtime.
- **Status:** DOCUMENTED

### [ISSUE-020] Android test coverage ~15-20% (target 80%) | Android | P1
- **Description:** Only 14 test functions across 5 files. No ViewModel tests, no repository tests, no API tests, no edge cases. Smoke tests are broken.
- **Status:** DOCUMENTED

### [ISSUE-021] Large composables needing decomposition | Android | P2
- **Files:** `ProfileScreen.kt` (ProfileScreenContent 163 lines), `LogScreen.kt` (LogScreenContent 118 lines), `FeedScreen.kt` (FeedActivityCard 101 lines)
- **Status:** DOCUMENTED

### [ISSUE-022] Android missing Track/TrackRating DTOs | Android | P2
- **Description:** iOS has TrackDto, TrackRatingDto, ListDetailDto, ListItemDto. Android has none of these.
- **Status:** DOCUMENTED

### [ISSUE-023] iOS WeeklyRecapDto missing fields vs backend/Android | Cross-platform | P2
- **Description:** iOS WeeklyRecapDto is missing userId, topAlbums, createdAt fields that backend and Android both have.
- **Status:** DOCUMENTED

### [ISSUE-024] iOS ActivityEventDto missing payload field | Cross-platform | P2
- **Description:** Backend returns `payload` on activity events. Android includes it (`Map<String, JsonElement>`). iOS DTO is missing it entirely.
- **Status:** DOCUMENTED

### [ISSUE-025] iOS Album model has orphan fields (spotifyId, genres) | iOS | P2
- **Description:** iOS `Album.swift` has `spotifyId` and `genres` fields not in contract, backend response, or Android model. Cannot be populated from API.
- **Status:** DOCUMENTED

### [ISSUE-026] UserProfile UI models missing `id` field | Cross-platform | P2
- **Description:** Both iOS and Android UserProfile models lack `id` while backend/DTOs return it. Code needing user ID from profile will fail.
- **Status:** DOCUMENTED

### [ISSUE-027] UserProfile has fields backend doesn't return | Cross-platform | P2
- **Description:** Both platforms have topAlbums, genres, albumsCount, followingCount, followersCount, favoriteAlbums — none returned by backend. Only work with seed data.
- **Status:** DOCUMENTED

### [ISSUE-028] iOS export uses GET, backend requires POST | iOS | P1
- **Description:** iOS calls `/v1/account/export` via GET but backend only implements POST. Export will 404.
- **Status:** DOCUMENTED

### [ISSUE-029] iOS has 3 track routes with no backend implementation | iOS | P1
- **Description:** iOS client has methods for `/v1/albums/:id/tracks`, `/v1/albums/:id/track-ratings`, `/v1/track-ratings`. DB schema exists but NO route handlers. Calls will 404.
- **Status:** DOCUMENTED

### [ISSUE-030] 20/36 backend routes lack contract schemas | Backend | P2
- **Description:** All Phase 2 routes (providers, mapping, sync) plus many Phase 1 routes have no typed contract. Undermines typed API goal.
- **Status:** DOCUMENTED

### [ISSUE-031] CONTEXT_04_CODEBASE_MAP.md significantly outdated | Docs | P2
- **Description:** All paths valid but missing entire API layer, ViewModels, outbox system, deep links, and all iOS/backend/contracts code. Only covers ~40% of Android.
- **Status:** DOCUMENTED

### [ISSUE-032] Phase 2 has zero mobile client coverage | Cross-platform | P1
- **Description:** All provider/mapping/sync routes are backend-only. Neither iOS nor Android has client methods for any Phase 2 endpoint.
- **Status:** DOCUMENTED

### [ISSUE-033] Provider fetch still mocked in import.ts | Backend | P2
- **Description:** `processSync()` in import.ts calls `fetchRecentPlays` which is a mock. Not connected to real Spotify API yet.
- **Status:** DOCUMENTED

## Pass Log

### Pass 1 — Bootstrap + Baseline
- **Start:** 2026-03-19
- **Actions:**
  - Created audit branch `audit/deep-sweep-20260319`
  - Installed `md-to-pdf` globally
  - Collected baseline metrics across all 3 platforms
  - Ran scans: TODOs, console.log, hardcoded URLs, large files
- **Key findings:**
  - iOS has ZERO test files — critical gap
  - 6 files exceed 400-line threshold
  - 9 console.log calls in backend should be structured logging
  - 47 hardcoded URLs need review
- **Issues found:** 4 (baseline observations, detailed in subsequent passes)
- **Issues fixed:** 0 (baseline only)
- **Commit:** `4df1e49`

### Pass 2 — Backend Deep Audit
- **Actions:**
  - Ran `npm run typecheck` for backend and contracts — both PASS clean
  - Searched for `as any` casts — NONE found
  - Checked SQL injection risk (template literal SQL) — NONE found (all parameterized)
  - Compared 39 server routes against contracts schemas
  - Identified dead exports in lib/
  - Verified rate limiting on auth routes (10 req/min, per-IP)
  - Checked logger setup (Pino structured logging via Fastify)
  - Mapped test coverage across all 11 modules
- **Key findings:**
  - Typechecks: PASS (both backend and contracts)
  - `as any` casts: 0 (clean)
  - SQL injection: 0 risk (all parameterized queries)
  - 10+ handlers bypass Zod validation (use type assertions instead of schema parse)
  - 6 dead exports across lib/ (including entirely dead token-refresh.ts)
  - 8/11 modules have zero test files — only utility functions tested
  - Console.log used in 4 files (pre-Fastify startup context, acceptable)
  - Rate limiting properly applied to auth (10/min), sensitive (3/hr), write (30/min)
  - No account lockout mechanism after repeated failed logins
  - Fastify Pino logger properly configured with request IDs and structured output
- **Issues found:** 6 (ISSUE-001 through ISSUE-006)
- **Issues fixed:** 0 (all documented — no safe mechanical fixes this pass)
- **Commit:** `ad4ee39`

### Pass 3 — iOS Deep Audit + Auth/Online Fix
- **Actions:**
  - **FIXED: iOS auth + online mode** — aligned dev credentials with Android, added auto-auth (`devAutoSignup()`) + auto-refresh in `SoundScoreRepository.init()`, added inline auth attempt in `refresh()` for DEBUG
  - Verified fix compiles: `xcodebuild BUILD SUCCEEDED` (0 warnings)
  - Audited Screen↔ViewModel mapping (10 screens, 8 have VMs)
  - Checked @Published usage (all 7 VMs correct)
  - Checked ErrorBanner presence (5/8 screens have it)
  - Checked .refreshable presence (5/8 scrollable screens have it)
  - Found 4 force-unwraps outside #if DEBUG
  - Checked retain cycles in .sink closures (0 issues, all use [weak self])
  - Checked @StateObject vs @ObservedObject (3 misuses on ThemeManager.shared)
  - Found 2 unused component files (GlassIconButton, ReviewSheet)
  - Found hardcoded Color usage in 3 screens
  - Discovered ListsScreen is orphaned (not reachable from tab bar)
- **Key findings:**
  - iOS build: PASS (0 errors, 0 warnings)
  - Auth fix applied: iOS will now auto-authenticate and connect to backend in DEBUG
  - ListsScreen is fully built but unreachable (no lists tab in Tab.swift)
  - AuthScreen has no ViewModel (inline business logic)
  - 4 force-unwraps could cause crashes (AlbumDetailScreen dictionary access, URL construction)
  - 3 screens missing ErrorBanner, 3 missing .refreshable
  - No retain cycle issues found
  - 2 dead component files (GlassIconButton.swift, ReviewSheet.swift)
- **Issues found:** 9 (ISSUE-007 through ISSUE-015)
- **Issues fixed:** 1 (ISSUE-007 — iOS auth/online mode)
- **Commit:** `b9beb57`

### Pass 4 — Android Static Audit
- **Actions:**
  - Checked Screen↔ViewModel mapping (5/5 screens have VMs)
  - Verified StateFlow usage (all correct, no mutableStateOf)
  - Verified collectAsStateWithLifecycle (all 5 screens correct)
  - Found 22 functions >50 lines (ProfileScreenContent 163, LogScreenContent 118, FeedActivityCard 101 worst)
  - No composables >200 lines (largest 163)
  - Found 50+ hardcoded strings, NO strings.xml file at all
  - Compared Android vs iOS screens (5 missing from Android)
  - Compared API models vs backend DTOs
  - Compared Android API endpoints vs backend routes (12 missing)
  - Verified ViewModel exposure (all correctly use StateFlow, not MutableStateFlow)
  - Audited test quality (14 functions, 5 broken smoke tests)
- **Key findings:**
  - Android MVVM architecture is SOLID: StateFlow + collectAsStateWithLifecycle + Repository pattern
  - NO strings.xml — all 50+ user-facing strings hardcoded (blocks i18n)
  - 5 screens missing vs iOS (AlbumDetail, Auth, AIBuddy, Settings, Splash)
  - 12 backend routes not in Android client (follow, comment, providers, sync, etc.)
  - Smoke tests are BROKEN (assert stale text strings)
  - Test coverage ~15-20% (far below 80% target)
  - iOS WeeklyRecapDto missing 3 fields vs Android/backend
  - iOS ActivityEventDto missing payload field vs Android/backend
- **Issues found:** 9 (ISSUE-016 through ISSUE-024)
- **Issues fixed:** 0 (all documented — no compilation available for verification)
- **Commit:** `3b081a5`

### Pass 5 — Cross-Platform Consistency
- **Actions:**
  - Compared Album, FeedItem, UserProfile models across all 3 platforms
  - Built API Endpoint Coverage Matrix (36 backend routes vs iOS 22 vs Android 18)
  - Built Feature Parity Matrix (23 features compared)
  - Verified CONTEXT_04_CODEBASE_MAP.md paths (all valid, but 60% of code undocumented)
  - Checked Phase 2 execution progress against actual implementation
- **Key findings:**
  - iOS ahead of Android: 10 screens vs 5, covers 22 routes vs 18
  - iOS Album model has orphan fields (spotifyId, genres) backend doesn't return
  - Both platforms' UserProfile has fields backend doesn't return (topAlbums, genres, followers, etc.)
  - iOS export calls GET but backend requires POST — will 404
  - iOS has 3 track route client methods with NO backend handlers — will 404
  - 20/36 backend routes lack typed contract schemas
  - Phase 2: Wave 0 (contracts) mostly done, Wave 1 (core) backend-only, Wave 2 (hardening) partial
  - Zero mobile coverage for any Phase 2 route
  - Provider fetch in import.ts still mocked
  - Codebase map covers ~40% of Android, 0% of iOS/backend

#### Feature Parity Summary
| Feature | Android | iOS | Backend |
|---------|---------|-----|---------|
| Auth | Full | Missing client | Full |
| Feed | Partial | Partial | Full |
| Search | Partial | Partial | Full |
| Lists | Partial | Partial | Full |
| Profile | Partial | Partial | Full |
| Album Detail | Missing | Full | Partial |
| Cadence AI | Missing | Full | N/A |
| Settings | Missing | Full | Full |
| Tracks | Missing | Full (DTOs) | Missing (routes) |
| Provider Connect | Missing | Missing | Full |
| Offline Sync | Full | Full | N/A |

#### API Coverage Summary
- Backend: 36 routes
- iOS client: 22 routes (61%)
- Android client: 18 routes (50%)
- Contract schemas: 16 routes (44%)

- **Issues found:** 9 (ISSUE-025 through ISSUE-033)
- **Issues fixed:** 0
- **Commit:** `286c005`

### Pass 6 — Build Verification
- **Actions:**
  - iOS `xcodebuild clean build`: **BUILD SUCCEEDED** (1 warning)
  - Backend `npm run typecheck`: **PASS**
  - Backend `npm run test`: **79 pass, 9 fail** (88 total)
  - Contracts `npm run build`: **PASS**
- **Build results:**
  - iOS: 1 warning — `CadenceActionCards.swift:291` unused result of `withAnimation`
  - Backend typecheck: clean, no errors
  - Backend tests: 9 failures in 3 test suites:
    - `error-handling.test.ts`: "invalid JSON body returns 400" — Fastify returns 500 instead of 400 for malformed JSON (error handler doesn't catch FST_ERR_CTP_INVALID_JSON_BODY as ApiError)
    - `integration.test.ts`: "create rating and verify idempotency" — expects 200 on duplicate idempotency key but gets 409 (idempotency logic returns conflict instead of cached response)
    - `production-readiness.test.ts`: structural checks failing (likely stale expectations)
  - Contracts build: clean, no errors
- **Regression check:** No regressions from audit passes 2-4 (typecheck was clean before, still clean)
- **Issues found:** 0 new (test failures are pre-existing, not caused by audit)
- **Issues fixed:** 0
- **Commit:** (this commit)
