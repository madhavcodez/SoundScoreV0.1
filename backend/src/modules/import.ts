import type { FastifyInstance } from "fastify";
import type { Db } from "../db/client";
import { badRequest, conflict, notFound } from "../lib/errors";
import { uid } from "../lib/util";
import { resolveMapping } from "./mapping";

// --- Provider adapter types (mock for V1) ---

type RawListen = {
  providerAlbumId: string;
  title: string;
  artist: string;
  year?: number;
  trackCount?: number;
  playedAt: string;
};

// Mock provider fetch — will be replaced with real provider adapters
const fetchRecentPlays = async (
  _provider: string,
  _userId: string,
  _cursor?: string,
): Promise<{ plays: RawListen[]; nextCursor: string | null }> => ({
  plays: [
    {
      providerAlbumId: "spotify:album:6kZ42qRrzov54LcAk4onW9",
      title: "CHROMAKOPIA",
      artist: "Tyler, the Creator",
      year: 2024,
      playedAt: new Date().toISOString(),
    },
    {
      providerAlbumId: "spotify:album:0hvT3yIEysuuvkK73vgdcW",
      title: "GNX",
      artist: "Kendrick Lamar",
      year: 2024,
      playedAt: new Date(Date.now() - 600_000).toISOString(),
    },
  ],
  nextCursor: null,
});

// --- Dedup key generation ---

export const generateDedupKey = (
  userId: string,
  canonicalAlbumId: string,
  playedAt: Date,
): string => {
  const epochSeconds = Math.floor(playedAt.getTime() / 1000);
  const bucket = Math.floor(epochSeconds / 600); // 10-minute buckets
  return `${userId}:${canonicalAlbumId}:${bucket}`;
};

// --- Sync job row → API shape ---

type SyncJobRow = {
  id: string;
  user_id: string;
  provider: string;
  sync_type: string;
  status: string;
  progress: number;
  items_processed: number;
  items_total: number | null;
  error: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
};

const mapSyncJob = (row: SyncJobRow) => ({
  id: row.id,
  userId: row.user_id,
  provider: row.provider,
  syncType: row.sync_type,
  status: row.status,
  progress: row.progress,
  itemsProcessed: row.items_processed,
  itemsTotal: row.items_total,
  error: row.error,
  startedAt: row.started_at,
  completedAt: row.completed_at,
  createdAt: row.created_at,
});

// --- Background sync worker ---

const processSync = async (db: Db, syncJobId: string): Promise<void> => {
  try {
    // 1. Mark running
    await db.query(
      "UPDATE sync_jobs SET status = 'running', started_at = NOW() WHERE id = $1",
      [syncJobId],
    );

    const job = await db.query<{ user_id: string; provider: string }>(
      "SELECT user_id, provider FROM sync_jobs WHERE id = $1",
      [syncJobId],
    );
    if (!job.rowCount) return;

    const { user_id: userId, provider } = job.rows[0];

    // 2. Load sync cursor
    const cursorResult = await db.query<{ cursor_value: string | null }>(
      "SELECT cursor_value FROM sync_cursors WHERE user_id = $1 AND provider = $2",
      [userId, provider],
    );
    const cursor = cursorResult.rows[0]?.cursor_value ?? undefined;

    // 3. Fetch recent plays from provider
    const { plays, nextCursor } = await fetchRecentPlays(provider, userId, cursor);

    await db.query("UPDATE sync_jobs SET items_total = $2 WHERE id = $1", [
      syncJobId,
      plays.length,
    ]);

    // 4. Process each listening event
    let processed = 0;
    for (const play of plays) {
      // Check cancellation
      const current = await db.query<{ status: string }>(
        "SELECT status FROM sync_jobs WHERE id = $1",
        [syncJobId],
      );
      if (current.rows[0]?.status === "cancelled") return;

      // a. Resolve mapping: provider album → canonical album
      const resolved = await resolveMapping(db, provider, play.providerAlbumId, {
        title: play.title,
        artist: play.artist,
        year: play.year,
        trackCount: play.trackCount,
      });

      // b. Generate dedup key
      const playedAt = new Date(play.playedAt);
      const dedupKey = generateDedupKey(userId, resolved.canonicalAlbum.id, playedAt);

      // c. Check for duplicate
      const existing = await db.query(
        "SELECT 1 FROM listening_events WHERE dedup_key = $1",
        [dedupKey],
      );

      // d. Insert if not duplicate
      if (!existing.rowCount) {
        await db.query(
          `INSERT INTO listening_events (id, user_id, album_id, played_at, source, source_ref, dedup_key)
           VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)`,
          [
            uid("lst"),
            userId,
            resolved.canonicalAlbum.id,
            playedAt.toISOString(),
            provider,
            JSON.stringify({ provider_album_id: play.providerAlbumId }),
            dedupKey,
          ],
        );
      }

      // e. Update progress
      processed++;
      const progress = plays.length > 0 ? Math.round((processed / plays.length) * 100) : 100;
      await db.query(
        "UPDATE sync_jobs SET items_processed = $2, progress = $3 WHERE id = $1",
        [syncJobId, processed, progress],
      );
    }

    // 5. Update sync cursor
    await db.query(
      `INSERT INTO sync_cursors (user_id, provider, cursor_value, last_sync_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (user_id, provider)
       DO UPDATE SET cursor_value = $3, last_sync_at = NOW()`,
      [userId, provider, nextCursor],
    );

    // 6. Mark completed
    await db.query(
      "UPDATE sync_jobs SET status = 'completed', completed_at = NOW() WHERE id = $1",
      [syncJobId],
    );
  } catch (error) {
    // 7. On error: mark failed, preserve cursor
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    await db.query(
      "UPDATE sync_jobs SET status = 'failed', error = $2, completed_at = NOW() WHERE id = $1",
      [syncJobId, errorMessage],
    );
  }
};

