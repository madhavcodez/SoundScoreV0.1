package com.soundscore.app.data.sync

/**
 * Phase 1A sync scaffold. A later phase will replace this with WorkManager-backed flush logic
 * that dispatches queued operations to the backend when network is available.
 */
class OutboxSyncEngine(
    private val outboxStore: OutboxStore,
) {
    fun flushNoop() {
        // Intentionally no-op for now; foundation layer only.
        outboxStore.pending.value.forEach { operation ->
            outboxStore.markDispatched(operation.id)
        }
    }
}
