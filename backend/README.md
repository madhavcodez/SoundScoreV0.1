# SoundScore Backend (Phase 1B stabilization)

Provider-free Fastify API for SoundScore with persistent storage (Postgres), cache (Redis), and idempotent `/v1` write behavior.

## Endpoints

- `POST /v1/auth/signup`
- `POST /v1/auth/login`
- `POST /v1/auth/refresh`
- `GET /v1/me`
- `GET /v1/search`
- `GET /v1/albums/:id`
- `GET /v1/log/recently-played`
- `POST /v1/ratings`
- `POST /v1/reviews`
- `PUT /v1/reviews/:id`
- `POST /v1/follow/:userId`
- `DELETE /v1/follow/:userId`
- `GET /v1/feed`
- `POST /v1/activity/:id/react`
- `POST /v1/activity/:id/comment`
- `POST /v1/lists`
- `POST /v1/lists/:id/items`
- `GET /v1/lists/:id`
- `POST /v1/account/export`
- `DELETE /v1/account`
- `GET /v1/recaps/weekly/latest`
- `POST /v1/recaps/weekly/generate`
- `POST /v1/push/tokens`
- `DELETE /v1/push/tokens/:deviceToken`
- `GET /v1/push/preferences`
- `PUT /v1/push/preferences`
- `GET /v1/notifications`
- `POST /v1/notifications/test-recap`

Mutating routes require `idempotency-key` header.

## Setup

1. Start infra (`postgres`, `redis`) using `docker compose up -d`.
2. Install packages: `npm install`.
3. Run migrations: `npm run migrate --workspace backend`.
4. Start backend: `npm run dev --workspace backend`.
