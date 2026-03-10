# SoundScore Phase 1A Foundation

This repository now contains both mobile and backend foundations for the provider-free beta.

## Modules

- `app/` Android app (Kotlin + Compose) with repository/ViewModel architecture.
- `backend/` TypeScript + Fastify provider-free API (`/v1/*`).
- `packages/contracts/` shared TypeScript contracts for API payloads and event schemas.

## Backend quick start

The backend requires Node.js 20+.

```bash
npm install
npm run dev
```

Default server URL: `http://localhost:8080`

## Android notes

- Screens now read from `SoundScoreRepository` through ViewModels.
- `Lists` and `Profile` no longer have dead CTA buttons.
- API client and outbox scaffolding are included for Phase 1 sync wiring.
