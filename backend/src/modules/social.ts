import type { FastifyInstance } from "fastify";
import { CommentActivityRequestSchema, ReactActivityRequestSchema } from "@soundscore/contracts";
import type { Db } from "../db/client";
import { notFound } from "../lib/errors";
import { withIdempotency } from "../lib/idempotency";
import { invalidateFeedCacheForUserAndFollowers, queueNotification } from "../lib/notifications";

const FEED_CACHE_TTL_SECONDS = 90;

export const registerSocialRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/follow/:userId", async (request) => {
    const actorId = await app.requireAuth(request);
    const targetUserId = (request.params as { userId: string }).userId;

    const target = await db.query<{ id: string }>("SELECT id FROM users WHERE id = $1", [targetUserId]);
    if (!target.rowCount) {
      throw notFound("User");
    }

    return withIdempotency(request, db, actorId, async () => {
      await db.query(
        `
          INSERT INTO follows(follower_id, followee_id)
          VALUES ($1, $2)
          ON CONFLICT(follower_id, followee_id) DO NOTHING
        `,
        [actorId, targetUserId],
      );

      await db.redis.del(`feed:${actorId}:page1`);
      return { followingUserId: targetUserId, following: true };
    });
  });

  app.delete("/v1/follow/:userId", async (request) => {
    const actorId = await app.requireAuth(request);
    const targetUserId = (request.params as { userId: string }).userId;

    return withIdempotency(request, db, actorId, async () => {
      await db.query(
        `
          DELETE FROM follows
          WHERE follower_id = $1 AND followee_id = $2
        `,
        [actorId, targetUserId],
      );

      await db.redis.del(`feed:${actorId}:page1`);
      return { followingUserId: targetUserId, following: false };
    });
  });

  app.get("/v1/feed", async (request) => {
    const actorId = await app.requireAuth(request);
    const cacheKey = `feed:${actorId}:page1`;
    const cached = await db.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached) as unknown;
    }

    const follows = await db.query<{ followee_id: string }>(
      "SELECT followee_id FROM follows WHERE follower_id = $1",
      [actorId],
    );

    const actorIds = [actorId, ...follows.rows.map((row) => row.followee_id)];
    const feed = await db.query<{
      id: string;
      actor_id: string;
      type: string;
      object_type: string;
      object_id: string;
      created_at: string;
      payload: Record<string, unknown>;
      reactions: number;
      comments: number;
    }>(
      `
        SELECT id, actor_id, type, object_type, object_id, created_at, payload, reactions, comments
        FROM activity_events
        WHERE actor_id = ANY($1::text[])
        ORDER BY created_at DESC
        LIMIT 40
      `,
      [actorIds],
    );

    const response = {
      items: feed.rows.map((row) => ({
        id: row.id,
        actorId: row.actor_id,
        type: row.type,
        object: {
          type: row.object_type,
          id: row.object_id,
        },
        createdAt: row.created_at,
        payload: row.payload,
        reactions: row.reactions,
        comments: row.comments,
      })),
      nextCursor: null,
    };

    await db.redis.setex(cacheKey, FEED_CACHE_TTL_SECONDS, JSON.stringify(response));
    return response;
  });

  app.post("/v1/activity/:id/react", async (request) => {
    const actorId = await app.requireAuth(request);
    const activityId = (request.params as { id: string }).id;
    ReactActivityRequestSchema.parse(request.body);

    return withIdempotency(request, db, actorId, async () => {
      const event = await db.query<{ reactions: number; actor_id: string }>(
        `
          UPDATE activity_events
          SET reactions = reactions + 1
          WHERE id = $1
          RETURNING reactions, actor_id
        `,
        [activityId],
      );

      if (!event.rowCount) {
        throw notFound("Activity");
      }

      const ownerId = event.rows[0].actor_id;
      if (ownerId !== actorId) {
        const pref = await db.query<{ reaction_enabled: boolean }>(
          "SELECT reaction_enabled FROM notification_preferences WHERE user_id = $1",
          [ownerId],
        );
        const canNotify = pref.rowCount ? pref.rows[0].reaction_enabled : true;
        if (canNotify) {
          await queueNotification(
            db,
            ownerId,
            "REACTION",
            {
              actorId,
              activityId,
            },
            {
              collapseKey: `activity:${activityId}:reaction`,
              dedupeKey: `${activityId}:${actorId}:reaction`,
            },
          );
        }
      }

      await invalidateFeedCacheForUserAndFollowers(db, ownerId);
      return { activityId, reactions: event.rows[0].reactions };
    });
  });

  app.post("/v1/activity/:id/comment", async (request) => {
    const actorId = await app.requireAuth(request);
    const activityId = (request.params as { id: string }).id;
    CommentActivityRequestSchema.parse(request.body);

    return withIdempotency(request, db, actorId, async () => {
      const event = await db.query<{ comments: number; actor_id: string }>(
        `
          UPDATE activity_events
          SET comments = comments + 1
          WHERE id = $1
          RETURNING comments, actor_id
        `,
        [activityId],
      );

      if (!event.rowCount) {
        throw notFound("Activity");
      }

      const ownerId = event.rows[0].actor_id;
      if (ownerId !== actorId) {
        const pref = await db.query<{ comment_enabled: boolean }>(
          "SELECT comment_enabled FROM notification_preferences WHERE user_id = $1",
          [ownerId],
        );
        const canNotify = pref.rowCount ? pref.rows[0].comment_enabled : true;
        if (canNotify) {
          await queueNotification(
            db,
            ownerId,
            "COMMENT",
            {
              actorId,
              activityId,
            },
            {
              collapseKey: `activity:${activityId}:comment`,
              dedupeKey: `${activityId}:${actorId}:comment`,
            },
          );
        }
      }

      await invalidateFeedCacheForUserAndFollowers(db, ownerId);
      return { activityId, comments: event.rows[0].comments };
    });
  });
};
