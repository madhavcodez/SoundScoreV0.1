package com.soundscore.app.data.sync

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

interface OutboxStore {
    val pending: StateFlow<List<OutboxOperation>>
    fun enqueue(operation: OutboxOperation)
    fun markDispatched(operationId: String)
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
}
