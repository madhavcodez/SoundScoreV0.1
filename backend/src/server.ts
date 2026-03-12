import Fastify, { type FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import { ApiError, unauthorized } from "./lib/errors";
import { registerAuthRoutes } from "./modules/auth";
import { registerCatalogRoutes } from "./modules/catalog";
import { registerOpinionRoutes } from "./modules/opinions";
import { registerSocialRoutes } from "./modules/social";
import { registerListRoutes } from "./modules/lists";
import { registerTrustRoutes } from "./modules/trust";
import { registerRecapRoutes } from "./modules/recaps";
import { registerPushRoutes } from "./modules/push";
import { createDb, type Db } from "./db/client";
import { runMigrations } from "./db/runMigrations";

declare module "fastify" {
  interface FastifyInstance {
    db: Db;
    requireAuth: (request: FastifyRequest) => Promise<string>;
  }
}

const resolveUserIdFromRequest = async (request: FastifyRequest, db: Db): Promise<string> => {
  const authHeader = request.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    throw unauthorized();
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const session = await db.query<{ user_id: string }>(
    "SELECT user_id FROM sessions WHERE access_token = $1",
    [token],
  );

  if (!session.rowCount) {
    throw unauthorized();
  }
  return session.rows[0].user_id;
};

export const buildServer = async () => {
  const app = Fastify({ logger: true });
  const db = createDb();
  await runMigrations(db);

  app.decorate("db", db);
  app.decorate("requireAuth", (request: FastifyRequest) => resolveUserIdFromRequest(request, db));

  app.register(cors, { origin: true });
  app.register(rateLimit, {
    global: true,
    max: 100,
    timeWindow: "1 minute",
    addHeadersOnExceeding: {
      "x-ratelimit-limit": true,
      "x-ratelimit-remaining": true,
      "x-ratelimit-reset": true,
    },
  });

  app.get("/health", async () => ({
    status: "ok",
    service: "soundscore-backend",
    checks: {
      postgres: "up",
      redis: db.redis.status,
    },
  }));

  registerAuthRoutes(app, db);
  registerCatalogRoutes(app, db);
  registerOpinionRoutes(app, db);
  registerSocialRoutes(app, db);
  registerListRoutes(app, db);
  registerTrustRoutes(app, db);
  registerPushRoutes(app, db);
  registerRecapRoutes(app, db);

  app.addHook("onRequest", (request, _reply, done) => {
    // Attach start timestamp for latency logging.
    (request as FastifyRequest & { _startedAt?: bigint })._startedAt = process.hrtime.bigint();
    done();
  });

  app.addHook("onResponse", (request, reply, done) => {
    const startedAt = (request as FastifyRequest & { _startedAt?: bigint })._startedAt;
    if (startedAt) {
      const elapsedMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
      const routePath = request.routeOptions.url ?? request.url;
      app.log.info(
        {
          path: routePath,
          method: request.method,
          statusCode: reply.statusCode,
          latencyMs: Number(elapsedMs.toFixed(2)),
        },
        "request_complete",
      );
    }
    done();
  });

  app.addHook("onClose", async () => {
    await db.close();
  });

  app.setErrorHandler((error: unknown, request, reply) => {
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
