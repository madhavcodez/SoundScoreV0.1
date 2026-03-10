import Fastify, { type FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import { createStore } from "./lib/store";
import { ApiError, unauthorized } from "./lib/errors";
import { registerAuthRoutes } from "./modules/auth";
import { registerCatalogRoutes } from "./modules/catalog";
import { registerOpinionRoutes } from "./modules/opinions";
import { registerSocialRoutes } from "./modules/social";
import { registerListRoutes } from "./modules/lists";
import { registerTrustRoutes } from "./modules/trust";
import type { InMemoryStore } from "./types";

declare module "fastify" {
  interface FastifyInstance {
    store: InMemoryStore;
    requireAuth: (request: FastifyRequest) => string;
  }
}

const seedAlbums = (store: InMemoryStore) => {
  [
    ["alb_1", "CHROMAKOPIA", "Tyler, the Creator", 2024, 4.3, 2100],
    ["alb_2", "GNX", "Kendrick Lamar", 2024, 4.1, 1800],
    ["alb_3", "Short n' Sweet", "Sabrina Carpenter", 2024, 3.8, 950],
    ["alb_4", "Brat", "Charli XCX", 2024, 4.0, 3200],
    ["alb_5", "Manning Fireside", "Mk.gee", 2024, 3.9, 620],
    ["alb_6", "The Great Impersonator", "Halsey", 2024, 3.5, 430],
  ].forEach(([id, title, artist, year, avgRating, logCount]) => {
    store.albums.set(id as string, {
      id: id as string,
      title: title as string,
      artist: artist as string,
      year: year as number,
      artworkUrl: null,
      avgRating: avgRating as number,
      logCount: logCount as number,
    });
  });
};

const resolveUserIdFromRequest = (request: FastifyRequest, store: InMemoryStore): string => {
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw unauthorized();
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const session = store.sessions.get(token);
  if (!session) {
    throw unauthorized();
  }
  return session.userId;
};

export const buildServer = () => {
  const app = Fastify({ logger: true });
  const store = createStore();
  seedAlbums(store);

  app.decorate("store", store);
  app.decorate("requireAuth", (request: FastifyRequest) => resolveUserIdFromRequest(request, store));

  app.register(cors, { origin: true });

  app.get("/health", async () => ({ status: "ok", service: "soundscore-backend" }));

  registerAuthRoutes(app, store);
  registerCatalogRoutes(app, store);
  registerOpinionRoutes(app, store);
  registerSocialRoutes(app, store);
  registerListRoutes(app, store);
  registerTrustRoutes(app, store);

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ApiError) {
      return reply.status(error.statusCode).send({
        error: {
          code: error.code,
          message: error.message,
          requestId: request.id,
        },
      });
    }

    app.log.error(error);
    return reply.status(500).send({
      error: {
        code: "INTERNAL_SERVER_ERROR",
        message: "Unexpected server error",
        requestId: request.id,
      },
    });
  });

  return app;
};
