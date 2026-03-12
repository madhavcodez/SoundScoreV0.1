# Roadmap and Phases

Use this to scope work and avoid over-building. Sources: architecture PDF §11; deep-research-report.md (strategy, Spotify dependency, operational excellence).

---

## Beta phases (from PDF §11.1)

**1. Provider-free beta**
- Manual logging + social + lists + recaps.
- No external provider dependency (no Spotify/Apple Music required).
- Validates core loop, UX, and trust surfaces (export, delete) before any platform risk.

**2. Provider-limited beta**
- Spotify allowlist cohort (fits Dev Mode 5-user limit).
- Iterate on import reliability and catalog mapping with real listens.
- Keep core experience usable without Spotify.

**3. Multi-provider beta**
- Add Apple Music and/or ListenBrainz adapters.
- Improve catalog mapping confidence across sources.
- Reduces single-provider policy risk.

---

## Launch sequence (from PDF §11.2)

- **Launch with share mechanics + export** to establish trust from day one.
- **Grow** through list culture and recaps; tune notifications carefully (recap ready, write-later nudge, social reactions).
- **Scale** feed and ingestion as graphs grow; introduce fan-out-on-write only when required (e.g. median follows > ~200 or p95 latency breaks).

---

## V1 scope (what we build first)

**In scope for V1:**
- Provider-optional core: sign up and use the app without connecting any streaming provider.
- Log (manual and, when available, from provider), rate, optional review, write-later queue.
- Profile (top albums, stats, shareable).
- Feed (activity from followed users), reactions, comments.
- Lists (create, items, share cards).
- Recaps (weekly, shareable).
- Trust: export, account deletion, provider disconnect (one tap).

**Post-V1 (do not over-build in V1):**
- Home screen widgets (WidgetKit / Android widgets).
- Full deep-link handling for all entity types (albums, lists, profiles, recaps) if not already in V1.
- Full multi-provider parity and advanced mapping UX.
- Recommendation features.
- Any monetization that requires payment infrastructure (can be prepared but not required for first launch).

---

## Strategic reminders from deep research

- **Reduce Spotify dependency early:** Design so core value does not depend on Spotify; use MusicBrainz (or similar) for catalog resilience; consider ListenBrainz for listening identity.
- **Operational excellence as differentiator:** Reliability, status page, export, and clear communication are product advantages in this niche—not just engineering hygiene.
- **Trust stack is product:** Export, deletion, and disconnect are user-facing features; implement and test them as such.
