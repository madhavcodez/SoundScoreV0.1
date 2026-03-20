# SoundScore Deep Audit Log

Generated: 2026-03-19
Branch: audit/deep-sweep-20260319
Total Passes Completed: 3/9

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
- **Commit:** (this commit)
