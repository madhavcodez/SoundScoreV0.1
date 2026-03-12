# Phase 1B Release Runbook

## Environments

- Local: Docker-backed Postgres + Redis, backend via `npm run dev --workspace backend`, Android emulator API base `http://10.0.2.2:8080`.
- CI: GitHub Actions services (`postgres`, `redis`) with migrations before typecheck/build.
- Staging: mirror production env vars and migration sequence.

## Pre-release checklist

1. `docker compose up -d` and `npm run migrate` complete successfully.
2. Backend health check returns `postgres=up` and Redis connected state.
3. Android app boots, pulls remote catalog/profile/feed, and handles offline fallback.
4. Outbox replay validated for rating, list create, push prefs, recap generate.
5. Recap endpoint returns latest payload and deep link is parseable by app.
6. Push preference APIs and device token registration return 2xx.

## Rollout

1. Deploy backend with migrations first.
2. Verify `/health`, `/v1/recaps/weekly/latest`, and `/v1/push/preferences` from staging client.
3. Promote Android build through internal testing track.
4. Monitor first-hour errors and latency for feed/profile writes.

## Rollback

1. Roll back backend image to previous tag.
2. Keep DB schema (backward-compatible migration approach).
3. Disable recap generation job endpoint invocation if required.
4. Disable push test endpoint exposure in gateway if notification queue spikes.
