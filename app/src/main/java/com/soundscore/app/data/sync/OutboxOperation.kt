package com.soundscore.app.data.sync

import java.util.UUID

enum class OutboxOperationType {
    RATE_ALBUM,
    TOGGLE_REACTION,
    CREATE_LIST,
    EXPORT_DATA,
    REGISTER_DEVICE_TOKEN,
    UPSERT_NOTIFICATION_PREFERENCES,
    GENERATE_RECAP,
}

data class OutboxOperation(
    val id: String = UUID.randomUUID().toString(),
    val type: OutboxOperationType,
    val payload: Map<String, String>,
    val idempotencyKey: String = UUID.randomUUID().toString(),
    val createdAtMs: Long = System.currentTimeMillis(),
    val attemptCount: Int = 0,
    val nextAttemptAtMs: Long = 0L,
    val lastError: String? = null,
)
