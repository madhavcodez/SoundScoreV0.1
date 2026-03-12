package com.soundscore.app.data.repository

import com.soundscore.app.data.api.ActivityEventDto
import com.soundscore.app.data.api.AlbumDto
import com.soundscore.app.data.api.ApiClient
import com.soundscore.app.data.api.AuthRequest
import com.soundscore.app.data.api.CreateListRequest
import com.soundscore.app.data.api.DeviceTokenRequest
import com.soundscore.app.data.api.NotificationPreferenceDto
import com.soundscore.app.data.api.RatingRequest
import com.soundscore.app.data.api.ReactionRequest
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.model.NotificationPreferences
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.data.model.UserList
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.data.model.WeeklyRecap
import com.soundscore.app.data.sync.InMemoryOutboxStore
import com.soundscore.app.data.sync.OutboxOperation
import com.soundscore.app.data.sync.OutboxOperationType
import com.soundscore.app.data.sync.OutboxSyncEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.floatOrNull
import kotlinx.serialization.json.jsonPrimitive
import java.util.UUID

interface SoundScoreRepository {
    val feedItems: StateFlow<List<FeedItem>>
    val albums: StateFlow<List<Album>>
    val profile: StateFlow<UserProfile>
    val ratings: StateFlow<Map<String, Float>>
    val lists: StateFlow<List<UserList>>
    val pendingOutboxOps: StateFlow<List<OutboxOperation>>
    val notificationPreferences: StateFlow<NotificationPreferences>
    val latestRecap: StateFlow<WeeklyRecap?>
    val syncMessage: StateFlow<String?>

    fun searchAlbums(query: String): List<Album>
    suspend fun refresh()
    suspend fun updateRating(albumId: String, rating: Float)
    suspend fun toggleLike(feedItemId: String)
    suspend fun createList(title: String)
    suspend fun exportSnapshot(): String
    suspend fun updateNotificationPreferences(preferences: NotificationPreferences)
    suspend fun registerDeviceToken(platform: String, token: String)
    suspend fun loadLatestRecap()
    suspend fun generateLatestRecap()
    suspend fun syncOutbox()
}

class RemoteSoundScoreRepository : SoundScoreRepository {
    private val api = ApiClient.create()
    private val outboxStore = InMemoryOutboxStore()
    private val outboxSyncEngine = OutboxSyncEngine(outboxStore)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _feedItems = MutableStateFlow(SeedData.feedItems)
    private val _albums = MutableStateFlow(SeedData.albums)
    private val _profile = MutableStateFlow(SeedData.myProfile)
    private val _ratings = MutableStateFlow(SeedData.logInitialRatings)
    private val _lists = MutableStateFlow(SeedData.initialLists)
    private val _notificationPreferences = MutableStateFlow(SeedData.defaultNotificationPreferences)
    private val _latestRecap = MutableStateFlow<WeeklyRecap?>(SeedData.initialRecap)
    private val _syncMessage = MutableStateFlow<String?>(null)

    private var accessToken: String? = null

    override val feedItems: StateFlow<List<FeedItem>> = _feedItems.asStateFlow()
    override val albums: StateFlow<List<Album>> = _albums.asStateFlow()
    override val profile: StateFlow<UserProfile> = _profile.asStateFlow()
    override val ratings: StateFlow<Map<String, Float>> = _ratings.asStateFlow()
    override val lists: StateFlow<List<UserList>> = _lists.asStateFlow()
    override val pendingOutboxOps: StateFlow<List<OutboxOperation>> = outboxStore.pending
    override val notificationPreferences: StateFlow<NotificationPreferences> = _notificationPreferences.asStateFlow()
    override val latestRecap: StateFlow<WeeklyRecap?> = _latestRecap.asStateFlow()
    override val syncMessage: StateFlow<String?> = _syncMessage.asStateFlow()

    init {
        scope.launch {
            refresh()
            syncOutbox()
        }
    }

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

