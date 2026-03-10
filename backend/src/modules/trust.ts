import type { FastifyInstance } from "fastify";
import type { InMemoryStore } from "../types";

export const registerTrustRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.post("/v1/account/export", async (request) => {
    const userId = app.requireAuth(request);
    const profile = store.users.get(userId)?.profile;
    const following = [...(store.follows.get(userId) ?? [])];

    return {
      generatedAt: new Date().toISOString(),
      profile,
      ratings: [...store.ratings.values()].filter((item) => item.userId === userId),
      reviews: [...store.reviews.values()].filter((item) => item.userId === userId),
      lists: [...store.lists.values()].filter((item) => item.ownerId === userId),
      following,
      listeningEvents: store.listeningEvents.filter((item) => item.userId === userId),
      activity: store.activity.filter((item) => item.actorId === userId),
    };
  });

  app.delete("/v1/account", async (request, reply) => {
    const userId = app.requireAuth(request);
    const user = store.users.get(userId);
    if (!user) {
      return reply.code(204).send();
    }

    store.users.delete(userId);
    store.usersByEmail.delete(user.email);
    store.follows.delete(userId);

    for (const [key, session] of store.sessions.entries()) {
      if (session.userId === userId) {
        store.sessions.delete(key);
      }
    }
    for (const [key, rating] of store.ratings.entries()) {
      if (rating.userId === userId) {
        store.ratings.delete(key);
      }
    }
    for (const [key, review] of store.reviews.entries()) {
      if (review.userId === userId) {
        store.reviews.delete(key);
      }
    }
    for (const [key, list] of store.lists.entries()) {
      if (list.ownerId === userId) {
        store.lists.delete(key);
      }
    }

    store.listeningEvents = store.listeningEvents.filter((item) => item.userId !== userId);
    store.activity = store.activity.filter((item) => item.actorId !== userId);
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
