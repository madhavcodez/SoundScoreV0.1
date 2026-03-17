-- Audit events for security and compliance logging.
-- user_id intentionally has no FK to users: audit rows are retained after
-- account deletion to support compliance investigations and breach forensics.
CREATE TABLE IF NOT EXISTS audit_events (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  details JSONB DEFAULT '{}',
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_type ON audit_events(event_type, created_at DESC);

-- Dead letter queue for failed async operations
CREATE TABLE IF NOT EXISTS dead_letter_events (
  id TEXT PRIMARY KEY,
  original_id TEXT,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  error TEXT NOT NULL,
  attempt_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