    override suspend fun refresh() {
        runCatching {
            ensureAuth()
            val token = bearerToken()

            val remoteAlbums = api.searchAlbums(query = "", authHeader = token).items
            _albums.value = remoteAlbums.map(::mapAlbum)

            val remoteProfile = api.me(token)
            _profile.value = _profile.value.copy(
                handle = remoteProfile.handle,
                bio = remoteProfile.bio,
                logCount = remoteProfile.logCount,
                reviewCount = remoteProfile.reviewCount,
                listCount = remoteProfile.listCount,
                avgRating = remoteProfile.avgRating,
            )

            val remoteFeed = api.feed(token).items
            _feedItems.value = remoteFeed.map(::mapFeedItem)

            val prefs = api.getNotificationPreferences(token)
            _notificationPreferences.value = NotificationPreferences(
                socialEnabled = prefs.socialEnabled,
                recapEnabled = prefs.recapEnabled,
                commentEnabled = prefs.commentEnabled,
                reactionEnabled = prefs.reactionEnabled,
                quietHoursStart = prefs.quietHoursStart,
                quietHoursEnd = prefs.quietHoursEnd,
            )

            runCatching {
                val recap = api.latestRecap(token)
                _latestRecap.value = WeeklyRecap(
                    id = recap.id,
                    weekStart = recap.weekStart,
                    weekEnd = recap.weekEnd,
                    totalLogs = recap.totalLogs,
                    averageRating = recap.averageRating,
                    shareText = recap.shareText,
                    deepLink = recap.deepLink,
                )
            }

            _syncMessage.value = null
        }.onFailure {
            _syncMessage.value = "Offline mode: ${it.message ?: "sync unavailable"}"
        }
    }

    override suspend fun updateRating(albumId: String, rating: Float) {
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

        syncOutbox()
    }

    override suspend fun toggleLike(feedItemId: String) {
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

        syncOutbox()
    }

    override suspend fun createList(title: String) {
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

        syncOutbox()
    }

    override suspend fun exportSnapshot(): String {
        ensureAuth()
        val exportPayload = api.exportData(bearerToken())
        return Json { prettyPrint = true }.encodeToString(
            kotlinx.serialization.json.JsonObject.serializer(),
            exportPayload,
        )
    }

