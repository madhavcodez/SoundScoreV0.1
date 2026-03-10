import type { FastifyReply, FastifyRequest } from "fastify";
import { badRequest } from "./errors";
import type { InMemoryStore } from "../types";

const keyFromRequest = (request: FastifyRequest, userId: string, idempotencyKey: string) => {
  const routeKey = `${request.method}:${request.url.split("?")[0]}`;
  return `${userId}:${routeKey}:${idempotencyKey}`;
};

export const withIdempotency = async <T>(
  request: FastifyRequest,
  _reply: FastifyReply,
  store: InMemoryStore,
  userId: string,
  handler: () => Promise<T> | T,
): Promise<T> => {
  const idempotencyKeyHeader = request.headers["idempotency-key"];
  if (!idempotencyKeyHeader || typeof idempotencyKeyHeader !== "string") {
    throw badRequest("IDEMPOTENCY_KEY_REQUIRED", "Missing idempotency-key header for mutating request");
  }

  const key = keyFromRequest(request, userId, idempotencyKeyHeader);
  if (store.idempotency.has(key)) {
    return store.idempotency.get(key) as T;
  }

  const result = await handler();
  store.idempotency.set(key, result);
  return result;
};
