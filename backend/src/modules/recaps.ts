import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { withIdempotency } from "../lib/idempotency";
import { queueNotification } from "../lib/notifications";
import { uid } from "../lib/util";

const toDay = (date: Date) => date.toISOString().slice(0, 10);

const computeWeekWindow = () => {
  const end = new Date();
  const start = new Date(end);
  start.setUTCDate(end.getUTCDate() - 6);
  return {
    weekStart: toDay(start),
    weekEnd: toDay(end),
  };
};

const generateRecap = async (db: Db, userId: string) => {
  const { weekStart, weekEnd } = computeWeekWindow();
  const weekStartTs = `${weekStart}T00:00:00.000Z`;

  const logs = await db.query<{ total: number }>(
    `
      SELECT COUNT(*)::int AS total
      FROM listening_events
      WHERE user_id = $1 AND played_at >= $2
    `,
    [userId, weekStartTs],
  );

  const ratings = await db.query<{ album_id: string; value: number }>(
    `
      SELECT album_id, value
      FROM ratings
      WHERE user_id = $1 AND updated_at >= $2
      ORDER BY value DESC, updated_at DESC
      LIMIT 6
    `,
    [userId, weekStartTs],
  );

  const avg = await db.query<{ average: number }>(
    `
      SELECT COALESCE(AVG(value), 0)::real AS average
      FROM ratings
      WHERE user_id = $1 AND updated_at >= $2
    `,
    [userId, weekStartTs],
  );

  const recapPayload = {
    id: uid("rcp"),
    userId,
    weekStart,
    weekEnd,
    totalLogs: logs.rows[0]?.total ?? 0,
    averageRating: Number((avg.rows[0]?.average ?? 0).toFixed(2)),
    topAlbums: ratings.rows.map((row) => ({
      albumId: row.album_id,
      rating: Number(row.value),
    })),
    shareText: `My SoundScore week: ${(logs.rows[0]?.total ?? 0)} logs, avg ${(avg.rows[0]?.average ?? 0).toFixed(2)}★`,
    deepLink: `https://soundscore.app/recaps/weekly/${weekStart}`,
    createdAt: new Date().toISOString(),
  };

  await db.query(
    `
      INSERT INTO recap_snapshots(id, user_id, week_start, week_end, payload)
      VALUES($1, $2, $3, $4, $5::jsonb)
      ON CONFLICT(user_id, week_start, week_end)
      DO UPDATE SET payload = EXCLUDED.payload, created_at = NOW()
    `,
    [recapPayload.id, userId, weekStart, weekEnd, JSON.stringify(recapPayload)],
  );

  await db.query(
    `
      INSERT INTO analytics_events(id, user_id, event_type, payload)
      VALUES($1, $2, 'RECAP_GENERATED', $3::jsonb)
    `,
    [uid("evt"), userId, JSON.stringify({ weekStart, weekEnd })],
  );

  const prefs = await db.query<{ recap_enabled: boolean }>(
    "SELECT recap_enabled FROM notification_preferences WHERE user_id = $1",
    [userId],
  );

  if (!prefs.rowCount || prefs.rows[0].recap_enabled) {
    await queueNotification(
      db,
      userId,
      "RECAP_READY",
      {
        weekStart,
        weekEnd,
        deepLink: recapPayload.deepLink,
      },
      {
        collapseKey: `recap:${weekStart}`,
        dedupeKey: `${userId}:${weekStart}:recap`,
      },
    );
  }

  return recapPayload;
};

export const registerRecapRoutes = (app: FastifyInstance, db: Db) => {
  app.get("/v1/recaps/weekly/latest", async (request) => {
    const userId = await app.requireAuth(request);

    const latest = await db.query<{ payload: Record<string, unknown> }>(
      `
        SELECT payload
        FROM recap_snapshots
        WHERE user_id = $1
        ORDER BY week_end DESC, created_at DESC
        LIMIT 1
      `,
      [userId],
    );

    const recap = latest.rowCount ? latest.rows[0].payload : await generateRecap(db, userId);

    await db.query(
      `
        INSERT INTO analytics_events(id, user_id, event_type, payload)
        VALUES($1, $2, 'RECAP_VIEWED', $3::jsonb)
      `,
      [uid("evt"), userId, JSON.stringify({ recapId: (recap as { id?: string }).id ?? null })],
    );

    return recap;
  });

  app.post("/v1/recaps/weekly/generate", async (request) => {
    const userId = await app.requireAuth(request);

    return withIdempotency(request, db, userId, async () => {
      return generateRecap(db, userId);
    });
  });
};
