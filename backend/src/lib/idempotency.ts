import type { FastifyRequest } from "fastify";
import type { Db } from "../db/client";
import { badRequest, conflict } from "./errors";

const keyFromRequest = (request: FastifyRequest, userId: string, idempotencyKey: string) => {
  const routeKey = `${request.method}:${request.url.split("?")[0]}`;
  return {
    routeKey,
    userId,
    idempotencyKey,
  };
};

export const withIdempotency = async <T>(
  request: FastifyRequest,
  db: Db,
  userId: string,
  handler: () => Promise<T> | T,
): Promise<T> => {
  const idempotencyKeyHeader = request.headers["idempotency-key"];
  if (!idempotencyKeyHeader || typeof idempotencyKeyHeader !== "string") {
    throw badRequest("IDEMPOTENCY_KEY_REQUIRED", "Missing idempotency-key header for mutating request");
  }

  const { routeKey, idempotencyKey } = keyFromRequest(request, userId, idempotencyKeyHeader);

  const inserted = await db.query<{ id: number }>(
    `
      INSERT INTO idempotency_keys (user_id, route_key, idempotency_key, status)
      VALUES ($1, $2, $3, 'pending')
      ON CONFLICT (user_id, route_key, idempotency_key) DO NOTHING
      RETURNING id
    `,
    [userId, routeKey, idempotencyKey],
  );

  if (!inserted.rowCount) {
    const existing = await db.query<{ status: string; response_json: unknown }>(
      `
        SELECT status, response_json
        FROM idempotency_keys
        WHERE user_id = $1 AND route_key = $2 AND idempotency_key = $3
      `,
      [userId, routeKey, idempotencyKey],
    );

    const row = existing.rows[0];
    if (!row || row.status === "pending" || row.response_json === null) {
      throw conflict("IDEMPOTENCY_IN_PROGRESS", "A request with this idempotency key is still processing");
    }

    return row.response_json as T;
  }

  try {
    const result = await handler();
    await db.query(
      `
        UPDATE idempotency_keys
        SET status = 'completed', response_json = $4::jsonb, updated_at = NOW()
        WHERE user_id = $1 AND route_key = $2 AND idempotency_key = $3
      `,
      [userId, routeKey, idempotencyKey, JSON.stringify(result)],
    );
    return result;
  } catch (error) {
    await db.query(
      `
        UPDATE idempotency_keys
        SET status = 'failed', updated_at = NOW()
        WHERE user_id = $1 AND route_key = $2 AND idempotency_key = $3
      `,
      [userId, routeKey, idempotencyKey],
    );
    throw error;
  }
};
