# SoundScore — Issues and Tackle Plan

**Purpose:** Pull together all known issues and problems (GitHub, codebase, docs) and lay out a single way to tackle everything. **No work is done in this doc—planning only.**

**Next step:** Phase 1A and Phase 1B are implemented (backend + Postgres/Redis, mobile remote+outbox, push, recaps, CI). The **next phase**—stabilization and M1 closure so external work can branch cleanly—is in **[docs/NEXT_PHASE_PLAN.md](NEXT_PHASE_PLAN.md)**.

---

## 1. GitHub issues (pulled via API)

- **Repo:** `https://github.com/madhavcodez/SoundScoreV0.1` (branch: `UI_beta`, `main`).
- **Pulled:** Issues fetched via GitHub REST API with PAT (see section 6 for re-pull commands).
- **Totals:** **100 issues** — **56 open**, **44 closed**.
- **By milestone:**
  - **M1 Provider-Free Beta:** 74 issues (42 open, 32 closed).
  - **M2 Provider-Limited Beta (Spotify):** 25 issues (13 open, 12 closed).
  - **M3 Multi-Provider Beta:** 1 issue (1 open).

---

## 2. Inventory of issues and problems

### 2.1 In-code TODOs (UI placeholders)

| Location | What’s missing |
|----------|----------------|
| `ListsScreen.kt` ~L54 | “Create your first list” button: `onClick = { /* TODO */ }` |
| `ProfileScreen.kt` ~L217–218 | “Share profile card” and “Export data” buttons: both `onClick = { /* TODO */ }` |

These are three explicit TODOs; no other `TODO`/`FIXME`/`HACK` in Kotlin/XML.

### 2.2 Product / roadmap gaps (from CONTEXT_06 + deep research)

- **Provider-free beta:** Manual logging + social + lists + recaps, no Spotify/Apple required. Not implemented (no backend, no auth).
- **Trust stack:** Export, account deletion, provider disconnect. Designed in docs; not built (Export/Share are UI TODOs only).
- **Spotify risk:** Dev Mode limits (5 users, Premium-only, etc.) and Extended quota (250k MAU, org-only). Strategy: reduce dependency; MusicBrainz/ListenBrainz and “Spotify optional” path.
- **Operational excellence:** Status page, incident comms, export/delete as product—all in strategy, not yet implemented.

### 2.3 Architecture / backend (from CONTEXT_02)

- **No backend yet.** Domain modules (Identity, Catalog, Listening Import, Ratings, Social, Feed, Lists, Recaps, Trust, etc.) are specified but not built.
- **No auth.** Sign up / login / refresh and provider connect/disconnect are designed, not implemented.
- **No persistence.** App uses `DummyData.kt` / in-memory state only; no Room, no API client, no offline outbox.
- **API surface:** Endpoint set is listed (auth, providers, catalog, log, social, lists, recaps, trust); no implementation.

### 2.4 Mobile app (from CONTEXT_03 + CONTEXT_04)

- **Data source:** All screens use `SeedData`; no repository layer, no server state, no caching.
- **State management:** No ViewModels/caching/retry; no idempotency keys or optimistic updates.
- **Offline:** No local DB, no outbox, no conflict policy.
- **Navigation:** No stack-per-tab detail screens, no deep links / App Links.
- **Share cards:** Designed (server-side + CDN); not implemented (Share profile/Export are TODOs).
- **Push:** FCM and notification types specified; not implemented.
- **Performance:** Budgets (cold start, feed scroll, image load, write response) are documented; not yet measured or enforced.

### 2.5 Conventions and compliance (from CONTEXT_05)

- **Spotify (if integrated):** Privacy policy, disconnect/delete, attribution/link-back—all required, not implemented.
- **Security:** Keystore for tokens, TLS, rate limits, audit—design only.
- **API conventions:** Cursor pagination, idempotency keys, versioning, error envelope—for when backend exists.
- **Testing:** Unit, integration, UI smoke, observability—strategy only; no tests in repo yet.

