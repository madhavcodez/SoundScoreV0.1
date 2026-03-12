# SoundScore Phase 1B Stabilization

This repository now contains both mobile and backend foundations for the provider-free beta.

## Modules

- `app/` Android app (Kotlin + Compose) with repository/ViewModel architecture.
- `backend/` TypeScript + Fastify provider-free API (`/v1/*`) with Postgres + Redis.
- `packages/contracts/` shared TypeScript contracts for API payloads and event schemas.

## Backend quick start

The backend requires Node.js 20+.

```bash
docker compose up -d
npm install
npm run migrate --workspace backend
npm run dev
```

Or run the one-shot bootstrap:

```bash
./scripts/bootstrap-phase1b.sh
```

Default server URL: `http://localhost:8080`

## Android notes

- Screens now read from `SoundScoreRepository` through ViewModels.
- `Lists` and `Profile` no longer have dead CTA buttons.
- API client and outbox scaffolding are included for Phase 1 sync wiring.
