import { z } from "zod";
import { ProviderName } from "./provider";

/** Whether a sync pulls all data or only changes since the last cursor. */
export const SyncType = z.enum(["full", "incremental"]);
export type SyncType = z.infer<typeof SyncType>;

/** Lifecycle states of a sync job. */
export const SyncStatus = z.enum(["queued", "running", "completed", "failed", "cancelled"]);
export type SyncStatus = z.infer<typeof SyncStatus>;

/** Request to start a new sync job for a connected provider. */
export const SyncTriggerRequestSchema = z.object({
  provider: ProviderName,
  syncType: SyncType,
});

/** Persistent representation of a sync job and its progress. */
export const SyncJobSchema = z.object({
  id: z.string(),
  userId: z.string(),
  provider: ProviderName,
  syncType: SyncType,
  status: SyncStatus,
  progress: z.number().int().min(0).max(100),
  itemsProcessed: z.number().int().nonnegative(),
  itemsTotal: z.number().int().nonnegative().optional(),
  error: z.string().optional(),
  startedAt: z.string().datetime().optional(),
  completedAt: z.string().datetime().optional(),
  createdAt: z.string().datetime(),
});

/** Response containing the current state of a sync job. */
export const SyncStatusResponseSchema = z.object({
  job: SyncJobSchema,
});

/** Cursor bookmark for incremental syncs — tracks where the last sync left off. */
export const SyncCursorSchema = z.object({
  userId: z.string(),
  provider: ProviderName,
  cursorValue: z.string().optional(),
  lastSyncAt: z.string().datetime().optional(),
});

/** A single listening event ingested from a provider or entered manually (canonical-aware). */
export const SyncListeningEventSchema = z.object({
  id: z.string(),
  userId: z.string(),
  canonicalAlbumId: z.string(),
  playedAt: z.string().datetime(),
  source: z.union([ProviderName, z.literal("manual")]),
  sourceRef: z.record(z.string()).optional(),
  dedupKey: z.string(),
});

/** Request to cancel a running or queued sync job. */
export const CancelSyncRequestSchema = z.object({
  syncId: z.string(),
});

export type SyncTriggerRequest = z.infer<typeof SyncTriggerRequestSchema>;
export type SyncJob = z.infer<typeof SyncJobSchema>;
export type SyncStatusResponse = z.infer<typeof SyncStatusResponseSchema>;
export type SyncCursor = z.infer<typeof SyncCursorSchema>;
export type SyncListeningEvent = z.infer<typeof SyncListeningEventSchema>;
export type CancelSyncRequest = z.infer<typeof CancelSyncRequestSchema>;