### 2.6 Linting / build

- **Linter:** No linter errors reported under `app/src/main/java`.

---

## 3. How to tackle everything (phased)

### Phase 0 — Immediate (no backend)

- **Tackle:** The three UI TODOs.
  - **ListsScreen:** Wire “Create your first list” to a no-op or a local dialog/screen (e.g. “Create list” modal with name only, in-memory list) so the button isn’t dead.
  - **ProfileScreen:** Wire “Share profile card” and “Export data” to placeholders: e.g. share a simple text/URL or “Export” toast, with a comment that real implementation will be server-side share card + trust stack.
- **Outcome:** No dead buttons; clear placeholders for later backend/trust work.

### Phase 1 — Provider-free beta (backend + mobile wiring)

- **Backend:** Implement minimal modular monolith: auth (sign up/login/refresh), canonical catalog (e.g. MusicBrainz or manual album entity), ratings/reviews, lists, activity feed, trust (export + delete + disconnect stub).
- **Mobile:** Replace `SeedData` with repository layer (API client + optional Room cache). Add ViewModels, loading/error states, idempotency keys for writes, optimistic updates where it makes sense.
- **Trust:** Real “Export data” (e.g. CSV/JSON snapshot) and “Delete account” from backend; “Share profile card” can still be placeholder or simple share until recaps/share cards exist.
- **Outcome:** App works without any provider; logging, ratings, lists, feed, and trust are real.

### Phase 2 — Provider-limited beta (Spotify optional)

- **Backend:** Provider adapter interface; Spotify adapter (OAuth, token storage, revoke, fetch recent plays). Catalog mapping (Spotify ID → canonical album). Comply with Spotify policy (disconnect, delete, attribution).
- **Mobile:** “Connect Spotify” flow; show “Listen on Spotify” where required; store tokens in Keystore.
- **Outcome:** Core still works without Spotify; optional connect for import and catalog.

### Phase 3 — Multi-provider + recaps and share cards

- **Backend:** Apple Music (and/or ListenBrainz) adapter; recap job + share card generation (server-side); CDN for share cards; deep links for albums/lists/profiles/recaps.
- **Mobile:** App Links; share sheet with image + link; push (FCM) for recap-ready and social events.
- **Outcome:** Multi-provider, recaps, and shareable cards as in roadmap.

### Phase 4 — Hardening and scale

- **Operational:** Status page, incident comms, monitoring (latency, queue lag, errors).
- **Performance:** Hit mobile performance budgets; add tests (unit, API contract, UI smoke).
- **Scale:** Feed fan-out-on-write when needed; rate limits, moderation, abuse controls.

---

## 4. Suggested order of work (within Phase 0)

1. **ListsScreen** — “Create your first list”: add local action (dialog or new screen) so the button does something; keep data in-memory or stub until Phase 1.
2. **ProfileScreen** — “Share profile card”: e.g. share current profile as text/URL or “Coming soon” toast; document that real implementation is server-side share card in Phase 3.
3. **ProfileScreen** — “Export data”: e.g. toast “Export coming when backend is ready” or, if you add a minimal export API in Phase 1, wire it here first.

---

## 5. Open GitHub issues (by milestone)

All **56 open** issues, grouped by milestone. Epics are parent issues; tasks follow the pattern Contract/API (.1) → Core implementation (.2) → Hardening (.3). **Note:** EPIC-M01 title references “React Native + Expo”; this repo is **Android native (Kotlin/Compose)**—treat as “Mobile App Foundation” for Android.

### M1 Provider-Free Beta (42 open)

