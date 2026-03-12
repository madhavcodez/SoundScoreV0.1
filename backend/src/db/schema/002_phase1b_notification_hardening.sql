ALTER TABLE notification_events
  ADD COLUMN IF NOT EXISTS collapse_key TEXT NOT NULL DEFAULT '';

ALTER TABLE notification_events
  ADD COLUMN IF NOT EXISTS dedupe_key TEXT NOT NULL DEFAULT '';

UPDATE notification_events
SET dedupe_key = md5(event_type || ':' || user_id || ':' || payload::text)
WHERE dedupe_key = '';

CREATE UNIQUE INDEX IF NOT EXISTS uq_notification_events_user_type_dedupe
  ON notification_events(user_id, event_type, dedupe_key);

CREATE INDEX IF NOT EXISTS idx_notification_events_user_created
  ON notification_events(user_id, created_at DESC);
