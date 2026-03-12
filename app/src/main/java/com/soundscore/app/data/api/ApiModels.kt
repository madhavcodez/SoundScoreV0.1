package com.soundscore.app.data.api

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ApiEnvelope<T>(
    val data: T,
)

@Serializable
data class ErrorEnvelope(
    val error: ApiError,
)

@Serializable
data class ApiError(
    val code: String,
    val message: String,
    val requestId: String,
)

@Serializable
data class CursorPage<T>(
    val items: List<T>,
    val nextCursor: String? = null,
)

@Serializable
data class AuthRequest(
    val email: String,
    val password: String,
    val handle: String? = null,
)

@Serializable
data class RefreshRequest(
    val refreshToken: String,
)

@Serializable
data class AuthResponse(
    val accessToken: String,
    val refreshToken: String,
    val userId: String,
    val handle: String,
)

@Serializable
data class AlbumDto(
    val id: String,
    val title: String,
    val artist: String,
    val year: Int,
    val artworkUrl: String? = null,
    val avgRating: Float,
    val logCount: Int,
)

@Serializable
data class RatingRequest(
    val albumId: String,
    val value: Float,
)

@Serializable
data class ReviewRequest(
    val albumId: String,
    val body: String,
)

@Serializable
data class UpdateReviewRequest(
    val body: String,
    @SerialName("expectedRevision") val expectedRevision: Int,
)

@Serializable
data class CreateListRequest(
    val title: String,
    val note: String? = null,
)

@Serializable
data class AddListItemRequest(
    val albumId: String,
    val note: String? = null,
)

@Serializable
data class UserProfileDto(
    val id: String,
    val handle: String,
    val bio: String,
    val logCount: Int,
    val reviewCount: Int,
    val listCount: Int,
    val avgRating: Float,
)

@Serializable
data class NotificationPreferenceDto(
    val socialEnabled: Boolean,
    val recapEnabled: Boolean,
    val commentEnabled: Boolean,
    val reactionEnabled: Boolean,
    val quietHoursStart: Int,
    val quietHoursEnd: Int,
)

@Serializable
data class DeviceTokenRequest(
    val platform: String,
    val deviceToken: String,
)

@Serializable
data class RecapAlbumDto(
    val albumId: String,
    val rating: Float,
)

@Serializable
data class WeeklyRecapDto(
    val id: String,
    val userId: String,
    val weekStart: String,
    val weekEnd: String,
    val totalLogs: Int,
    val averageRating: Float,
    val topAlbums: List<RecapAlbumDto>,
    val shareText: String,
    val deepLink: String,
    val createdAt: String,
)

@Serializable
data class ActivityObjectDto(
    val type: String,
    val id: String,
)

@Serializable
data class ActivityEventDto(
    val id: String,
    val actorId: String,
    val type: String,
    @SerialName("object") val activityObject: ActivityObjectDto,
    val createdAt: String,
    val payload: Map<String, @JvmSuppressWildcards kotlinx.serialization.json.JsonElement>,
    val reactions: Int,
    val comments: Int,
)

@Serializable
data class ReactionRequest(
    val reaction: String,
)