| # | Title |
|---|--------|
| 53 | EPIC-M01 Mobile App Foundation (React Native + Expo + native escape hatches) |
| 67–69 | TASK-M01.1 Contract/data-model/API alignment → Core implementation → Hardening |
| 54 | EPIC-M02 Navigation, Deep Links, and Share Entry Flows |
| 70–72 | TASK-M02.1 → M02.2 → M02.3 |
| 55 | EPIC-M03 Offline Cache + Outbox Sync Engine |
| 73–75 | TASK-M03.1 → M03.2 → M03.3 |
| 56 | EPIC-M04 Mobile Performance Budgets + Reliability |
| 76–78 | TASK-M04.1 → M04.2 → M04.3 |
| 57 | EPIC-M05 Push Notifications + User Controls |
| 79–81 | TASK-M05.1 → M05.2 → M05.3 |
| 61 | EPIC-M09 Ratings/Reviews/Drafts + Conflict Handling |
| 91–93 | TASK-M09.1 → M09.2 → M09.3 |
| 62 | EPIC-M10 Social Graph + Activity Feed Ranking |
| 94–96 | TASK-M10.1 → M10.2 → M10.3 |
| 63 | EPIC-M11 Lists + Share Cards + Distribution |
| 97–99 | TASK-M11.1 → M11.2 → M11.3 |
| 64 | EPIC-M12 Recaps + Growth Loops |
| 100–102 | TASK-M12.1 → M12.2 → M12.3 |
| 65 | EPIC-M13 Trust Stack + Security + Compliance |
| 103–104 | TASK-M13.1 Contract/API → M13.2 Core implementation (M13.3 is M2) |
| 66 | EPIC-M14 Mobile CI/CD + Observability + Release Ops |
| 106–107 | TASK-M14.1 → M14.2 (M14.3 is M3) |

### M2 Provider-Limited Beta – Spotify (13 open)

| # | Title |
|---|--------|
| 58 | EPIC-M06 Identity/Auth + Provider Connect UX/API |
| 82–84 | TASK-M06.1 → M06.2 → M06.3 |
| 59 | EPIC-M07 Catalog + ID Mapping |
| 85–87 | TASK-M07.1 → M07.2 → M07.3 |
| 60 | EPIC-M08 Listening Import + Dedup Pipeline |
| 88–90 | TASK-M08.1 → M08.2 → M08.3 |
| 105 | TASK-M13.3 Hardening (Trust Stack) |

### M3 Multi-Provider Beta (1 open)

| # | Title |
|---|--------|
| 108 | TASK-M14.3 Hardening (security/perf/test/observability/scale) |

---

## 6. Phase ↔ GitHub milestone mapping

| Doc phase | GitHub milestone | Open issues (examples) |
|-----------|------------------|------------------------|
| Phase 0 (UI TODOs) | — | In-code only; no GitHub issue yet |
| Phase 1 | M1 Provider-Free Beta | #53–66 (epics), #67–107 (tasks under M1) |
| **Phase 1B Stabilization** | M1 closure | Tracks A–F in [NEXT_PHASE_PLAN.md](NEXT_PHASE_PLAN.md); close or defer #67–107 |
| Phase 2 | M2 Provider-Limited Beta (Spotify) | #58–60, #82–90, #105 |
| Phase 3 | M3 Multi-Provider Beta | #108; plus future Apple/ListenBrainz epics |
| Phase 4 | Hardening tasks (.3) across M1–M3 | e.g. #69, #72, #75, #78, #81, #93, #96, #102, #105, #108 |

Re-pull issues (use a PAT or `gh auth login`):

```bash
# With PAT (replace YOUR_PAT):
curl -s -H "Authorization: Bearer YOUR_PAT" -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/madhavcodez/SoundScoreV0.1/issues?state=all&per_page=100"

# With gh CLI:
gh issue list --repo madhavcodez/SoundScoreV0.1 --state all --limit 100
```

---

*Last updated: GitHub issues pulled via API (56 open, 44 closed). Doc also uses PROJECT_OVERVIEW, CONTEXT_01–07, deep-research-report.md, codebase grep for TODO/FIXME, and read_lints. No code or config changes were made.*
