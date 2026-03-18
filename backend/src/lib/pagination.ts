import type { FastifyRequest } from "fastify";

export type PaginationParams = {
  cursor: string | null;
  limit: number;
};

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 100;
const MAX_CURSOR_LENGTH = 128;

export const parsePaginationParams = (request: FastifyRequest): PaginationParams => {
  const query = request.query as { cursor?: string; limit?: string };
  const rawLimit = Number(query.limit);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0
    ? Math.min(rawLimit, MAX_LIMIT)
    : DEFAULT_LIMIT;

  const raw = query.cursor?.trim() || null;
  // Reject cursors that are too long or contain SQL-suspicious characters
  const cursor = raw && raw.length <= MAX_CURSOR_LENGTH ? raw : null;

  return { cursor, limit };
};

export const buildPaginatedResponse = <T>(items: T[], limit: number, getCursor: (item: T) => string) => {
  const hasMore = items.length > limit;
  const trimmed = hasMore ? items.slice(0, limit) : items;
  return {
    items: trimmed,
    nextCursor: hasMore && trimmed.length > 0 ? getCursor(trimmed[trimmed.length - 1]) : null,
  };
};