// --- Route registration ---

export const registerImportRoutes = (app: FastifyInstance, db: Db) => {
  // POST /v1/sync/start
  app.post("/v1/sync/start", async (request) => {
    const userId = await app.requireAuth(request);
    const body = request.body as { provider?: string; sync_type?: string };

    if (!body.provider) {
      throw badRequest("MISSING_PROVIDER", "provider is required");
    }

    const provider = body.provider;
    const syncType = body.sync_type === "full" ? "full" : "incremental";

    // Check no running sync for this user+provider
    const running = await db.query<{ id: string }>(
      "SELECT id FROM sync_jobs WHERE user_id = $1 AND provider = $2 AND status IN ('queued', 'running')",
      [userId, provider],
    );

    if (running.rowCount) {
      throw conflict("SYNC_ALREADY_RUNNING", "A sync is already in progress for this provider");
    }

    // Create sync job
    const jobId = uid("syj");
    await db.query(
      `INSERT INTO sync_jobs (id, user_id, provider, sync_type, status)
       VALUES ($1, $2, $3, $4, 'queued')`,
      [jobId, userId, provider, syncType],
    );

    // Kick off async (don't await)
    processSync(db, jobId).catch((err) => {
      app.log.error({ err, syncJobId: jobId }, "sync_process_error");
    });

    const created = await db.query<SyncJobRow>(
      "SELECT * FROM sync_jobs WHERE id = $1",
      [jobId],
    );

    return { job: mapSyncJob(created.rows[0]) };
  });

  // GET /v1/sync/status/:sync_id
  app.get("/v1/sync/status/:sync_id", async (request) => {
    const userId = await app.requireAuth(request);
    const syncId = (request.params as { sync_id: string }).sync_id;

    const result = await db.query<SyncJobRow>(
      "SELECT * FROM sync_jobs WHERE id = $1 AND user_id = $2",
      [syncId, userId],
    );

    if (!result.rowCount) {
      throw notFound("Sync job");
    }

    return { job: mapSyncJob(result.rows[0]) };
  });

  // POST /v1/sync/cancel
  app.post("/v1/sync/cancel", async (request) => {
    const userId = await app.requireAuth(request);
    const body = request.body as { sync_id?: string };

    if (!body.sync_id) {
      throw badRequest("MISSING_SYNC_ID", "sync_id is required");
    }

    const result = await db.query<{ id: string; status: string }>(
      "SELECT id, status FROM sync_jobs WHERE id = $1 AND user_id = $2",
      [body.sync_id, userId],
    );

    if (!result.rowCount) {
      throw notFound("Sync job");
    }

    const job = result.rows[0];
    if (job.status !== "queued" && job.status !== "running") {
      throw badRequest("SYNC_NOT_CANCELLABLE", "Only queued or running syncs can be cancelled");
    }

    await db.query(
      "UPDATE sync_jobs SET status = 'cancelled', completed_at = NOW() WHERE id = $1",
      [body.sync_id],
    );

    return { cancelled: true };
  });
};
