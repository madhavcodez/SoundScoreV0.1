import Fastify, { type FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import { ApiError, unauthorized } from "./lib/errors";
import { applyRouteRateLimits } from "./lib/rate-limit";
import { registerAuthRoutes } from "./modules/auth";
import { registerCatalogRoutes } from "./modules/catalog";
import { registerOpinionRoutes } from "./modules/opinions";
import { registerSocialRoutes } from "./modules/social";
import { registerListRoutes } from "./modules/lists";
import { registerTrustRoutes } from "./modules/trust";
import { registerRecapRoutes } from "./modules/recaps";
import { registerPushRoutes } from "./modules/push";
import { registerProviderRoutes } from "./modules/providers";
import { registerMappingRoutes } from "./modules/mapping";
import { registerImportRoutes } from "./modules/import";
import { createDb, type Db } from "./db/client";
import { runMigrations } from "./db/runMigrations";
import { env } from "./config/env";
import { uid } from "./lib/util";

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
    "SELECT user_id FROM sessions WHERE access_token = $1 AND expires_at > NOW()",
    [token],
  );

  if (!session.rowCount) {
    throw unauthorized();
  }
  return session.rows[0].user_id;
};

export const buildServer = async () => {
  const app = Fastify({
    logger: {
      level: env.app.logLevel,
      serializers: {
        req: (req) => ({
          method: req.method,
          url: req.url,
          remoteAddress: req.ip,
        }),
      },
    },
    requestIdHeader: "x-request-id",
    genReqId: () => uid("req"),
  });

  const db = createDb();
  try {
    await runMigrations(db);
  } catch (error) {
    await db.close();
    throw error;
  }

  app.decorate("db", db);
  app.decorate("requireAuth", (request: FastifyRequest) => resolveUserIdFromRequest(request, db));

  // OpenAPI documentation
  await app.register(swagger, {
    openapi: {
      info: {
        title: "SoundScore API",
        description: "Music logging & social discovery platform",
        version: "0.1.0",
      },
      servers: [{ url: `http://localhost:${env.app.port}` }],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: "http",
            scheme: "bearer",
          },
        },
      },
    },
  });
  await app.register(swaggerUi, { routePrefix: "/docs" });

  // Security headers (API-only, no CSP needed)
  app.register(helmet, {
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
  });

  // CORS with explicit origin allowlist
  app.register(cors, {
    origin: env.app.allowedOrigins.includes("*") ? true : env.app.allowedOrigins,
    credentials: true,
  });

  app.register(rateLimit, {
    global: true,
    max: 100,
    timeWindow: "1 minute",
    addHeaders: {
      "x-ratelimit-limit": true,
      "x-ratelimit-remaining": true,
      "x-ratelimit-reset": true,
      "retry-after": true,
    },
    addHeadersOnExceeding: {
      "x-ratelimit-limit": true,
      "x-ratelimit-remaining": true,
      "x-ratelimit-reset": true,
    },
  });

  applyRouteRateLimits(app);

  // Health check with actual DB/Redis connectivity probes
  app.get("/health", async (_request, reply) => {
    const pgStatus = await db.query("SELECT 1").then(() => "up" as const).catch(() => "down" as const);
    const redisStatus = db.redis.status === "ready" ? "up" as const : "down" as const;
    const allUp = pgStatus === "up" && redisStatus === "up";

    const payload = {
      status: allUp ? "ok" : "degraded",
      service: "soundscore-backend",
      checks: {
        postgres: pgStatus,
        redis: redisStatus,
      },
    };

    return allUp ? payload : reply.status(503).send(payload);
  });

  registerAuthRoutes(app, db);
  registerCatalogRoutes(app, db);
  registerOpinionRoutes(app, db);
  registerSocialRoutes(app, db);
  registerListRoutes(app, db);
  registerTrustRoutes(app, db);
  registerPushRoutes(app, db);
  registerRecapRoutes(app, db);
  registerProviderRoutes(app, db);
  registerMappingRoutes(app, db);
  registerImportRoutes(app, db);

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
