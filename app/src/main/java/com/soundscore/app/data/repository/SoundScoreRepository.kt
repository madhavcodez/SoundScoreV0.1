package com.soundscore.app.data.repository

import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.data.model.UserList
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.data.sync.InMemoryOutboxStore
import com.soundscore.app.data.sync.OutboxOperation
import com.soundscore.app.data.sync.OutboxOperationType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

interface SoundScoreRepository {
    val feedItems: StateFlow<List<FeedItem>>
    val albums: StateFlow<List<Album>>
    val profile: StateFlow<UserProfile>
    val ratings: StateFlow<Map<String, Float>>
    val lists: StateFlow<List<UserList>>
    val pendingOutboxOps: StateFlow<List<OutboxOperation>>

    fun searchAlbums(query: String): List<Album>
    fun updateRating(albumId: String, rating: Float)
    fun toggleLike(feedItemId: String)
    fun createList(title: String)
    fun exportSnapshot(): String
}

class SeedSoundScoreRepository : SoundScoreRepository {
    private val _feedItems = MutableStateFlow(SeedData.feedItems)
    private val _albums = MutableStateFlow(SeedData.albums)
    private val _profile = MutableStateFlow(SeedData.myProfile)
    private val _ratings = MutableStateFlow(SeedData.logInitialRatings)
    private val _lists = MutableStateFlow(SeedData.initialLists)
    private val outboxStore = InMemoryOutboxStore()

    override val feedItems: StateFlow<List<FeedItem>> = _feedItems.asStateFlow()
    override val albums: StateFlow<List<Album>> = _albums.asStateFlow()
    override val profile: StateFlow<UserProfile> = _profile.asStateFlow()
    override val ratings: StateFlow<Map<String, Float>> = _ratings.asStateFlow()
    override val lists: StateFlow<List<UserList>> = _lists.asStateFlow()
    override val pendingOutboxOps: StateFlow<List<OutboxOperation>> = outboxStore.pending

    override fun searchAlbums(query: String): List<Album> {
        val normalized = query.trim()
        if (normalized.isBlank()) {
            return _albums.value
        }

        return _albums.value.filter {
            it.title.contains(normalized, ignoreCase = true) ||
                it.artist.contains(normalized, ignoreCase = true)
        }
    }

    override fun updateRating(albumId: String, rating: Float) {
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.RATE_ALBUM,
                payload = mapOf(
                    "albumId" to albumId,
                    "rating" to rating.toString(),
                ),
            ),
        )

        _ratings.update { previous ->
            previous + (albumId to rating)
        }

        _profile.update { previous ->
            val values = _ratings.value.values
            val average = if (values.isEmpty()) previous.avgRating else values.average().toFloat()
            previous.copy(avgRating = average)
        }
    }

    override fun toggleLike(feedItemId: String) {
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.TOGGLE_REACTION,
                payload = mapOf("feedItemId" to feedItemId),
            ),
        )

        _feedItems.update { items ->
            items.map { item ->
                if (item.id != feedItemId) {
                    item
                } else {
                    val nextLiked = !item.isLiked
                    item.copy(
                        isLiked = nextLiked,
                        likes = if (nextLiked) item.likes + 1 else maxOf(0, item.likes - 1),
                    )
                }
            }
        }
    }

    override fun createList(title: String) {
        val trimmed = title.trim()
        if (trimmed.isEmpty()) {
            return
        }

        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.CREATE_LIST,
                payload = mapOf("title" to trimmed),
            ),
        )

        _lists.update { current ->
            current + UserList(
                id = UUID.randomUUID().toString(),
                title = trimmed,
            )
        }

        _profile.update { previous ->
            previous.copy(listCount = _lists.value.size)
        }
    }

    override fun exportSnapshot(): String {
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.EXPORT_DATA,
                payload = mapOf("trigger" to "profile"),
            ),
        )

        val payload = JSONObject()
            .put("exportedAt", System.currentTimeMillis())
            .put("profile", JSONObject().apply {
                put("handle", _profile.value.handle)
                put("bio", _profile.value.bio)
                put("logCount", _profile.value.logCount)
                put("reviewCount", _profile.value.reviewCount)
                put("listCount", _profile.value.listCount)
                put("avgRating", _profile.value.avgRating)
            })
            .put("ratings", JSONObject(_ratings.value as Map<*, *>))
            .put("lists", JSONArray(_lists.value.map { list ->
                JSONObject().apply {
                    put("id", list.id)
                    put("title", list.title)
                    put("note", list.note)
                    put("albumIds", JSONArray(list.albumIds))
                }
            }))

        return payload.toString(2)
    }
}

object AppContainer {
    val repository: SoundScoreRepository by lazy {
        SeedSoundScoreRepository()
    }
}
