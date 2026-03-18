import type { FastifyInstance } from "fastify";
import { AddListItemRequestSchema, CreateListRequestSchema } from "@soundscore/contracts";
import type { Db } from "../db/client";
import { logAuditEvent } from "../lib/audit";
import { notFound } from "../lib/errors";
import { withIdempotency } from "../lib/idempotency";
import { invalidateFeedCacheForUserAndFollowers, queueFollowerNotifications } from "../lib/notifications";
import { nowIso, uid } from "../lib/util";
import { stripHtml } from "../lib/sanitize";

const updateUserListCount = async (db: Db, userId: string) => {
  await db.query(
    `
      UPDATE users
      SET list_count = stat.list_count,
          updated_at = NOW()
      FROM (
        SELECT COUNT(*)::int AS list_count
        FROM lists
        WHERE owner_id = $1
      ) stat
      WHERE users.id = $1
    `,
    [userId],
  );
  await db.redis.del(`profile:${userId}`);
};

export const registerListRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/lists", async (request, reply) => {
    const userId = await app.requireAuth(request);
    const payload = CreateListRequestSchema.parse(request.body);

    return withIdempotency(request, db, userId, async () => {
      const now = nowIso();
      const listId = uid("lst");

      await db.query(
        `
          INSERT INTO lists(id, owner_id, title, note, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, $5)
        `,
        [listId, userId, stripHtml(payload.title), payload.note ? stripHtml(payload.note) : null, now],
      );

      await updateUserListCount(db, userId);

      const activityId = uid("act");
      await db.query(
        `
          INSERT INTO activity_events(id, actor_id, type, object_type, object_id, created_at, payload)
          VALUES ($1, $2, 'CREATED_LIST', 'list', $3, $4, $5::jsonb)
        `,
        [activityId, userId, listId, now, JSON.stringify({ listId })],
      );

      await invalidateFeedCacheForUserAndFollowers(db, userId);
      await queueFollowerNotifications(
        db,
        userId,
        "SOCIAL_LIST",
        {
          actorId: userId,
          activityId,
          listId,
        },
        {
          collapseKey: `actor:${userId}:social`,
          dedupeKey: `${activityId}:social-list`,
        },
      );

      logAuditEvent(db, {
        userId,
        type: "list.create",
        details: { listId },
        ipAddress: request.ip,
        userAgent: request.headers["user-agent"],
      }).catch(() => {});

      return reply.status(201).send({
        id: listId,
        ownerId: userId,
        title: payload.title,
        note: payload.note ?? null,
        items: [],
        createdAt: now,
        updatedAt: now,
      });
    });
  });

  app.post("/v1/lists/:id/items", async (request, reply) => {
    const userId = await app.requireAuth(request);
    const listId = (request.params as { id: string }).id;
    const payload = AddListItemRequestSchema.parse(request.body);

    return withIdempotency(request, db, userId, async () => {
      const list = await db.query<{ id: string; owner_id: string }>(
        "SELECT id, owner_id FROM lists WHERE id = $1",
        [listId],
      );
      if (!list.rowCount || list.rows[0].owner_id !== userId) {
        throw notFound("List");
      }

      const album = await db.query<{ id: string }>("SELECT id FROM albums WHERE id = $1", [payload.albumId]);
      if (!album.rowCount) {
        throw notFound("Album");
      }

      const positionResult = await db.query<{ next_position: number }>(
        "SELECT COALESCE(MAX(position), 0) + 1 AS next_position FROM list_items WHERE list_id = $1",
        [listId],
      );
      const position = positionResult.rows[0].next_position;

      await db.query(
        `
          INSERT INTO list_items(id, list_id, album_id, position, note)
          VALUES ($1, $2, $3, $4, $5)
        `,
        [uid("lit"), listId, payload.albumId, position, payload.note ?? null],
      );

      await db.query("UPDATE lists SET updated_at = NOW() WHERE id = $1", [listId]);

      const activityId = uid("act");
      await db.query(
        `
          INSERT INTO activity_events(id, actor_id, type, object_type, object_id, created_at, payload)
          VALUES ($1, $2, 'ADDED_LIST_ITEM', 'list', $3, NOW(), $4::jsonb)
        `,
        [activityId, userId, listId, JSON.stringify({ listId, albumId: payload.albumId })],
      );

      await invalidateFeedCacheForUserAndFollowers(db, userId);

      const response = await db.query<{
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
          WHERE id = $1
        `,
        [listId],
      );

      const items = await db.query<{
        album_id: string;
        position: number;
        note: string | null;
      }>(
        `
          SELECT album_id, position, note
          FROM list_items
          WHERE list_id = $1
          ORDER BY position ASC
        `,
        [listId],
      );

      return reply.status(201).send({
        id: response.rows[0].id,
        ownerId: response.rows[0].owner_id,
        title: response.rows[0].title,
        note: response.rows[0].note,
        items: items.rows.map((row) => ({
          albumId: row.album_id,
          position: row.position,
          note: row.note,
        })),
        createdAt: response.rows[0].created_at,
        updatedAt: response.rows[0].updated_at,
      });
    });
  });

  app.get("/v1/lists/:id", async (request) => {
    const listId = (request.params as { id: string }).id;

    const list = await db.query<{
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
        WHERE id = $1
      `,
      [listId],
    );

    if (!list.rowCount) {
      throw notFound("List");
    }

    const items = await db.query<{
      album_id: string;
      position: number;
      note: string | null;
    }>(
      `
        SELECT album_id, position, note
        FROM list_items
        WHERE list_id = $1
        ORDER BY position ASC
      `,
      [listId],
    );

    return {
      id: list.rows[0].id,
      ownerId: list.rows[0].owner_id,
      title: list.rows[0].title,
      note: list.rows[0].note,
      items: items.rows.map((row) => ({
        albumId: row.album_id,
        position: row.position,
        note: row.note,
      })),
      createdAt: list.rows[0].created_at,
      updatedAt: list.rows[0].updated_at,
    };
  });
};
