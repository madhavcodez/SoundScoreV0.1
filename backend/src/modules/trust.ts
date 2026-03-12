import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";

export const registerTrustRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/account/export", async (request) => {
    const userId = await app.requireAuth(request);

    const profile = await db.query<{
      id: string;
      handle: string;
      bio: string;
      log_count: number;
      review_count: number;
      list_count: number;
      avg_rating: number;
    }>(
      `
        SELECT id, handle, bio, log_count, review_count, list_count, avg_rating
        FROM users
        WHERE id = $1
      `,
      [userId],
    );

    const ratings = await db.query<{
      id: string;
      user_id: string;
      album_id: string;
      value: number;
      created_at: string;
      updated_at: string;
    }>(
      `
        SELECT id, user_id, album_id, value, created_at, updated_at
        FROM ratings
        WHERE user_id = $1
      `,
      [userId],
    );

    const reviews = await db.query<{
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
        WHERE user_id = $1
      `,
      [userId],
    );

    const listRows = await db.query<{
      id: string;
      owner_id: string;
      title: string;
      note: string | null;
      created_at: string;
      updated_at: string;
    }>(
      `
        SELECT id, owner_id, title, note, created_at, updated_at
        FROM lists
        WHERE owner_id = $1
      `,
      [userId],
    );

    const listItems = await db.query<{
      list_id: string;
      album_id: string;
      position: number;
      note: string | null;
    }>(
      `
        SELECT list_id, album_id, position, note
        FROM list_items
        WHERE list_id = ANY($1::text[])
      `,
      [listRows.rows.map((list) => list.id)],
    );

    const following = await db.query<{ followee_id: string }>(
      "SELECT followee_id FROM follows WHERE follower_id = $1",
      [userId],
    );

    const listeningEvents = await db.query<{
      id: string;
      user_id: string;
      album_id: string;
      played_at: string;
      source: string;
      source_ref: Record<string, unknown>;
    }>(
      `
        SELECT id, user_id, album_id, played_at, source, source_ref
        FROM listening_events
        WHERE user_id = $1
      `,
      [userId],
    );

    const activity = await db.query<{
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
        WHERE actor_id = $1
      `,
      [userId],
    );

    return {
      generatedAt: new Date().toISOString(),
      profile: profile.rowCount
        ? {
            id: profile.rows[0].id,
            handle: profile.rows[0].handle,
            bio: profile.rows[0].bio,
            logCount: profile.rows[0].log_count,
            reviewCount: profile.rows[0].review_count,
            listCount: profile.rows[0].list_count,
            avgRating: Number(profile.rows[0].avg_rating),
          }
        : null,
      ratings: ratings.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        albumId: row.album_id,
        value: Number(row.value),
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      })),
      reviews: reviews.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        albumId: row.album_id,
        body: row.body,
        revision: row.revision,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      })),
      lists: listRows.rows.map((list) => ({
        id: list.id,
        ownerId: list.owner_id,
        title: list.title,
        note: list.note,
        items: listItems.rows
          .filter((item) => item.list_id === list.id)
          .sort((a, b) => a.position - b.position)
          .map((item) => ({
            albumId: item.album_id,
            position: item.position,
            note: item.note,
          })),
        createdAt: list.created_at,
        updatedAt: list.updated_at,
      })),
      following: following.rows.map((row) => row.followee_id),
      listeningEvents: listeningEvents.rows.map((row) => ({
        id: row.id,
        userId: row.user_id,
        albumId: row.album_id,
        playedAt: row.played_at,
        source: row.source,
        sourceRef: row.source_ref,
      })),
      activity: activity.rows.map((row) => ({
        id: row.id,
        actorId: row.actor_id,
        type: row.type,
        object: { type: row.object_type, id: row.object_id },
        createdAt: row.created_at,
        payload: row.payload,
        reactions: row.reactions,
        comments: row.comments,
      })),
    };
  });

  app.delete("/v1/account", async (request, reply) => {
    const userId = await app.requireAuth(request);

    await db.query("DELETE FROM users WHERE id = $1", [userId]);

    await db.redis.del(
      `profile:${userId}`,
      `feed:${userId}:page1`,
    );

    reply.code(204).send();
  });

  app.post("/v1/providers/:provider/connect", async (_request, reply) => {
    return reply.code(501).send({
      code: "PROVIDER_NOT_ENABLED",
      message: "Provider connections are out of scope for provider-free phase 1",
    });
  });

  app.post("/v1/providers/:provider/disconnect", async (_request, reply) => {
    return reply.code(501).send({
      code: "PROVIDER_NOT_ENABLED",
      message: "Provider connections are out of scope for provider-free phase 1",
    });
  });
};
