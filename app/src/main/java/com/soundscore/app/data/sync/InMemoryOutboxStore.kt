package com.soundscore.app.data.sync

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

interface OutboxStore {
    val pending: StateFlow<List<OutboxOperation>>
    fun enqueue(operation: OutboxOperation)
    fun markDispatched(operationId: String)
    fun markFailed(operationId: String, message: String)
}

class InMemoryOutboxStore : OutboxStore {
    private val operations = MutableStateFlow(emptyList<OutboxOperation>())

    override val pending: StateFlow<List<OutboxOperation>> = operations.asStateFlow()

    override fun enqueue(operation: OutboxOperation) {
        operations.update { current -> current + operation }
    }

    override fun markDispatched(operationId: String) {
        operations.update { current -> current.filterNot { it.id == operationId } }
    }

    override fun markFailed(operationId: String, message: String) {
        operations.update { current ->
            current.map { operation ->
                if (operation.id != operationId) {
                    operation
                } else {
                    val nextAttempt = operation.attemptCount + 1
                    val backoffMs = (1L shl minOf(nextAttempt, 6)) * 1_000L
                    operation.copy(
                        attemptCount = nextAttempt,
                        nextAttemptAtMs = System.currentTimeMillis() + backoffMs,
                        lastError = message,
                    )
                }
            }
        }
    }
}