    override suspend fun updateNotificationPreferences(preferences: NotificationPreferences) {
        _notificationPreferences.value = preferences
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.UPSERT_NOTIFICATION_PREFERENCES,
                payload = mapOf(
                    "socialEnabled" to preferences.socialEnabled.toString(),
                    "recapEnabled" to preferences.recapEnabled.toString(),
                    "commentEnabled" to preferences.commentEnabled.toString(),
                    "reactionEnabled" to preferences.reactionEnabled.toString(),
                    "quietHoursStart" to preferences.quietHoursStart.toString(),
                    "quietHoursEnd" to preferences.quietHoursEnd.toString(),
                ),
            ),
        )
        syncOutbox()
    }

    override suspend fun registerDeviceToken(platform: String, token: String) {
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.REGISTER_DEVICE_TOKEN,
                payload = mapOf(
                    "platform" to platform,
                    "deviceToken" to token,
                ),
            ),
        )
        syncOutbox()
    }

    override suspend fun loadLatestRecap() {
        runCatching {
            ensureAuth()
            val recap = api.latestRecap(bearerToken())
            _latestRecap.value = WeeklyRecap(
                id = recap.id,
                weekStart = recap.weekStart,
                weekEnd = recap.weekEnd,
                totalLogs = recap.totalLogs,
                averageRating = recap.averageRating,
                shareText = recap.shareText,
                deepLink = recap.deepLink,
            )
            _syncMessage.value = null
        }.onFailure {
            _syncMessage.value = "Unable to load recap"
        }
    }

    override suspend fun generateLatestRecap() {
        outboxStore.enqueue(
            OutboxOperation(
                type = OutboxOperationType.GENERATE_RECAP,
                payload = emptyMap(),
            ),
        )
        syncOutbox()
        loadLatestRecap()
    }

    override suspend fun syncOutbox() {
        outboxSyncEngine.flush { operation ->
            ensureAuth()
            val token = bearerToken()
            when (operation.type) {
                OutboxOperationType.RATE_ALBUM -> {
                    val albumId = operation.payload.getValue("albumId")
                    val rating = operation.payload.getValue("rating").toFloat()
                    api.rateAlbum(
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                        request = RatingRequest(albumId = albumId, value = rating),
                    )
                }

                OutboxOperationType.TOGGLE_REACTION -> {
                    val activityId = operation.payload["feedItemId"] ?: return@flush
                    api.reactToActivity(
                        activityId = activityId,
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                        request = ReactionRequest(reaction = "like"),
                    )
                }

                OutboxOperationType.CREATE_LIST -> {
                    val title = operation.payload.getValue("title")
                    api.createList(
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                        request = CreateListRequest(title = title),
                    )
                }

                OutboxOperationType.EXPORT_DATA -> {
                    // Snapshot export is handled directly via exportSnapshot().
                }

                OutboxOperationType.REGISTER_DEVICE_TOKEN -> {
                    api.registerDeviceToken(
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                        request = DeviceTokenRequest(
                            platform = operation.payload.getValue("platform"),
                            deviceToken = operation.payload.getValue("deviceToken"),
                        ),
                    )
                }

                OutboxOperationType.UPSERT_NOTIFICATION_PREFERENCES -> {
                    api.upsertNotificationPreferences(
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                        request = NotificationPreferenceDto(
                            socialEnabled = operation.payload.getValue("socialEnabled").toBooleanStrict(),
                            recapEnabled = operation.payload.getValue("recapEnabled").toBooleanStrict(),
                            commentEnabled = operation.payload.getValue("commentEnabled").toBooleanStrict(),
                            reactionEnabled = operation.payload.getValue("reactionEnabled").toBooleanStrict(),
                            quietHoursStart = operation.payload.getValue("quietHoursStart").toInt(),
                            quietHoursEnd = operation.payload.getValue("quietHoursEnd").toInt(),
                        ),
                    )
                }

                OutboxOperationType.GENERATE_RECAP -> {
                    api.generateRecap(
                        authHeader = token,
                        idempotencyKey = operation.idempotencyKey,
                    )
                }
            }
        }

        val pending = pendingOutboxOps.value
        if (pending.isEmpty()) {
            _syncMessage.value = null
            return
        }

        val waitingRetry = pending.count { it.nextAttemptAtMs > System.currentTimeMillis() }
        _syncMessage.value = if (waitingRetry > 0) {
            "Pending ${pending.size} offline ops (${waitingRetry} retry scheduled)"
        } else {
            "Pending ${pending.size} offline ops"
        }
    }

    private suspend fun ensureAuth() {
        if (accessToken != null) {
            return
        }

        val email = "phase1b@local.soundscore.app"
        val password = "soundscore-dev-pass"
        val handle = "madhav"

        val auth = runCatching {
            api.login(AuthRequest(email = email, password = password))
        }.getOrElse {
            api.signUp(AuthRequest(email = email, password = password, handle = handle))
        }

        accessToken = auth.accessToken
    }

    private fun bearerToken(): String {
        val token = accessToken ?: error("Auth token not available")
        return "Bearer $token"
    }

    private fun mapAlbum(dto: AlbumDto): Album {
        val colors = SeedData.albums.find { it.id == dto.id }?.artColors
            ?: SeedData.albums.random().artColors

        return Album(
            id = dto.id,
            title = dto.title,
            artist = dto.artist,
            year = dto.year,
            artColors = colors,
            avgRating = dto.avgRating,
            logCount = dto.logCount,
        )
    }

    private fun mapFeedItem(event: ActivityEventDto): FeedItem {
        val albumId = event.payload["albumId"]?.jsonPrimitive?.contentOrNull
        val album = _albums.value.find { it.id == albumId } ?: _albums.value.firstOrNull() ?: SeedData.albums.first()
        val rating = event.payload["rating"]?.jsonPrimitive?.floatOrNull ?: 0f

        val action = when (event.type) {
            "RATED_ALBUM" -> "rated"
            "WROTE_REVIEW" -> "reviewed"
            "CREATED_LIST" -> "created a list"
            "ADDED_LIST_ITEM" -> "updated a list"
            else -> "posted"
        }

        return FeedItem(
            id = event.id,
            username = event.actorId,
            action = action,
            album = album,
            rating = rating,
            reviewSnippet = null,
            likes = event.reactions,
            comments = event.comments,
            timeAgo = event.createdAt.take(16),
            isLiked = false,
        )
    }
}

object AppContainer {
    val repository: SoundScoreRepository by lazy {
        RemoteSoundScoreRepository()
    }
}
