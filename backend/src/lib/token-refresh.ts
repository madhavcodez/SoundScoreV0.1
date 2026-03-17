import type { Db } from "../db/client";
import { getAdapter } from "./provider-registry";

const REFRESH_BUFFER_MS = 5 * 60 * 1000; // 5 minutes

export const ensureFreshToken = async (
  userId: string,
  provider: string,
  db: Db,
): Promise<string> => {
  const result = await db.query<{
    id: string;
    access_token: string;
    refresh_token: string | null;
    token_expires_at: string | null;
  }>(
    `SELECT id, access_token, refresh_token, token_expires_at
     FROM provider_connections
     WHERE user_id = $1 AND provider = $2 AND disconnected_at IS NULL`,
    [userId, provider],
  );

  if (!result.rowCount) {
    throw new Error(`No active ${provider} connection for user ${userId}`);
  }

  const conn = result.rows[0];

  // If no expiry or not yet close to expiring, return current token
  if (conn.token_expires_at) {
    const expiresAt = new Date(conn.token_expires_at).getTime();
    const now = Date.now();

    if (expiresAt - now > REFRESH_BUFFER_MS) {
      return conn.access_token;
    }

    // Token is expired or about to expire — refresh it
    if (!conn.refresh_token) {
      throw new Error(`Token expired and no refresh token available for ${provider}`);
    }

    const adapter = getAdapter(provider);
    if (!adapter) {
      throw new Error(`No adapter for provider ${provider}`);
    }

    const tokens = await adapter.refreshToken(conn.refresh_token);
    const newExpiresAt = tokens.expires_in
      ? new Date(Date.now() + tokens.expires_in * 1000).toISOString()
      : null;

    await db.query(
      `UPDATE provider_connections
       SET access_token = $1,
           refresh_token = COALESCE($2, refresh_token),
           token_expires_at = $3
       WHERE id = $4`,
      [tokens.access_token, tokens.refresh_token, newExpiresAt, conn.id],
    );

    return tokens.access_token;
  }

  return conn.access_token;
};
