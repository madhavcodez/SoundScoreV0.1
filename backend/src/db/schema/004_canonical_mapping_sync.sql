-- Canonical artists
CREATE TABLE IF NOT EXISTS canonical_artists (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_canonical_artist_norm ON canonical_artists(normalized_name);

-- Canonical albums (SoundScore-owned IDs)
CREATE TABLE IF NOT EXISTS canonical_albums (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  artist_id TEXT REFERENCES canonical_artists(id),
  year INT,
  track_count INT,
  artwork_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_canonical_album_norm ON canonical_albums(normalized_title, artist_id);

-- Provider ID mappings
CREATE TABLE IF NOT EXISTS provider_mappings (
  id TEXT PRIMARY KEY,
  canonical_id TEXT NOT NULL,
  canonical_type TEXT NOT NULL CHECK (canonical_type IN ('artist', 'album', 'track')),
  provider TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  confidence REAL NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 1),
  provenance TEXT NOT NULL DEFAULT 'auto_match' CHECK (provenance IN ('auto_match', 'user_confirm', 'admin_override', 'provider_link')),
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'pending', 'ambiguous', 'unmapped')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(provider, provider_id)
);
CREATE INDEX IF NOT EXISTS idx_mapping_canonical ON provider_mappings(canonical_id);
CREATE INDEX IF NOT EXISTS idx_mapping_lookup ON provider_mappings(provider, provider_id);

-- Sync cursors (resume point per user per provider)
CREATE TABLE IF NOT EXISTS sync_cursors (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  cursor_value TEXT,
  last_sync_at TIMESTAMPTZ,
  PRIMARY KEY(user_id, provider)
);

-- Sync jobs
CREATE TABLE IF NOT EXISTS sync_jobs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  provider TEXT NOT NULL,
  sync_type TEXT NOT NULL CHECK (sync_type IN ('full', 'incremental')),
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancelled')),
  progress INT DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  items_processed INT DEFAULT 0,
  items_total INT,
  error TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sync_jobs_user ON sync_jobs(user_id, created_at DESC);

-- Add dedup_key to listening_events for import deduplication
ALTER TABLE listening_events ADD COLUMN IF NOT EXISTS dedup_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_listening_events_dedup ON listening_events(dedup_key) WHERE dedup_key IS NOT NULL;
