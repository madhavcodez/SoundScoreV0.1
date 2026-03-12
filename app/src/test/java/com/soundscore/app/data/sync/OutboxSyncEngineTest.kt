package com.soundscore.app.data.sync

import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class OutboxSyncEngineTest {
    @Test
    fun flushDispatchesSuccessfulOperation() = runTest {
        val store = InMemoryOutboxStore()
        store.enqueue(
            OutboxOperation(
                type = OutboxOperationType.RATE_ALBUM,
                payload = mapOf("albumId" to "alb_1", "rating" to "4.5"),
            ),
        )

        val engine = OutboxSyncEngine(
            outboxStore = store,
            dispatcher = StandardTestDispatcher(testScheduler),
        )

        engine.flush { }

        assertTrue(store.pending.value.isEmpty())
    }

    @Test
    fun flushFailureSchedulesRetry() = runTest {
        val store = InMemoryOutboxStore()
        store.enqueue(
            OutboxOperation(
                type = OutboxOperationType.CREATE_LIST,
                payload = mapOf("title" to "retry me"),
            ),
        )

        val engine = OutboxSyncEngine(
            outboxStore = store,
            dispatcher = StandardTestDispatcher(testScheduler),
        )

        engine.flush {
            throw IllegalStateException("network unavailable")
        }

        val pending = store.pending.value.single()
        assertEquals(1, pending.attemptCount)
        assertEquals("network unavailable", pending.lastError)
        assertTrue(pending.nextAttemptAtMs > System.currentTimeMillis())
    }
}
