import type { FastifyRequest } from "fastify";

export type PaginationParams = {
  cursor: string | null;
  limit: number;
};

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;

export const parsePaginationParams = (request: FastifyRequest): PaginationParams => {
  const query = request.query as { cursor?: string; limit?: string };
  const rawLimit = Number(query.limit);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0
    ? Math.min(rawLimit, MAX_LIMIT)
    : DEFAULT_LIMIT;
  const cursor = query.cursor?.trim() || null;
  return { cursor, limit };
};

export const buildPaginatedResponse = <T>(items: T[], limit: number, getCursor: (item: T) => string) => {
  const hasMore = items.length > limit;
  const trimmed = hasMore ? items.slice(0, limit) : items;
  return {
    items: trimmed,
    nextCursor: hasMore ? getCursor(trimmed[trimmed.length - 1]) : null,
  };
};
