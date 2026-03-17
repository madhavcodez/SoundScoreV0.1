import type { FastifyInstance } from "fastify";
import {
  CreateRatingRequestSchema,
  CreateReviewRequestSchema,
  UpdateReviewRequestSchema,
} from "@soundscore/contracts";
import type { Db } from "../db/client";
import { logAuditEvent } from "../lib/audit";
import { conflict, notFound } from "../lib/errors";
import { withIdempotency } from "../lib/idempotency";
import {
  invalidateFeedCacheForUserAndFollowers,
  queueFollowerNotifications,
} from "../lib/notifications";
import { nowIso, uid } from "../lib/util";

const updateUserAndAlbumAggregates = async (db: Db, userId: string, albumId: string) => {
  await db.query(
    `
      UPDATE users
      SET log_count = stat.log_count,
          avg_rating = stat.avg_rating,
          updated_at = NOW()
      FROM (
        SELECT
          COUNT(*)::int AS log_count,
          COALESCE(AVG(value), 0)::real AS avg_rating
        FROM ratings
        WHERE user_id = $1
      ) stat
      WHERE users.id = $1
    `,
    [userId],
  );

  await db.query(
    `
      UPDATE albums
      SET avg_rating = stat.avg_rating,
          log_count = stat.log_count
      FROM (
        SELECT
          COALESCE(AVG(value), 0)::real AS avg_rating,
          COUNT(*)::int AS log_count
        FROM ratings
        WHERE album_id = $1
      ) stat
      WHERE albums.id = $1
    `,
    [albumId],
  );
};

