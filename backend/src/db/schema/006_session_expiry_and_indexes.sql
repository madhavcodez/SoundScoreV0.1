-- Add session expiration support
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- Backfill existing sessions with a 24-hour window from creation
UPDATE sessions SET expires_at = created_at + INTERVAL '24 hours' WHERE expires_at IS NULL;

-- Now enforce NOT NULL
ALTER TABLE sessions ALTER COLUMN expires_at SET NOT NULL;

-- Create index for expired session cleanup
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- Missing indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_ratings_album ON ratings(album_id);
CREATE INDEX IF NOT EXISTS idx_reviews_album ON reviews(album_id);
CREATE INDEX IF NOT EXISTS idx_activity_created ON activity_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listening_album ON listening_events(album_id);
CREATE INDEX IF NOT EXISTS idx_notification_events_user ON notification_events(user_id, created_at DESC);

-- Full-text search support for albums
ALTER TABLE albums ADD COLUMN IF NOT EXISTS search_vector tsvector;

UPDATE albums SET search_vector = to_tsvector('english', title || ' ' || artist) WHERE search_vector IS NULL;

CREATE INDEX IF NOT EXISTS idx_albums_search ON albums USING GIN (search_vector);

-- Trigger to keep search_vector updated on insert/update
CREATE OR REPLACE FUNCTION albums_search_vector_update() RETURNS trigger AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', NEW.title || ' ' || NEW.artist);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_albums_search_vector ON albums;
CREATE TRIGGER trg_albums_search_vector
  BEFORE INSERT OR UPDATE OF title, artist ON albums
  FOR EACH ROW EXECUTE FUNCTION albums_search_vector_update();
