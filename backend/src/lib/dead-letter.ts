import type { Db } from "../db/client";
import { uid } from "./util";

export async function moveToDeadLetter(
  db: Db,
  event: {
    originalId?: string;
    eventType: string;
    payload: Record<string, unknown>;
    error: string;
    attemptCount?: number;
  },
): Promise<void> {
  await db.query(
    `
      INSERT INTO dead_letter_events(id, original_id, event_type, payload, error, attempt_count)
      VALUES ($1, $2, $3, $4::jsonb, $5, $6)
    `,
    [
      uid("dle"),
      event.originalId ?? null,
      event.eventType,
      JSON.stringify(event.payload),
      event.error,
      event.attemptCount ?? 0,
    ],
  );
}

export async function listRecentDeadLetters(
  db: Db,
  limit = 50,
  maxLimit = 200,
): Promise<
  Array<{
    id: string;
    originalId: string | null;
    eventType: string;
    payload: Record<string, unknown>;
    error: string;
    attemptCount: number;
    createdAt: string;
  }>
> {
  const result = await db.query<{
    id: string;
    original_id: string | null;
    event_type: string;
    payload: Record<string, unknown>;
    error: string;
    attempt_count: number;
    created_at: string;
  }>(
    `
      SELECT id, original_id, event_type, payload, error, attempt_count, created_at
      FROM dead_letter_events
      ORDER BY created_at DESC
      LIMIT $1
    `,
    [Math.min(Math.max(1, limit), maxLimit)],
  );

  return result.rows.map((row) => ({
    id: row.id,
    originalId: row.original_id,
    eventType: row.event_type,
    payload: row.payload,
    error: row.error,
    attemptCount: row.attempt_count,
    createdAt: row.created_at,
  }));
}
