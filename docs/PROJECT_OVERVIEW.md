# SoundScore — Project Overview

## What SoundScore is

SoundScore is **"Letterboxd for music"**: a dedicated place to log albums you actually listened to, rate them on a consistent scale, write real reviews (optionally), build lists, and make your taste legible on a profile—then layer friend-first social discovery on top.

**Core loop:** Log → rate → (optional) review → profile identity (top albums + recent activity) → lightweight community views per album. Roadmap adds lists, friend graph, and recommendation features.

## V1 design realities (from architecture report)

- **Surface area is crowded.** Winning comes from friction reduction, culture, and distribution loops—not just feature parity with other "rate albums" apps.
- **Low-effort capture scales.** V1 must make logging feel like a swipe/tap, not an essay prompt.
- **Spotify is not a stable scaling foundation.** Dev Mode constraints (Feb/Mar 2026) mean the core product must work **without** Spotify; Spotify is an optional enhancement.

## What this repo is

- **Stack:** **Android native** — Kotlin, Jetpack Compose, Navigation Compose, Material3. The architecture PDF also describes a React Native + Expo option; for this codebase we are building **native Android** (iOS optionally later).
- **Current state:** Five screens (Feed, Log, Search, Lists, Profile), bottom nav with "liquid glass" bar, in-memory dummy data. No backend or auth yet.
- **Sources of truth for context:** `deep-research-report.md` (market, competitors, Spotify constraints, strategy), `SoundScore_V1_Mobile_Architecture_Report_Madhav_Chauhan.pdf` (product, mobile UX, system architecture, API, security, roadmap).

## End-to-end V1 (from architecture report)

SoundScore V1 is designed to be:

- **Mobile-first** — iOS/Android are the primary clients; the app is the product.
- **Provider-agnostic** — SoundScore owns canonical IDs; external providers (Spotify, Apple Music, MusicBrainz) are adapters.
- **Event-driven where it matters** — listening events + activity events.
- **Operationally sane** — modular monolith + queue + background workers.
- **Built for trust** — export, delete, disconnect as real product surfaces.

## Context docs (read when building)

| Doc | Purpose |
|-----|--------|
| [NEXT_PHASE_PLAN.md](NEXT_PHASE_PLAN.md) | **Next phase:** Phase 1B stabilization and M1 closure; tracks, exit criteria, build verification, external-contributor handoff. |
| [CONTEXT_01_PRODUCT_AND_MARKET.md](CONTEXT_01_PRODUCT_AND_MARKET.md) | Why we exist, wedge, success criteria, competitors, strategy (from deep research + PDF). |
| [CONTEXT_02_ARCHITECTURE_AND_SYSTEM.md](CONTEXT_02_ARCHITECTURE_AND_SYSTEM.md) | Domains, data flow, provider adapters, catalog, feed, API, trust stack (from PDF). |
| [CONTEXT_03_MOBILE_APP_SPEC.md](CONTEXT_03_MOBILE_APP_SPEC.md) | Mobile principles, journeys, current Android implementation, perf, offline, push (from PDF + codebase). |
| [CONTEXT_04_CODEBASE_MAP.md](CONTEXT_04_CODEBASE_MAP.md) | Where things live; packages, screens, models, theme, components; "add X → edit Y" (from codebase). |
| [CONTEXT_05_CONVENTIONS_AND_CONSTRAINTS.md](CONTEXT_05_CONVENTIONS_AND_CONSTRAINTS.md) | Spotify policy, security, API conventions, testing (from PDF + deep research). |
| [CONTEXT_06_ROADMAP_AND_PHASES.md](CONTEXT_06_ROADMAP_AND_PHASES.md) | Beta phases, launch sequence, V1 vs later (from PDF + deep research). |
| [CONTEXT_07_DATA_MODELS_AND_EVENTS.md](CONTEXT_07_DATA_MODELS_AND_EVENTS.md) | Activity/listening event schemas, canonical entities, current DummyData mapping (from PDF + codebase). |

## Constraint: 150 lines per doc

Each context file in `docs/` is kept to **at most 150 lines** so Cursor can load them without truncation while still giving genuine, implementation-useful content from the architecture plan and deep research report.
