# SoundScore Deep Audit Log

Generated: 2026-03-19
Branch: audit/deep-sweep-20260319
Total Passes Completed: 2/9

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
- **Commit:** (this commit)
