import type { FastifyInstance } from "fastify";
import {
  AuthResponseSchema,
  LoginRequestSchema,
  RefreshRequestSchema,
  SignUpRequestSchema,
} from "@soundscore/contracts";
import bcrypt from "bcryptjs";
import type { Db } from "../db/client";
import { logAuditEvent } from "../lib/audit";
import { conflict, unauthorized } from "../lib/errors";
import { mapUserProfile } from "../lib/mappers";
import { nowIso, uid } from "../lib/util";
import { env } from "../config/env";

const buildAuthResponse = (
  accessToken: string,
  refreshToken: string,
  userId: string,
  handle: string,
) => AuthResponseSchema.parse({ accessToken, refreshToken, userId, handle });

const writeProfileCache = async (db: Db, userId: string) => {
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

  if (profile.rowCount) {
    await db.redis.setex(
      `profile:${userId}`,
      90,
      JSON.stringify(mapUserProfile(profile.rows[0])),
    );
  }
};

export const registerAuthRoutes = (app: FastifyInstance, db: Db) => {
  app.post("/v1/auth/signup", async (request, reply) => {
    const payload = SignUpRequestSchema.parse(request.body);
    const existing = await db.query<{ id: string }>(
      "SELECT id FROM users WHERE email = $1",
      [payload.email.toLowerCase()],
    );
    if (existing.rowCount) {
      throw conflict("EMAIL_ALREADY_IN_USE", "Email is already registered");
    }

    const userId = uid("usr");
    const accessToken = uid("atk");
    const refreshToken = uid("rtk");
    const now = nowIso();
    const passwordHash = await bcrypt.hash(payload.password, env.auth.saltRounds);

    await db.query(
      `
        INSERT INTO users(
          id, email, password_hash, handle, bio, log_count, review_count, list_count, avg_rating, refresh_token, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, '', 0, 0, 0, 0, $5, $6, $6)
      `,
      [
        userId,
        payload.email.toLowerCase(),
        passwordHash,
        payload.handle.startsWith("@") ? payload.handle : `@${payload.handle}`,
        refreshToken,
        now,
      ],
    );

    await db.query(
      `
        INSERT INTO sessions(access_token, user_id, created_at, expires_at)
        VALUES($1, $2, $3, NOW() + INTERVAL '24 hours')
      `,
      [accessToken, userId, now],
    );

    await db.query(
      `
        INSERT INTO notification_preferences(user_id)
        VALUES($1)
        ON CONFLICT(user_id) DO NOTHING
      `,
      [userId],
    );

    await writeProfileCache(db, userId);

    logAuditEvent(db, {
      userId,
      type: "user.signup",
      details: { handle: payload.handle.startsWith("@") ? payload.handle : `@${payload.handle}` },
      ipAddress: request.ip,
      userAgent: request.headers["user-agent"],
    }).catch(() => {});

    return reply.status(201).send(buildAuthResponse(
      accessToken,
      refreshToken,
      userId,
      payload.handle.startsWith("@") ? payload.handle : `@${payload.handle}`,
    ));
  });

  app.post("/v1/auth/login", async (request) => {
    const payload = LoginRequestSchema.parse(request.body);
    const userResult = await db.query<{
      id: string;
      password_hash: string;
      handle: string;
    }>(
      "SELECT id, password_hash, handle FROM users WHERE email = $1",
      [payload.email.toLowerCase()],
    );

    if (!userResult.rowCount) {
      throw unauthorized("Invalid credentials");
    }

    const user = userResult.rows[0];
    const matches = await bcrypt.compare(payload.password, user.password_hash);
    if (!matches) {
      throw unauthorized("Invalid credentials");
    }

    const accessToken = uid("atk");
    const refreshToken = uid("rtk");
    const now = nowIso();

    await db.query(
      "UPDATE users SET refresh_token = $2, updated_at = NOW() WHERE id = $1",
      [user.id, refreshToken],
    );
    await db.query(
      "INSERT INTO sessions(access_token, user_id, created_at, expires_at) VALUES($1, $2, $3, NOW() + INTERVAL '24 hours')",
      [accessToken, user.id, now],
    );

    // Clean up expired sessions for this user
    await db.query("DELETE FROM sessions WHERE user_id = $1 AND expires_at < NOW()", [user.id]);

    logAuditEvent(db, {
      userId: user.id,
      type: "user.login",
      ipAddress: request.ip,
      userAgent: request.headers["user-agent"],
    }).catch(() => {});

    return buildAuthResponse(accessToken, refreshToken, user.id, user.handle);
  });

  app.post("/v1/auth/refresh", async (request) => {
    const payload = RefreshRequestSchema.parse(request.body);
    const userResult = await db.query<{ id: string; handle: string }>(
      "SELECT id, handle FROM users WHERE refresh_token = $1",
      [payload.refreshToken],
    );

    if (!userResult.rowCount) {
      throw unauthorized("Refresh token is invalid");
    }

    const user = userResult.rows[0];
    const accessToken = uid("atk");
    const nextRefreshToken = uid("rtk");
    const now = nowIso();

    await db.query(
      "UPDATE users SET refresh_token = $2, updated_at = NOW() WHERE id = $1",
      [user.id, nextRefreshToken],
    );
    await db.query(
      "INSERT INTO sessions(access_token, user_id, created_at, expires_at) VALUES($1, $2, $3, NOW() + INTERVAL '24 hours')",
      [accessToken, user.id, now],
    );

    // Clean up expired sessions for this user
    await db.query("DELETE FROM sessions WHERE user_id = $1 AND expires_at < NOW()", [user.id]);

    return buildAuthResponse(accessToken, nextRefreshToken, user.id, user.handle);
  });

  app.get("/v1/me", async (request) => {
    const userId = await app.requireAuth(request);
    const cached = await db.redis.get(`profile:${userId}`);
    if (cached) {
      return JSON.parse(cached) as unknown;
    }

    const user = await db.query<{
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
    if (!user.rowCount) {
      throw unauthorized();
    }

    const profile = mapUserProfile(user.rows[0]);
    await db.redis.setex(`profile:${userId}`, 90, JSON.stringify(profile));
    return profile;
  });
};
