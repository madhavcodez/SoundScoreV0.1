import type { FastifyInstance } from "fastify";
import { CommentActivityRequestSchema, ReactActivityRequestSchema } from "@soundscore/contracts";
import type { InMemoryStore } from "../types";
import { notFound } from "../lib/errors";
import { withIdempotency } from "../lib/idempotency";

export const registerSocialRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.post("/v1/follow/:userId", async (request, reply) => {
    const actorId = app.requireAuth(request);
    const targetUserId = (request.params as { userId: string }).userId;
    if (!store.users.has(targetUserId)) {
      throw notFound("User");
    }

    return withIdempotency(request, reply, store, actorId, async () => {
      const follows = store.follows.get(actorId) ?? new Set<string>();
      follows.add(targetUserId);
      store.follows.set(actorId, follows);
      return { followingUserId: targetUserId, following: true };
    });
  });

  app.delete("/v1/follow/:userId", async (request, reply) => {
    const actorId = app.requireAuth(request);
    const targetUserId = (request.params as { userId: string }).userId;

    return withIdempotency(request, reply, store, actorId, async () => {
      const follows = store.follows.get(actorId) ?? new Set<string>();
      follows.delete(targetUserId);
      store.follows.set(actorId, follows);
      return { followingUserId: targetUserId, following: false };
    });
  });

  app.get("/v1/feed", async (request) => {
    const actorId = app.requireAuth(request);
    const follows = store.follows.get(actorId) ?? new Set<string>();
    const include = new Set<string>([actorId, ...follows]);

    const feed = store.activity
      .filter((event) => include.has(event.actorId))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, 40);

    return {
      items: feed,
      nextCursor: null,
    };
  });

  app.post("/v1/activity/:id/react", async (request, reply) => {
    const actorId = app.requireAuth(request);
    const activityId = (request.params as { id: string }).id;
    ReactActivityRequestSchema.parse(request.body);

    return withIdempotency(request, reply, store, actorId, async () => {
      const event = store.activity.find((item) => item.id === activityId);
      if (!event) {
        throw notFound("Activity");
      }
      event.reactions += 1;
      return { activityId, reactions: event.reactions };
    });
  });

  app.post("/v1/activity/:id/comment", async (request, reply) => {
    const actorId = app.requireAuth(request);
    const activityId = (request.params as { id: string }).id;
    CommentActivityRequestSchema.parse(request.body);

    return withIdempotency(request, reply, store, actorId, async () => {
      const event = store.activity.find((item) => item.id === activityId);
      if (!event) {
        throw notFound("Activity");
      }
      event.comments += 1;
      return { activityId, comments: event.comments };
    });
  });
};
