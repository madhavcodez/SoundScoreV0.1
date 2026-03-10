# SoundScore Backend (Phase 1A foundation)

Provider-free Fastify API for SoundScore with idempotent write behavior and `/v1` contracts.

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

Mutating routes require `idempotency-key` header.
