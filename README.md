<div align="center">

<img src="docs/images/hero.svg" alt="SoundScore — Letterboxd for music" width="100%"/>

[![iOS](https://img.shields.io/badge/iOS-SwiftUI-4FC3F7?style=flat-square&logo=apple&logoColor=white)](#-getting-started)
[![Android](https://img.shields.io/badge/Android-Jetpack%20Compose-1ED760?style=flat-square&logo=android&logoColor=white)](#-getting-started)
[![Backend](https://img.shields.io/badge/Fastify-4.x-000000?style=flat-square&logo=fastify)](#-architecture)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?style=flat-square&logo=typescript&logoColor=white)](#-tech-stack)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?style=flat-square&logo=postgresql&logoColor=white)](#-architecture)
[![Redis](https://img.shields.io/badge/Redis-cache%20%2B%20fanout-DC382D?style=flat-square&logo=redis&logoColor=white)](#-architecture)
[![Gemini](https://img.shields.io/badge/Gemini-recommendations-B388FF?style=flat-square&logo=google&logoColor=white)](#-feature-spotlights)
[![License: MIT](https://img.shields.io/badge/License-MIT-FFA726?style=flat-square)](#-license)
[![Open Source](https://img.shields.io/badge/Status-Open%20Sandbox-1ED760?style=flat-square)](#-contributing)

**Log what you listen to · rate in half-stars · follow friends · discover new sound.**

[Overview](#-overview) · [Screens](#-ios-screens) · [Capabilities](#-capabilities) · [Architecture](#-architecture) · [Spotlights](#-feature-spotlights) · [Tech](#-tech-stack) · [Get started](#-getting-started) · [Contribute](#-contributing)

</div>

---

## 🎯 Overview

**SoundScore** is a cross-platform music logging and social discovery app — think _Letterboxd, but for albums_.

Rate albums on a real **0–6 scale with half-star precision**. Write reviews. Build curated lists. Follow friends and react to what they're spinning. Get **Gemini-powered recommendations** based on what you actually rate. All delivered through **native iOS + Android clients** backed by a single **TypeScript / Fastify** API and shared **Zod** contracts.

> This is an **open-source sandbox project.** Built as a learning exercise and creative outlet. If you find it interesting, want to pick up where I left off, or want to contribute — go for it.

<div align="center">

| Clients | Backend | Database | Cache | AI |
|:---:|:---:|:---:|:---:|:---:|
| SwiftUI + Compose | Fastify · Zod · Pino | PostgreSQL 15 | Redis | Gemini |

</div>

---

## 📱 iOS screens

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

<p align="center"><em>Live screenshots from the shipping SwiftUI build · emerald theme.</em></p>

---

## ✨ Capabilities

<img src="docs/images/feature-gallery.svg" alt="Capabilities overview" width="100%"/>

| # | Capability | What it does | Status |
|---|-----------|-------------|:------:|
| 1 | **Log · Rate · Review** | 0–6 rating with half-star precision; editable reviews with optimistic concurrency | ✅ |
| 2 | **Social feed** | Follow users, see their logs / reviews / lists, react and comment — Redis-fanned | ✅ |
| 3 | **Discover** | Genre browsing, Postgres full-text search (tsvector + GIN), trending | ✅ |
| 4 | **Curated lists** | Public or private album collections, ordered, shareable | ✅ |
| 5 | **Weekly recaps** | Auto-generated insights: albums logged, avg rating, top pick, new follows | ✅ |
| 6 | **Push notifications** | Follow alerts, reactions, comments — via `push` module | ✅ |
| 7 | **Theming** | 6 accent themes reskin the entire app — Emerald · Amethyst · Bonfire · Rose · Midnight · Gilt | ✅ |
| 8 | **GDPR tooling** | Full account data export + deletion | ✅ |
| 9 | **Gemini recs** | Recommendation engine wired on backend, mobile integration pending | 🛠 |
| 10 | **Spotify OAuth** | Listening history import + sync, provider-agnostic canonical album mapping | 🛠 |

---

## 🏗️ Architecture

<img src="docs/images/architecture.svg" alt="SoundScore architecture" width="100%"/>

```mermaid
flowchart TB
  subgraph Clients["📱 Native Clients"]
    IOS["iOS · SwiftUI<br/>Combine · URLSession"]
    AND["Android · Jetpack Compose<br/>StateFlow · Hilt · Room"]
  end

  subgraph API["⚡ Fastify API (TypeScript)"]
    direction LR
    AUTH[auth] --- CAT[catalog] --- OPN[opinions]
    SOC[social] --- LST[lists] --- REC[recaps]
    PSH[push] --- IMP[import] --- PRV[providers]
    MAP[mapping] --- TRU[trust]
  end

  subgraph Data["💾 Data Layer"]
    PG[("PostgreSQL 15<br/>tsvector · GIN")]
    RD[("Redis<br/>sessions · fan-out · rate limit")]
  end

  subgraph Ext["🌐 External Providers"]
    SP[Spotify OAuth]
    MB[MusicBrainz]
    GM[Gemini]
  end

  IOS -- "HTTPS · /v1/*" --> API
  AND -- "HTTPS · /v1/*" --> API
  API --> PG
  API --> RD
  API --> SP
  API --> MB
  API --> GM

  classDef client fill:#061A10,stroke:#1ED760,color:#F2F5F3
  classDef api fill:#0A2A18,stroke:#1ED76088,color:#F2F5F3
  classDef data fill:#061A10,stroke:#4FC3F755,color:#F2F5F3
  classDef ext fill:#061A10,stroke:#B388FF55,color:#F2F5F3
  class IOS,AND client
  class AUTH,CAT,OPN,SOC,LST,REC,PSH,IMP,PRV,MAP,TRU api
  class PG,RD data
  class SP,MB,GM ext
```

**Defining properties**

- **36 API routes** across **11 domain modules** (`auth`, `catalog`, `opinions`, `social`, `lists`, `recaps`, `push`, `import`, `providers`, `mapping`, `trust`)
- **Shared Zod contracts** in `packages/contracts/` — one source of truth for request/response shapes across Android, iOS, and backend
- **Idempotency-key enforcement** on every mutating route
- **Redis-cached** feed fan-out, sessions, rate limiting
- **Postgres full-text search** via `tsvector` + `GIN` indexes (album/artist lookup lands in **&lt;90 ms p95**)

### Rating mutation · lifecycle

```mermaid
sequenceDiagram
  autonumber
  participant C as Client (iOS/Android)
  participant F as Fastify /v1/opinions
  participant Z as Zod validator
  participant P as Postgres
  participant R as Redis
  participant S as Social fan-out

  C->>F: POST { album, rating, idempotencyKey }
  F->>Z: validate payload
  Z-->>F: ok
  F->>P: UPSERT opinion (opinion_version++)
  P-->>F: row + version
  F->>R: cache opinion + invalidate album agg
  F->>S: enqueue feed fan-out (followers)
  F-->>C: 200 { opinion, version }
  S-->>R: push feed items for followers
```

### Opinion state

```mermaid
stateDiagram-v2
  [*] --> draft
  draft --> logged: submit rating
  logged --> edited: edit review/rating
  edited --> edited: re-edit (version++)
  logged --> deleted: GDPR purge
  edited --> deleted: GDPR purge
  deleted --> [*]
```

---

## 🔥 Feature spotlights

### A real rating system · not five stars

<img src="docs/images/spotlight-rating.svg" alt="Rating spotlight" width="100%"/>

Thirteen increments from **0.0 to 6.0**. Every half-star matters. Every edit bumps `opinion_version` so concurrent edits can't clobber each other — the server resolves with optimistic concurrency and returns the authoritative version.

### Social feed that's actually fast

The `social` module writes to per-user feed keys in Redis when a followed user logs an album, reacts, or publishes a list. Clients read a prebuilt feed instead of querying the graph — **no N+1 fan-out at read time**. Expiry is capped so cold followers don't blow up memory.

### 6 themes · whole-app reskin

The iOS `ThemeManager` publishes an `AccentTheme` (Emerald · Bonfire · Rose · Amethyst · Midnight · Gilt). Every screen binds to `ThemeManager.shared.primary` / `secondary` / `colors.darkBase`. Picking a theme in Settings re-renders the entire app — backdrop glows, album gradient overlays, tab bar accents, everything.

### Gemini-powered recommendations

The backend exposes a recommendation endpoint that takes a user's rating history, sends a compact prompt to Gemini, and returns a structured list of album recs with a "because you rated X" explanation. Mobile surfacing is in progress; the API is live.

---

## 🛠️ Tech stack

| Layer | Stack |
|-------|-------|
| **iOS** | Swift · SwiftUI · Combine · URLSession |
| **Android** | Kotlin · Jetpack Compose · StateFlow · Hilt · OkHttp · Room |
| **Backend** | TypeScript · Fastify 4.x · Pino · Zod |
| **Contracts** | `packages/contracts/` — shared Zod schemas consumed by backend + type-gen for clients |
| **Database** | PostgreSQL 15 (tsvector + GIN full-text search) |
| **Cache** | Redis — sessions, feed fan-out, rate limit buckets |
| **AI** | Google Gemini (recommendation engine) |
| **Infra** | Docker Compose (local Postgres + Redis) · Railway (prod) |
| **Tooling** | Node 20 · Xcode 16+ · Android Studio · Gradle Kotlin DSL |

---

## 🚀 Getting started

### Prerequisites

- **Node.js 20+**
- **Docker** (for local Postgres + Redis)
- **Xcode 16+** (for iOS)
- **Android Studio** (for Android)

### Backend

```bash
docker compose up -d
npm install
npm run migrate --workspace backend
npm run dev --workspace backend
```

Server runs at `http://localhost:8080`.

### iOS

Open `ios/SoundScore/SoundScore.xcodeproj` in Xcode, pick a simulator, hit **Run**. The app auto-authenticates against the local backend in debug mode.

### Android

```bash
./gradlew installDebug
```

Or open the project in Android Studio and run on a device / emulator.

---

## 🗂️ Project structure

```
SoundScoreV0.1/
├── app/                    # 📱 Android app (Kotlin + Jetpack Compose)
│   └── src/main/java/
│       ├── data/           #   Repository · API client · DTOs
│       └── ui/             #   Screens · ViewModels · theme
│
├── ios/                    # 🍎 iOS app (Swift + SwiftUI)
│   └── SoundScore/
│       ├── Screens/        #   10 screens + ViewModels
│       ├── Components/     #   Reusable UI (glass cards, rating bar, etc.)
│       └── Theme/          #   6 accent themes + typography
│
├── backend/                # ⚡ Fastify API
│   └── src/
│       ├── modules/        #   11 domain modules
│       ├── lib/            #   18 shared utilities
│       └── db/             #   Schema migrations
│
├── packages/contracts/     # 📦 Shared Zod schemas
├── docs/                   # 📖 Architecture, audit logs, screenshots
└── docker-compose.yml      # 🐳 Local Postgres + Redis
```

---

## 📊 Stats

<div align="center">

| | Android | iOS | Backend |
|---|:---:|:---:|:---:|
| **Source files** | **33** | **67** | **45** |
| **Lines of code** | ~4,900 | ~8,300 | ~5,500 |
| **API routes wired** | 18 | 22 | **36** |
| **Domain modules** | — | — | **11** |
| **Themes** | — | **6** | — |
| **Tests** | — | — | ~96 |

</div>

---

## 🎨 Design tokens

| Token | Value | Used for |
|-------|-------|----------|
| `darkBase` | `#020A04` → `#0A0802` (per-theme) | App background |
| `darkSurface` | `#061A10` → theme variant | Card / list surface |
| `darkElevated` | `#0A2A18` → theme variant | Modals, sheets |
| `glassBg` | `rgba(255,255,255,0.07)` | Glass morphism cards |
| `glassBorder` | `rgba(255,255,255,0.18)` | Glass edges |
| `accentEmerald` | `#1ED760` | Primary (default theme) |
| `accentAmethyst` | `#B388FF` | Purple theme / violet semantic |
| `accentBonfire` | `#FF8C42` | Orange theme |
| `accentRose` | `#FF6B8A` | Pink theme |
| `accentMidnight` | `#4FC3F7` | Blue theme |
| `accentGilt` | `#FFD54F` | Gold theme |

---

## 🤝 Contributing

This started as a solo sandbox project. If you want to pick it up, extend it, or fork it as a foundation — go for it.

**Areas that could use work:**

- [ ] Android parity with iOS (5 screens still missing)
- [ ] Phase 2 Spotify integration on mobile clients
- [ ] Surface Gemini recs in the UI
- [ ] Test coverage (currently backend-only, ~96 tests)
- [ ] CI / CD pipeline hardening

### Branch strategy

| Branch prefix | Purpose |
|--------------|---------|
| `main` | Stable |
| `feat/<description>` | New features |
| `fix/<description>` | Bug fixes |

### Commit format

```
<type>: <description>
```

Types: `feat` · `fix` · `refactor` · `docs` · `test` · `chore` · `perf` · `ci`

---

## 🔗 Related

- **[SoundScore Web (Legacy)](https://github.com/madhavcodez/SoundScore)** — the original 2025 web prototype (React + Express + MongoDB). Archived as a reference.

---

<div align="center">

### 📄 License

MIT · Built by [**@madhavcodez**](https://github.com/madhavcodez)

_Log what you listen to. Share what you love._

</div>
