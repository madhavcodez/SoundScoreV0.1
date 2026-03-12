# Product and Market Context

Use this when deciding what to build, how to position features, or why we make product tradeoffs. Sources: `deep-research-report.md`, architecture PDF §2–3.

---

## What SoundScore is (product definition)

- **Taste journal:** Log albums listened to, rate, review (optional), draft reviews, create lists.
- **Taste identity:** Profile shows top albums, stats (genres/decades), recency.
- **Social discovery:** Follow friends, see activity, react/comment, explore album pages and lists.

---

## The wedge (how V1 wins)

We win on three axes, not on feature parity:

1. **Friction:** One-tap logging from real listening context; reviews can be written later. "Rate what you actually listened to, with the lowest possible effort"—then progressively deepen (reviews, track picks, lists) for power users.
2. **Culture:** List/review norms that reward substance without demanding essays.
3. **Distribution:** Shareable objects—weekly recap cards, list cards, profile cards—that travel and drive acquisition.

Concrete product moves from deep research:
- Make "log it" effortless (one tap to log, optional review later) to avoid the "write an essay" trap that kills daily retention; still support high-quality reviews for those who want them.
- Build share objects that travel: weekly "SoundScore Recap" card, "Top 6 albums" profile card, "recent ratings" strip. Shareable stats drive acquisition (Airbuds recap, Spotify Wrapped).
- Treat lists as a core distribution surface; differentiate list semantics ("albums I would defend," "best headphones albums") for taste-as-identity.

---

## V1 success criteria (from architecture PDF)

**North Star outcomes:**
1. Taste identity becomes legible in under 2 minutes.
2. A weekly habit forms around logging + reacting + recaps.
3. Shares create acquisition and bring in friend clusters.
4. Trust is productized (export, deletion, privacy).

**Concrete targets:**

| Metric | Target | Why it matters |
|--------|--------|----------------|
| Time-to-first-log (median) | < 60 seconds | Friction story; correlates with D1 retention. |
| Feed load p95 (cached page 1) | < 400 ms | Mobile users abandon slow feeds. |
| Profile load p95 | < 300 ms | Profile is the identity surface shared externally. |
| Shares / active user / week | Upward trend post-recaps | Product-market resonance, organic distribution. |
| Crash-free sessions | > 99.5% | Mobile reliability = brand trust. |

---

## Competitive landscape (from deep research)

We compete with three categories:

1. **Direct competitors (album logging, ratings, reviews, lists):** Musicboard ("Letterboxd for music lovers," 400k+ users claimed, Pro $4.99/mo), Musotic (Spotify/Apple sign-up, small scale), Musis (100K+ Android downloads), plus long tail (Spinlist, Tuniverse, Factory.fm, Musicboxd, Noisefloor). **Takeaway:** The blueprint (rate + review + profile + lists + friends) is widely copied; differentiation = culture, friction, distribution.

2. **Entrenched incumbents:** RYM (~1.3M users, ~15M visits/mo), AOTY (~12.59M visits), Last.fm (taste stats, scrobbling), Discogs (collectors, marketplace). They have decades of data and mindshare; we don't win on "biggest database."

3. **Passive social / identity-first:** Airbuds (15M+ downloads, 5M MAU—success through *low* friction: listening becomes the feed automatically). **Lesson:** "Music social" works, but winning mechanics may not be long-form reviews; reducing effort while amplifying identity is key.

**Strategic reading:** RYM/AOTY strongest at "global database + charts"; Airbuds at "friends + passive feed." Musicboard showed appetite for a Letterboxd-like journal but had operational fragility—opening for a **trustworthy, export-friendly** alternative.

---

## What makes social music products succeed (from deep research)

- **Low-friction creation loop:** System creates content from behavior (e.g. listening); writing optional. For SoundScore: system knows what you listened to, nudges to rate/review without making you search and remember.
- **Identity primitives:** Compact favorites (top albums/artists), periodic recaps (weekly/yearly) that can be screenshotted, lightweight reactions (not essays).
- **Community:** Friend-first (not public follower spam); clear contribution norms; anti-spam, anti-brigading; export/portability for trust.

---

## Spotify: platform risk and strategy (from deep research)

- **Feb 2026:** Dev Mode reduced—Premium-only, single Client ID, up to 5 authorized users, limited endpoints. Extended quota (unlimited users) requires org (not individual), launched service, **250k MAUs**+.
- **Implication:** Core product must work **without** Spotify; Spotify = optional enhancement. Options: (1) Spotify-optional sign-up, MusicBrainz (or similar) for catalog, Spotify only for "import listening context"; (2) multi-provider (Apple Music, ListenBrainz) to expand market and de-risk policy shocks.

---

## Trust and operational excellence (from deep research)

Musicboard’s turbulence showed that **reliability, communication, and data portability are strategic differentiators**. Productize the trust stack:
- Clear export (CSV/JSON) and deletion controls.
- Transparent status page and incident comms.
- Privacy aligned to Spotify policy (disconnect → delete/stop processing).
- One-tap provider disconnect in-app.

---

## Monetization (from deep research)

- Subscription for advanced stats, profile customization, premium list features (Musicboard Pro ~$4.99/mo).
- Optional "supporter" tier (identity signal, Letterboxd-style).
- Affiliate (e.g. vinyl, merch) only where compliant—avoid streaming-licensing territory; Spotify policy and quota gating make "commercial streaming integration" risky.
