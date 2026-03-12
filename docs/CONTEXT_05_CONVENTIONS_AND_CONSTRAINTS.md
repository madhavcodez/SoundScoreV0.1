# Conventions and Constraints

Use this to stay compliant with Spotify, security, API design, and testing. Sources: architecture PDF §8, §10; deep-research-report.md (Spotify section).

---

## Spotify (if/when integrated)

**Dev Mode limits (Feb/Mar 2026):** Premium-only developer access; single Development Mode Client ID; up to five authorized users per app; limited endpoint access. App can stop working if Premium lapses. Extended quota (unlimited users) requires organization, launched service, 250k MAUs+.

**Policy (non-optional):**
- Transparency and privacy policy; limit data collection to what’s needed.
- User-accessible way to **disconnect** Spotify account; after disconnect, **delete and stop processing** that user’s personal data.
- **Attribution/link-back:** When displaying Spotify metadata or cover art, accompany with a link back to the relevant album/content/playlist on Spotify. Do **not** offer Spotify metadata/cover art as a standalone product.

**UI impact:** Album pages and any Spotify-sourced art must have "Listen on Spotify" (or equivalent) links; token and personal data retention must align with disconnect/delete rules.

---

## Security and privacy (from PDF §10)

**Threat model (mobile):** Account takeover (credential stuffing, session theft); token leakage (provider tokens, refresh tokens); abuse/spam (fake accounts, automated reactions/comments); scraping; reverse engineering (tampering, API misuse).

**Controls:**
- **Secure storage:** Keychain (iOS) / Keystore (Android) for refresh tokens; **no** tokens in plain text or unencrypted shared prefs/AsyncStorage.
- **Network:** TLS everywhere; rotate refresh tokens; short-lived access tokens.
- **Abuse:** Rate limits; privacy-respecting device fingerprinting to reduce automation; report/block flows in-app; moderation tooling on backend.
- **Audit:** Log account-sensitive actions; alert on anomalous sign-in patterns.

**App store privacy:**
- Request permissions only when needed (e.g. contacts optional; notifications opt-in; no background location/tracking).
- Clear privacy policy and in-app disclosure for connected providers (Spotify, etc.).
- **Data export and deletion** user-accessible in-app; **provider disconnect** one tap.

---

## API conventions (from PDF §8.1)

- **Pagination:** Cursor-based for feeds and comments (e.g. `?cursor=...&limit=20`).
- **Writes:** All mutating endpoints accept an **idempotency key** (header or body) so mobile retries and offline outbox don’t create duplicates.
- **Versioning:** Prefix with `/v1/`.
- **Errors:** Consistent envelope; typed error codes so the client can show appropriate UX (e.g. "rate limited," "not found," "unauthorized").

When implementing or generating API client code, follow these so the app and backend stay aligned.

---

## Testing strategy (from PDF §9.3)

- **Unit:** Domain use-cases, catalog mapping logic, reducers/stores, utility functions.
- **Integration:** API contract tests (e.g. OpenAPI snapshots); end-to-end flows in staging.
- **UI:** Smoke tests for critical paths (onboarding, logging, feed) using Detox/Appium or Android’s Compose testing.
- **Observability as testing:** Monitor crash-free sessions, ANR rates, network error rates; use as ongoing quality signal.

---

## Reference links (from PDF Appendix B)

- Spotify Developer Policy: https://developer.spotify.com/policy
- Spotify Dev Mode update (Feb 2026): https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security
- Spotify migration guide: https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide
- Spotify quota modes: https://developer.spotify.com/documentation/web-api/concepts/quota-modes
- MusicBrainz data license (CC0): https://musicbrainz.org/doc/About/Data_License
- ListenBrainz docs: https://listenbrainz.readthedocs.io/en/latest/index.html
