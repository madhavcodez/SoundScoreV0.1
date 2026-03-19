-- Add missing timestamp columns to albums table
-- Required by upsertAlbumFromSpotify() in spotify-catalog.ts
ALTER TABLE albums
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
