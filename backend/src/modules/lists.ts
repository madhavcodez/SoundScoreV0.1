import type { FastifyInstance } from "fastify";
import { AddListItemRequestSchema, CreateListRequestSchema } from "@soundscore/contracts";
import type { InMemoryStore } from "../types";
import { notFound } from "../lib/errors";
import { nowIso, uid } from "../lib/util";
import { withIdempotency } from "../lib/idempotency";

export const registerListRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.post("/v1/lists", async (request, reply) => {
    const userId = app.requireAuth(request);
    const payload = CreateListRequestSchema.parse(request.body);

    return withIdempotency(request, reply, store, userId, async () => {
      const now = nowIso();
      const list = {
        id: uid("lst"),
        ownerId: userId,
        title: payload.title,
        note: payload.note ?? null,
        items: [],
        createdAt: now,
        updatedAt: now,
      };
      store.lists.set(list.id, list);
      const user = store.users.get(userId);
      if (user) {
        const listCount = [...store.lists.values()].filter((candidate) => candidate.ownerId === userId).length;
        user.profile = {
          ...user.profile,
          listCount,
        };
      }
      store.activity.unshift({
        id: uid("act"),
        actorId: userId,
        type: "CREATED_LIST",
        object: { type: "list", id: list.id },
        createdAt: now,
        payload: { listId: list.id },
        reactions: 0,
        comments: 0,
      });
      return list;
    });
  });

  app.post("/v1/lists/:id/items", async (request, reply) => {
    const userId = app.requireAuth(request);
    const listId = (request.params as { id: string }).id;
    const payload = AddListItemRequestSchema.parse(request.body);

    return withIdempotency(request, reply, store, userId, async () => {
      const list = store.lists.get(listId);
      if (!list || list.ownerId !== userId) {
        throw notFound("List");
      }
      if (!store.albums.has(payload.albumId)) {
        throw notFound("Album");
      }

      list.items.push({
        albumId: payload.albumId,
        note: payload.note ?? null,
        position: list.items.length + 1,
      });
      list.updatedAt = nowIso();
      store.activity.unshift({
        id: uid("act"),
        actorId: userId,
        type: "ADDED_LIST_ITEM",
        object: { type: "list", id: list.id },
        createdAt: nowIso(),
        payload: { listId, albumId: payload.albumId },
        reactions: 0,
        comments: 0,
      });
      return list;
    });
  });

  app.get("/v1/lists/:id", async (request) => {
    const listId = (request.params as { id: string }).id;
    const list = store.lists.get(listId);
    if (!list) {
      throw notFound("List");
    }
    return list;
  });
};
