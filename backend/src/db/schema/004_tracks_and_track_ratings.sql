-- Phase 1: Tracks and Track Ratings
-- Adds per-track data and per-track rating support

CREATE TABLE IF NOT EXISTS tracks (
    id          TEXT PRIMARY KEY,
    album_id    TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    track_number INTEGER NOT NULL,
    duration_ms  INTEGER,
    spotify_id   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(album_id, track_number)
);

CREATE TABLE IF NOT EXISTS track_ratings (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    track_id    TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    album_id    TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
    value       REAL NOT NULL CHECK(value >= 0 AND value <= 6),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, track_id)
);

CREATE INDEX IF NOT EXISTS idx_tracks_album_id ON tracks(album_id);
CREATE INDEX IF NOT EXISTS idx_track_ratings_user_track ON track_ratings(user_id, track_id);
CREATE INDEX IF NOT EXISTS idx_track_ratings_album ON track_ratings(album_id);