export const registerOpinionRoutes = (app: FastifyInstance, db: Db) => {
  app.get("/v1/log/recently-played", async (request) => {
    const userId = await app.requireAuth(request);

    const recentlyPlayed = await db.query<{
      id: string;
      user_id: string;
      album_id: string;
      played_at: string;
      source: "manual" | "spotify" | "apple";
      source_ref: Record<string, unknown>;
    }>(
      `
        SELECT id, user_id, album_id, played_at, source, source_ref
        FROM listening_events
        WHERE user_id = $1
        ORDER BY played_at DESC
        LIMIT 30
      `,
      [userId],
    );

    return {
      items: recentlyPlayed.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        albumId: row.album_id,
        playedAt: row.played_at,
        source: row.source,
        sourceRef: row.source_ref,
      })),
      nextCursor: null,
    };
  });

  app.post("/v1/ratings", async (request) => {
    const userId = await app.requireAuth(request);
    const payload = CreateRatingRequestSchema.parse(request.body);

    const albumExists = await db.query<{ id: string }>("SELECT id FROM albums WHERE id = $1", [payload.albumId]);
    if (!albumExists.rowCount) {
      throw notFound("Album");
    }

    return withIdempotency(request, db, userId, async () => {
      const now = nowIso();
      const ratingId = uid("rat");

      const ratingResult = await db.query<{
        id: string;
        user_id: string;
        album_id: string;
        value: number;
        created_at: string;
        updated_at: string;
      }>(
        `
          INSERT INTO ratings (id, user_id, album_id, value, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $5)
          ON CONFLICT (user_id, album_id)
          DO UPDATE SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at
          RETURNING id, user_id, album_id, value, created_at, updated_at
        `,
        [ratingId, userId, payload.albumId, payload.value, now],
      );

      await db.query(
        `
          INSERT INTO listening_events(id, user_id, album_id, played_at, source, source_ref)
          VALUES ($1, $2, $3, $4, 'manual', '{}'::jsonb)
        `,
        [uid("lst"), userId, payload.albumId, now],
      );

      const activityId = uid("act");
      await db.query(
        `
          INSERT INTO activity_events(id, actor_id, type, object_type, object_id, created_at, payload)
          VALUES ($1, $2, 'RATED_ALBUM', 'album', $3, $4, $5::jsonb)
        `,
        [activityId, userId, payload.albumId, now, JSON.stringify({ albumId: payload.albumId, rating: payload.value })],
      );

      await updateUserAndAlbumAggregates(db, userId, payload.albumId);
      await db.redis.del(`profile:${userId}`);
      await invalidateFeedCacheForUserAndFollowers(db, userId);
      await queueFollowerNotifications(
        db,
        userId,
        "SOCIAL_RATING",
        {
          actorId: userId,
          activityId,
          albumId: payload.albumId,
          rating: payload.value,
        },
        {
          collapseKey: `actor:${userId}:social`,
          dedupeKey: `${activityId}:social-rating`,
        },
      );

      logAuditEvent(db, {
        userId,
        type: "rating.create",
        details: { albumId: payload.albumId, value: payload.value },
        ipAddress: request.ip,
        userAgent: request.headers["user-agent"],
      }).catch(() => {});

      const rating = ratingResult.rows[0];
      return {
        id: rating.id,
        userId: rating.user_id,
        albumId: rating.album_id,
        value: Number(rating.value),
        createdAt: rating.created_at,
        updatedAt: rating.updated_at,
      };
    });
  });

  app.post("/v1/reviews", async (request) => {
    const userId = await app.requireAuth(request);
    const payload = CreateReviewRequestSchema.parse(request.body);

    const albumExists = await db.query<{ id: string }>("SELECT id FROM albums WHERE id = $1", [payload.albumId]);
    if (!albumExists.rowCount) {
      throw notFound("Album");
    }

    return withIdempotency(request, db, userId, async () => {
      const now = nowIso();
      const reviewId = uid("rev");

      const reviewResult = await db.query<{
        id: string;
        user_id: string;
        album_id: string;
        body: string;
        revision: number;
        created_at: string;
        updated_at: string;
      }>(
        `
          INSERT INTO reviews(id, user_id, album_id, body, revision, created_at, updated_at)
          VALUES ($1, $2, $3, $4, 0, $5, $5)
          RETURNING id, user_id, album_id, body, revision, created_at, updated_at
        `,
        [reviewId, userId, payload.albumId, payload.body, now],
      );

      const activityId = uid("act");
      await db.query(
        `
          INSERT INTO activity_events(id, actor_id, type, object_type, object_id, created_at, payload)
          VALUES ($1, $2, 'WROTE_REVIEW', 'review', $3, $4, $5::jsonb)
        `,
        [activityId, userId, reviewId, now, JSON.stringify({ albumId: payload.albumId, reviewId })],
      );

      await db.query(
        `
          UPDATE users
          SET review_count = stat.review_count,
              updated_at = NOW()
          FROM (
            SELECT COUNT(*)::int AS review_count
            FROM reviews
            WHERE user_id = $1
          ) stat
          WHERE users.id = $1
        `,
        [userId],
      );

      await db.redis.del(`profile:${userId}`);
      await invalidateFeedCacheForUserAndFollowers(db, userId);
      await queueFollowerNotifications(
        db,
        userId,
        "SOCIAL_REVIEW",
        {
          actorId: userId,
          activityId,
          albumId: payload.albumId,
          reviewId,
        },
        {
          collapseKey: `actor:${userId}:social`,
          dedupeKey: `${activityId}:social-review`,
        },
      );

      logAuditEvent(db, {
        userId,
        type: "review.create",
        details: { albumId: payload.albumId, reviewId },
        ipAddress: request.ip,
        userAgent: request.headers["user-agent"],
      }).catch(() => {});

      const review = reviewResult.rows[0];
      return {
        id: review.id,
        userId: review.user_id,
        albumId: review.album_id,
        body: review.body,
        revision: review.revision,
        createdAt: review.created_at,
        updatedAt: review.updated_at,
      };
    });
  });

  app.put("/v1/reviews/:id", async (request) => {
    const userId = await app.requireAuth(request);
    const reviewId = (request.params as { id: string }).id;
    const payload = UpdateReviewRequestSchema.parse(request.body);

    return withIdempotency(request, db, userId, async () => {
      const review = await db.query<{
        id: string;
        user_id: string;
        album_id: string;
        body: string;
        revision: number;
        created_at: string;
        updated_at: string;
      }>(
        `
          SELECT id, user_id, album_id, body, revision, created_at, updated_at
          FROM reviews
          WHERE id = $1
        `,
        [reviewId],
      );

      if (!review.rowCount || review.rows[0].user_id !== userId) {
        throw notFound("Review");
      }
      if (review.rows[0].revision !== payload.expectedRevision) {
        throw conflict("REVIEW_REVISION_CONFLICT", "Review has been updated on another device");
      }

      const updated = await db.query<{
        id: string;
        user_id: string;
        album_id: string;
        body: string;
        revision: number;
        created_at: string;
        updated_at: string;
      }>(
        `
          UPDATE reviews
          SET body = $2,
              revision = revision + 1,
              updated_at = NOW()
          WHERE id = $1
          RETURNING id, user_id, album_id, body, revision, created_at, updated_at
        `,
        [reviewId, payload.body],
      );

      logAuditEvent(db, {
        userId,
        type: "review.update",
        details: { reviewId, revision: updated.rows[0].revision },
        ipAddress: request.ip,
        userAgent: request.headers["user-agent"],
      }).catch(() => {});

      const row = updated.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        albumId: row.album_id,
        body: row.body,
        revision: row.revision,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    });
  });
};
