# Running SoundScore Locally

## Tools in this repo

- **Node.js** — Installed under `.local/node/` (v20 LTS). Use it by sourcing the run script (see below) or by adding `./.local/node/bin` to your `PATH`.
- **Java** — Use Android Studio’s bundled JDK. The run script sets `JAVA_HOME` to it so Gradle works.

## One-time setup: load env

From the repo root:

```bash
source scripts/run-env.sh
```

Or: `. scripts/run-env.sh`

This puts Node and Java on `PATH` and sets `JAVA_HOME`. Use this in every new terminal where you run backend or Android.

## Backend (Postgres + Redis required)

1. **Install Docker Desktop** (or have Postgres and Redis running on `localhost:5432` and `localhost:6379`).
2. Start DBs:
   ```bash
   docker compose up -d
   ```
3. Migrate and run:
   ```bash
   npm run migrate
   npm run dev
   ```
   Backend will be at `http://localhost:8080`. Use `backend/.env` (see `backend/.env.example`) to override ports or URLs.

## Android app

- **From terminal** (after `source scripts/run-env.sh`):
  ```bash
  ./gradlew installDebug
  ```
  Installs the debug APK on a connected device or running emulator.

- **From Android Studio:** Open the project, select a device/emulator, and Run. Android Studio uses its own JDK; no need to set `JAVA_HOME` there.

## Quick reference

| Goal              | Command / step                                      |
|-------------------|-----------------------------------------------------|
| Load Node + Java  | `source scripts/run-env.sh`                         |
| Start Postgres/Redis | `docker compose up -d`                          |
| Run migrations    | `npm run migrate`                                   |
| Start backend     | `npm run dev`                                       |
| Build + install app | `./gradlew installDebug`                         |
