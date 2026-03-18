# --- Builder stage ---
FROM node:20-alpine AS builder
WORKDIR /app

# Copy workspace root for npm workspaces resolution
COPY package.json package-lock.json ./
COPY packages/contracts/package.json packages/contracts/
COPY backend/package.json backend/

RUN npm ci --workspace backend --workspace @soundscore/contracts

COPY packages/contracts/ packages/contracts/
COPY backend/ backend/

RUN npm run build --workspace @soundscore/contracts && npm run build --workspace backend

# --- Production stage ---
FROM node:20-alpine AS production
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY package.json package-lock.json ./
COPY packages/contracts/package.json packages/contracts/
COPY backend/package.json backend/

RUN npm ci --workspace backend --workspace @soundscore/contracts --omit=dev

COPY --from=builder /app/packages/contracts/dist packages/contracts/dist
COPY --from=builder /app/backend/dist backend/dist
COPY backend/src/db/schema backend/src/db/schema

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -q --spider http://localhost:8080/health || exit 1

CMD ["node", "backend/dist/index.js"]
