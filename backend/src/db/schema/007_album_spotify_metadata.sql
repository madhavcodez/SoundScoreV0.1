-- Add Spotify metadata columns to albums
ALTER TABLE albums
  ADD COLUMN IF NOT EXISTS spotify_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS genres TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS popularity INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS label TEXT,
  ADD COLUMN IF NOT EXISTS total_tracks INT DEFAULT 0;

-- Genre junction table for normalized genre queries
CREATE TABLE IF NOT EXISTS album_genres (
  album_id TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
  genre TEXT NOT NULL,
  PRIMARY KEY (album_id, genre)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_albums_spotify_id ON albums(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_album_genres_genre ON album_genres(genre);
