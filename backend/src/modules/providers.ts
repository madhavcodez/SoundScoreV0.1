import crypto from "node:crypto";
import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { badRequest, conflict, notFound, unauthorized } from "../lib/errors";
import { getAdapter, SUPPORTED_PROVIDERS } from "../lib/provider-registry";
import { uid } from "../lib/util";

const VALID_PROVIDERS = new Set(SUPPORTED_PROVIDERS);

const validateProvider = (provider: string) => {
  if (!VALID_PROVIDERS.has(provider)) {
    throw badRequest("INVALID_PROVIDER", `Unsupported provider: ${provider}`);
  }
};

export const registerProviderRoutes = (app: FastifyInstance, db: Db) => {
  // --- POST /v1/providers/:provider/connect ---
  app.post("/v1/providers/:provider/connect", async (request) => {
    const userId = await app.requireAuth(request);
    const { provider } = request.params as { provider: string };
    validateProvider(provider);

    const body = request.body as { redirect_uri?: string } | undefined;
    const redirectUri = body?.redirect_uri;
    if (!redirectUri) {
      throw badRequest("MISSING_REDIRECT_URI", "redirect_uri is required");
    }

    // Check if already connected
    const existing = await db.query<{ id: string; connected_at: string }>(
      `SELECT id, connected_at FROM provider_connections
       WHERE user_id = $1 AND provider = $2 AND disconnected_at IS NULL`,
      [userId, provider],
    );
    if (existing.rowCount) {
      throw conflict("ALREADY_CONNECTED", `Already connected to ${provider}`);
    }

    const adapter = getAdapter(provider);
    if (!adapter) {
      throw badRequest("INVALID_PROVIDER", `No adapter for provider: ${provider}`);
    }

    // Generate crypto-random state for CSRF protection
    const state = crypto.randomBytes(32).toString("hex");
    await db.query(
      `INSERT INTO oauth_states(state, user_id, provider, redirect_uri)
       VALUES($1, $2, $3, $4)`,
      [state, userId, provider, redirectUri],
    );

    const oauthUrl = adapter.getOAuthUrl(state, redirectUri);

    return { oauth_url: oauthUrl, state };
  });

  // --- POST /v1/providers/:provider/callback ---
  app.post("/v1/providers/:provider/callback", async (request) => {
    const userId = await app.requireAuth(request);
    const { provider } = request.params as { provider: string };
    validateProvider(provider);

    const body = request.body as { code?: string; state?: string } | undefined;
    const code = body?.code;
    const state = body?.state;

    if (!code || !state) {
      throw badRequest("MISSING_PARAMS", "code and state are required");
    }

    // Validate state: exists, not expired, matches user
    const stateResult = await db.query<{
      user_id: string;
      provider: string;
      redirect_uri: string;
      expires_at: string;
    }>(
      `SELECT user_id, provider, redirect_uri, expires_at
       FROM oauth_states
       WHERE state = $1`,
      [state],
    );

    if (!stateResult.rowCount) {
      throw unauthorized("Invalid or expired OAuth state");
    }

    const oauthState = stateResult.rows[0];

    if (oauthState.user_id !== userId) {
      throw unauthorized("OAuth state does not match authenticated user");
    }
    if (oauthState.provider !== provider) {
      throw badRequest("STATE_PROVIDER_MISMATCH", "State provider does not match route");
    }
    if (new Date(oauthState.expires_at).getTime() < Date.now()) {
      // Clean up expired state
      await db.query("DELETE FROM oauth_states WHERE state = $1", [state]);
      throw unauthorized("OAuth state has expired");
    }

    // Delete used state (one-time use)
    await db.query("DELETE FROM oauth_states WHERE state = $1", [state]);

    const adapter = getAdapter(provider);
    if (!adapter) {
      throw badRequest("INVALID_PROVIDER", `No adapter for provider: ${provider}`);
    }

    const tokens = await adapter.exchangeCode(code, oauthState.redirect_uri);
    const connectionId = uid("prc");
    const expiresAt = tokens.expires_in
      ? new Date(Date.now() + tokens.expires_in * 1000).toISOString()
      : null;
    const scopes = tokens.scope ? tokens.scope.split(" ") : [];

    // Upsert: if a disconnected connection exists for this user+provider, replace it
    await db.query(
      `INSERT INTO provider_connections(id, user_id, provider, access_token, refresh_token, token_expires_at, scopes, connected_at, disconnected_at)
       VALUES($1, $2, $3, $4, $5, $6, $7, NOW(), NULL)
       ON CONFLICT(user_id, provider) DO UPDATE SET
         id = $1,
         access_token = $4,
         refresh_token = $5,
         token_expires_at = $6,
         scopes = $7,
         connected_at = NOW(),
         disconnected_at = NULL`,
      [connectionId, userId, provider, tokens.access_token, tokens.refresh_token ?? null, expiresAt, scopes],
    );

    return {
      connection: {
        id: connectionId,
        provider,
        connected: true,
        connected_at: new Date().toISOString(),
        scopes,
      },
    };
  });

  // --- GET /v1/providers/:provider/status ---
  app.get("/v1/providers/:provider/status", async (request) => {
    const userId = await app.requireAuth(request);
    const { provider } = request.params as { provider: string };
    validateProvider(provider);

    const result = await db.query<{
      id: string;
      provider: string;
      connected_at: string;
      scopes: string[];
    }>(
      `SELECT id, provider, connected_at, scopes
       FROM provider_connections
       WHERE user_id = $1 AND provider = $2 AND disconnected_at IS NULL`,
      [userId, provider],
    );

    if (!result.rowCount) {
      return { connection: null };
    }

    const conn = result.rows[0];
    return {
      connection: {
        id: conn.id,
        provider: conn.provider,
        connected: true,
        connected_at: conn.connected_at,
        scopes: conn.scopes,
      },
    };
  });

  // --- POST /v1/providers/:provider/disconnect ---
  app.post("/v1/providers/:provider/disconnect", async (request) => {
    const userId = await app.requireAuth(request);
    const { provider } = request.params as { provider: string };
    validateProvider(provider);

    const connResult = await db.query<{
      id: string;
      access_token: string;
    }>(
      `SELECT id, access_token FROM provider_connections
       WHERE user_id = $1 AND provider = $2 AND disconnected_at IS NULL`,
      [userId, provider],
    );

    if (!connResult.rowCount) {
      throw notFound("Provider connection");
    }

    const conn = connResult.rows[0];

    // Best-effort token revocation
    const adapter = getAdapter(provider);
    if (adapter) {
      try {
        await adapter.revokeToken(conn.access_token);
      } catch {
        // Revocation is best-effort; log but don't fail
      }
    }

    // Soft-disconnect: set disconnected_at
    await db.query(
      `UPDATE provider_connections SET disconnected_at = NOW() WHERE id = $1`,
      [conn.id],
    );

    // Purge associated data if requested
    const body = request.body as { purge_data?: boolean } | undefined;
    if (body?.purge_data) {
      await db.query(
        `DELETE FROM listening_events WHERE user_id = $1 AND source = $2`,
        [userId, provider],
      );
      // sync_cursors and sync_jobs tables may not exist yet in this phase;
      // wrap in try/catch to be forward-compatible
      try {
        await db.query(
          `DELETE FROM sync_cursors WHERE user_id = $1 AND provider = $2`,
          [userId, provider],
        );
      } catch {
        // Table may not exist yet
      }
      try {
        await db.query(
          `DELETE FROM sync_jobs WHERE user_id = $1 AND provider = $2`,
          [userId, provider],
        );
      } catch {
        // Table may not exist yet
      }
    }

    return { disconnected: true };
  });
};
