package com.soundscore.app.data.sync

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class OutboxSyncEngine(
    private val outboxStore: OutboxStore,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) {
    suspend fun flush(
        handler: suspend (OutboxOperation) -> Unit,
    ) = withContext(dispatcher) {
        val now = System.currentTimeMillis()
        val snapshot = outboxStore.pending.value
        snapshot.forEach { operation ->
            if (operation.nextAttemptAtMs > now) {
                return@forEach
            }
            runCatching {
                handler(operation)
            }.onSuccess {
                outboxStore.markDispatched(operation.id)
            }.onFailure { error ->
                outboxStore.markFailed(
                    operationId = operation.id,
                    message = error.message ?: "sync_failed",
                )
            }
        }
    }
}
