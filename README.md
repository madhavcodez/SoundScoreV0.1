# SoundScore

> Letterboxd for music — log, rate, review, discover.

SoundScore is a cross-platform music logging and social discovery app. Rate albums, write reviews, build lists, follow friends, and get AI-powered recommendations — all from native Android and iOS apps backed by a shared TypeScript API.

**This is an open-source sandbox project.** I built it as a learning exercise and creative outlet. If you find it interesting, want to pick up where I left off, or want to contribute — go for it.

---

## Screenshots

### iOS App

<p align="center">
  <img src="docs/screenshots/showcase/01-auth-screen.png" width="180" alt="Welcome Screen" />
  <img src="docs/screenshots/showcase/02-feed.png" width="180" alt="Feed — Trending & Collections" />
  <img src="docs/screenshots/showcase/03-search.png" width="180" alt="Discover — Genre Browsing" />
  <img src="docs/screenshots/showcase/05-album-detail.png" width="180" alt="Album Detail & Rating" />
</p>

<p align="center">
  <img src="docs/screenshots/showcase/04-search-results.png" width="180" alt="Search Results" />
  <img src="docs/screenshots/showcase/06-social-feed.png" width="180" alt="Social Feed — Activity from Friends" />
</p>

---

## What's Built

### Core Features (Working)
- **Album ratings** — 0-6 scale with half-star precision
- **Reviews** — write and edit reviews with optimistic concurrency
- **Social feed** — follow users, see what friends are logging, react and comment
- **Curated lists** — create and share album collections
- **Discover** — browse by genre, search albums, see trending
- **Weekly recaps** — auto-generated listening insights
- **Push notifications** — follow alerts, reactions, comments
- **Theming** — multiple color themes (Amethyst, Emerald, Midnight)
- **GDPR data export** — full account data export and deletion

### AI & Recommendations
- Gemini-powered recommendation engine (backend wired, mobile pending)
- Genre-based discovery with curated browsing categories

### Phase 2 (In Progress — Backend Only)
- Spotify OAuth integration
- Listening history import and sync
- Provider-agnostic canonical album mapping

---

## Tech Stack

| Layer | Tech |
|-------|------|
| **Android** | Kotlin, Jetpack Compose, StateFlow, Hilt, OkHttp, Room |
| **iOS** | Swift, SwiftUI, Combine, URLSession |
| **Backend** | TypeScript, Fastify 4.x, Pino, Zod |
| **Database** | PostgreSQL 15 (full-text search via tsvector/GIN) |
| **Cache** | Redis (sessions, feed fan-out, rate limiting) |
| **Infra** | Docker Compose, Railway |

---

## Architecture

```
         Android (Kotlin)          iOS (Swift)
         Jetpack Compose            SwiftUI
              \                      /
               \                    /
                +--  HTTPS /v1/*  --+
                |                   |
           +----v-------------------v----+
           |     Backend (TypeScript)    |
           |     Fastify + Pino + Zod   |
           +--+------+------+------+----+
              |      |      |      |
          Postgres  Redis  Spotify  MusicBrainz
```

- **36 API routes** across 11 domain modules
- Shared Zod contracts between backend and clients
- Idempotency-key enforcement on all mutations
- Redis-cached feed, profile, and session data

---

## What's Here

```
SoundScorev0.1/
├── app/                    # Android app (Kotlin + Compose)
│   └── src/main/java/
│       ├── data/           #   Repository, API client, DTOs
│       └── ui/             #   Screens, ViewModels, theme
├── ios/                    # iOS app (Swift + SwiftUI)
│   └── SoundScore/
│       ├── Screens/        #   10 screens + ViewModels
│       ├── Components/     #   Reusable UI components
│       └── Theme/          #   Color themes
├── backend/                # Fastify API server
│   └── src/
│       ├── modules/        #   11 domain modules
│       ├── lib/            #   18 shared utilities
│       └── db/             #   Schema migrations
├── packages/contracts/     # Shared Zod API schemas
├── docs/                   # Architecture docs, audit logs
└── docker-compose.yml      # Local Postgres + Redis
```

---

## Getting Started

### Prerequisites
- Node.js 20+
- Docker (for Postgres + Redis)
- Xcode 16+ (for iOS)
- Android Studio (for Android)

### Backend

```bash
docker compose up -d
npm install
npm run migrate --workspace backend
npm run dev --workspace backend
```

Server runs at `http://localhost:8080`.

### iOS

Open `ios/SoundScore/SoundScore.xcodeproj` in Xcode, select a simulator, and hit Run. The app auto-authenticates against the local backend in debug mode.

### Android

```bash
./gradlew installDebug
```

Or open the project in Android Studio and run on a device/emulator.

---

## Stats

| | Android | iOS | Backend |
|---|---------|-----|---------|
| **Source files** | 33 | 67 | 45 |
| **Lines of code** | ~4,900 | ~8,300 | ~5,500 |
| **API routes wired** | 18 | 22 | 36 |

---

## Contributing

This started as a solo sandbox project. If you want to pick it up, extend it, or use it as a foundation for something — feel free.

Some areas that could use work:
- [ ] Android parity with iOS (5 screens missing)
- [ ] Phase 2 Spotify integration on mobile clients
- [ ] Test coverage (currently backend-only, ~96 tests)
- [ ] CI/CD pipeline hardening

### Branch Strategy
- `main` — stable
- `feat/<description>` — feature branches
- `fix/<description>` — bug fixes

### Commit Format
```
<type>: <description>
```
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

---

## Related

- **[SoundScore Web (Legacy)](https://github.com/madhavcodez/SoundScore)** — the original 2025 web app prototype (React + Express + MongoDB). Archived as a reference.

---

## License

MIT
