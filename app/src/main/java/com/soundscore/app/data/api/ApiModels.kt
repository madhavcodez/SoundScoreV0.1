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
