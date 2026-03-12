import type { FastifyInstance } from "fastify";
import {
  RegisterDeviceTokenRequestSchema,
  UpsertNotificationPreferenceSchema,
} from "@soundscore/contracts";
import type { Db } from "../db/client";
import { withIdempotency } from "../lib/idempotency";
import { queueNotification } from "../lib/notifications";
import { uid } from "../lib/util";

const defaultPreferences = {
  socialEnabled: true,
  recapEnabled: true,
  commentEnabled: true,
  reactionEnabled: true,
  quietHoursStart: 22,
  quietHoursEnd: 7,
};

export const registerPushRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/push/tokens", async (request) => {
    const userId = await app.requireAuth(request);
    const payload = RegisterDeviceTokenRequestSchema.parse(request.body);

    return withIdempotency(request, db, userId, async () => {
      const id = uid("dvc");
      await db.query(
        `
          INSERT INTO device_tokens(id, user_id, platform, device_token)
          VALUES ($1, $2, $3, $4)
          ON CONFLICT(device_token)
          DO UPDATE SET user_id = EXCLUDED.user_id, platform = EXCLUDED.platform, last_seen_at = NOW()
        `,
        [id, userId, payload.platform, payload.deviceToken],
      );

      const token = await db.query<{
        id: string;
        user_id: string;
        platform: string;
        device_token: string;
        created_at: string;
        last_seen_at: string;
      }>(
        `
          SELECT id, user_id, platform, device_token, created_at, last_seen_at
          FROM device_tokens
          WHERE device_token = $1
        `,
        [payload.deviceToken],
      );

      return {
        id: token.rows[0].id,
        userId: token.rows[0].user_id,
        platform: token.rows[0].platform,
        deviceToken: token.rows[0].device_token,
        createdAt: token.rows[0].created_at,
        lastSeenAt: token.rows[0].last_seen_at,
      };
    });
  });

  app.delete("/v1/push/tokens/:deviceToken", async (request) => {
    const userId = await app.requireAuth(request);
    const deviceToken = (request.params as { deviceToken: string }).deviceToken;

    return withIdempotency(request, db, userId, async () => {
      await db.query(
        "DELETE FROM device_tokens WHERE user_id = $1 AND device_token = $2",
        [userId, deviceToken],
      );
      return { removed: true, deviceToken };
    });
  });

  app.get("/v1/push/preferences", async (request) => {
    const userId = await app.requireAuth(request);

    const prefs = await db.query<{
      social_enabled: boolean;
      recap_enabled: boolean;
      comment_enabled: boolean;
      reaction_enabled: boolean;
      quiet_hours_start: number;
      quiet_hours_end: number;
    }>(
      `
        SELECT social_enabled, recap_enabled, comment_enabled, reaction_enabled, quiet_hours_start, quiet_hours_end
        FROM notification_preferences
        WHERE user_id = $1
      `,
      [userId],
    );

    if (!prefs.rowCount) {
      await db.query(
        "INSERT INTO notification_preferences(user_id) VALUES($1) ON CONFLICT(user_id) DO NOTHING",
        [userId],
      );
      return defaultPreferences;
    }

    return {
      socialEnabled: prefs.rows[0].social_enabled,
      recapEnabled: prefs.rows[0].recap_enabled,
      commentEnabled: prefs.rows[0].comment_enabled,
      reactionEnabled: prefs.rows[0].reaction_enabled,
      quietHoursStart: prefs.rows[0].quiet_hours_start,
      quietHoursEnd: prefs.rows[0].quiet_hours_end,
    };
  });

  app.put("/v1/push/preferences", async (request) => {
    const userId = await app.requireAuth(request);
    const payload = UpsertNotificationPreferenceSchema.parse(request.body);

    return withIdempotency(request, db, userId, async () => {
      await db.query(
        `
          INSERT INTO notification_preferences(
            user_id,
            social_enabled,
            recap_enabled,
            comment_enabled,
            reaction_enabled,
            quiet_hours_start,
            quiet_hours_end,
            updated_at
          ) VALUES($1, $2, $3, $4, $5, $6, $7, NOW())
          ON CONFLICT(user_id)
          DO UPDATE SET
            social_enabled = EXCLUDED.social_enabled,
            recap_enabled = EXCLUDED.recap_enabled,
            comment_enabled = EXCLUDED.comment_enabled,
            reaction_enabled = EXCLUDED.reaction_enabled,
            quiet_hours_start = EXCLUDED.quiet_hours_start,
            quiet_hours_end = EXCLUDED.quiet_hours_end,
            updated_at = NOW()
        `,
        [
          userId,
          payload.socialEnabled,
          payload.recapEnabled,
          payload.commentEnabled,
          payload.reactionEnabled,
          payload.quietHoursStart,
          payload.quietHoursEnd,
        ],
      );

      return payload;
    });
  });

  app.get("/v1/notifications", async (request) => {
    const userId = await app.requireAuth(request);

    const events = await db.query<{
      id: string;
      event_type: string;
      payload: Record<string, unknown>;
      is_sent: boolean;
      created_at: string;
    }>(
      `
        SELECT id, event_type, payload, is_sent, created_at
        FROM notification_events
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT 50
      `,
      [userId],
    );

    return {
      items: events.rows.map((row) => ({
        id: row.id,
        eventType: row.event_type,
        payload: row.payload,
        isSent: row.is_sent,
        createdAt: row.created_at,
      })),
      nextCursor: null,
    };
  });

  app.post("/v1/notifications/test-recap", async (request) => {
    const userId = await app.requireAuth(request);

    return withIdempotency(request, db, userId, async () => {
      const weekStart = new Date().toISOString().slice(0, 10);
      await queueNotification(
        db,
        userId,
        "RECAP_READY",
        {
          deepLink: `https://soundscore.app/recaps/weekly/${weekStart}`,
        },
        {
          collapseKey: `recap:${weekStart}`,
          dedupeKey: `${userId}:${weekStart}:recap-test`,
        },
      );

      await db.query(
        `
          INSERT INTO analytics_events(id, user_id, event_type, payload)
          VALUES($1, $2, 'NOTIFICATION_TEST_SENT', $3::jsonb)
        `,
        [uid("evt"), userId, JSON.stringify({ type: "RECAP_READY" })],
      );

      return { queued: true };
    });
  });
};
