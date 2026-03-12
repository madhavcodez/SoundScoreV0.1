import { Pool, type QueryResult, type QueryResultRow } from "pg";
import Redis, { type Redis as RedisClient } from "ioredis";
import { env } from "../config/env";

export type Db = {
  pool: Pool;
  redis: RedisClient;
  query: <T extends QueryResultRow = QueryResultRow>(
    text: string,
    params?: unknown[],
  ) => Promise<QueryResult<T>>;
  close: () => Promise<void>;
};

export const createDb = (): Db => {
  const pool = new Pool({
    connectionString: env.postgres.connectionString,
  });

  const redis = new Redis(env.redis.url, {
    maxRetriesPerRequest: 1,
    lazyConnect: false,
  });

  return {
    pool,
    redis,
    query: <T extends QueryResultRow = QueryResultRow>(text: string, params?: unknown[]) =>
      pool.query<T>(text, params),
    close: async () => {
      await Promise.all([pool.end(), redis.quit()]);
    },
  };
};
