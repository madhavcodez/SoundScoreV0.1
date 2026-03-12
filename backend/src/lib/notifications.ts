import { createHash } from "node:crypto";
import type { Db } from "../db/client";
import { uid } from "./util";

type NotificationOptions = {
  collapseKey?: string;
  dedupeKey?: string;
};

const SENSITIVE_FIELDS = new Set([
  "body",
  "content",
  "message",
  "email",
  "phone",
  "token",
  "deviceToken",
  "accessToken",
  "refreshToken",
]);

const sanitizePayload = (payload: Record<string, unknown>): Record<string, unknown> =>
  Object.fromEntries(
    Object.entries(payload).filter(
      ([key, value]) => !SENSITIVE_FIELDS.has(key) && value !== undefined,
    ),
  );

const stableStringify = (value: unknown): string => {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((entry) => stableStringify(entry)).join(",")}]`;
  }
  const entries = Object.entries(value as Record<string, unknown>).sort(([a], [b]) =>
    a.localeCompare(b),
  );
  return `{${entries
    .map(([key, entryValue]) => `${JSON.stringify(key)}:${stableStringify(entryValue)}`)
    .join(",")}}`;
};

const toDedupeKey = (eventType: string, payload: Record<string, unknown>, dedupeKey?: string) =>
  dedupeKey ??
  createHash("sha256")
    .update(`${eventType}:${stableStringify(payload)}`)
    .digest("hex")
    .slice(0, 32);

export const queueNotification = async (
  db: Db,
  userId: string,
  eventType: string,
  payload: Record<string, unknown>,
  options: NotificationOptions = {},
) => {
  const safePayload = sanitizePayload(payload);
  const collapseKey = options.collapseKey ?? "";
  const dedupeKey = toDedupeKey(eventType, safePayload, options.dedupeKey);

  await db.query(
    `
      INSERT INTO notification_events(id, user_id, event_type, payload, collapse_key, dedupe_key)
      VALUES ($1, $2, $3, $4::jsonb, $5, $6)
      ON CONFLICT (user_id, event_type, dedupe_key)
      DO UPDATE
      SET payload = EXCLUDED.payload,
          collapse_key = EXCLUDED.collapse_key,
          is_sent = FALSE,
          created_at = NOW()
    `,
    [uid("not"), userId, eventType, JSON.stringify(safePayload), collapseKey, dedupeKey],
  );
};

export const queueFollowerNotifications = async (
  db: Db,
  actorId: string,
  eventType: string,
  payload: Record<string, unknown>,
  options: NotificationOptions = {},
) => {
  const followers = await db.query<{ follower_id: string }>(
    `SELECT follower_id FROM follows WHERE followee_id = $1`,
    [actorId],
  );

  for (const row of followers.rows) {
    const prefs = await db.query<{
      social_enabled: boolean;
      comment_enabled: boolean;
      reaction_enabled: boolean;
    }>(
      `
        SELECT social_enabled, comment_enabled, reaction_enabled
        FROM notification_preferences
        WHERE user_id = $1
      `,
      [row.follower_id],
    );

    const settings = prefs.rows[0];
    const allowSocial = settings ? settings.social_enabled : true;
    if (allowSocial && row.follower_id !== actorId) {
      await queueNotification(db, row.follower_id, eventType, payload, options);
    }
  }
};

export const invalidateFeedCacheForUserAndFollowers = async (db: Db, actorId: string) => {
  const followers = await db.query<{ follower_id: string }>(
    `SELECT follower_id FROM follows WHERE followee_id = $1`,
    [actorId],
  );

  const keys = [
    `feed:${actorId}:page1`,
    ...followers.rows.map((row) => `feed:${row.follower_id}:page1`),
  ];

  if (keys.length > 0) {
    await db.redis.del(...keys);
  }
};
