import type { FastifyInstance } from "fastify";
import {
  AuthResponseSchema,
  LoginRequestSchema,
  RefreshRequestSchema,
  SignUpRequestSchema,
} from "@soundscore/contracts";
import type { InMemoryStore } from "../types";
import { conflict, unauthorized } from "../lib/errors";
import { nowIso, uid } from "../lib/util";

const buildAuthResponse = (
  accessToken: string,
  refreshToken: string,
  userId: string,
  handle: string,
) => AuthResponseSchema.parse({ accessToken, refreshToken, userId, handle });

export const registerAuthRoutes = (app: FastifyInstance, store: InMemoryStore) => {
  app.post("/v1/auth/signup", async (request) => {
    const payload = SignUpRequestSchema.parse(request.body);
    if (store.usersByEmail.has(payload.email.toLowerCase())) {
      throw conflict("EMAIL_ALREADY_IN_USE", "Email is already registered");
    }

    const userId = uid("usr");
    const accessToken = uid("atk");
    const refreshToken = uid("rtk");

    store.users.set(userId, {
      id: userId,
      email: payload.email.toLowerCase(),
      password: payload.password,
      refreshToken,
      profile: {
        id: userId,
        handle: payload.handle.startsWith("@") ? payload.handle : `@${payload.handle}`,
        bio: "",
        logCount: 0,
        reviewCount: 0,
        listCount: 0,
        avgRating: 0,
      },
    });
    store.usersByEmail.set(payload.email.toLowerCase(), userId);
    store.sessions.set(accessToken, {
      accessToken,
      userId,
      createdAt: nowIso(),
    });

    return buildAuthResponse(accessToken, refreshToken, userId, store.users.get(userId)!.profile.handle);
  });

  app.post("/v1/auth/login", async (request) => {
    const payload = LoginRequestSchema.parse(request.body);
    const userId = store.usersByEmail.get(payload.email.toLowerCase());
    if (!userId) {
      throw unauthorized("Invalid credentials");
    }

    const user = store.users.get(userId)!;
    if (user.password !== payload.password) {
      throw unauthorized("Invalid credentials");
    }

    const accessToken = uid("atk");
    const refreshToken = uid("rtk");
    user.refreshToken = refreshToken;
    store.sessions.set(accessToken, {
      accessToken,
      userId,
      createdAt: nowIso(),
    });

    return buildAuthResponse(accessToken, refreshToken, userId, user.profile.handle);
  });

  app.post("/v1/auth/refresh", async (request) => {
    const payload = RefreshRequestSchema.parse(request.body);
    const user = [...store.users.values()].find((candidate) => candidate.refreshToken === payload.refreshToken);
    if (!user) {
      throw unauthorized("Refresh token is invalid");
    }

    const accessToken = uid("atk");
    const nextRefreshToken = uid("rtk");
    user.refreshToken = nextRefreshToken;
    store.sessions.set(accessToken, {
      accessToken,
      userId: user.id,
      createdAt: nowIso(),
    });

    return buildAuthResponse(accessToken, nextRefreshToken, user.id, user.profile.handle);
  });

  app.get("/v1/me", async (request) => {
    const userId = app.requireAuth(request);
    const user = store.users.get(userId);
    if (!user) {
      throw unauthorized();
    }
    return user.profile;
  });
};
