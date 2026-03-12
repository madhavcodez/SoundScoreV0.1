#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required for Postgres/Redis bootstrap"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required"
  exit 1
fi

echo "Starting Postgres/Redis..."
docker compose up -d postgres redis

echo "Installing dependencies..."
npm install

echo "Running backend migrations..."
npm run migrate --workspace backend

echo "Phase 1B local bootstrap complete."
echo "Start backend with: npm run dev --workspace backend"
