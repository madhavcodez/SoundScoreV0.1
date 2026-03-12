package com.soundscore.app.data.api

import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query
import kotlinx.serialization.json.JsonObject

interface SoundScoreApi {
    @POST("/v1/auth/signup")
    suspend fun signUp(@Body request: AuthRequest): AuthResponse

    @POST("/v1/auth/login")
    suspend fun login(@Body request: AuthRequest): AuthResponse

    @POST("/v1/auth/refresh")
    suspend fun refresh(@Body request: RefreshRequest): AuthResponse

    @GET("/v1/me")
    suspend fun me(
        @Header("Authorization") authHeader: String,
    ): UserProfileDto

    @GET("/v1/search")
    suspend fun searchAlbums(
        @Query("q") query: String,
        @Header("Authorization") authHeader: String? = null,
    ): CursorPage<AlbumDto>

    @GET("/v1/albums/{id}")
    suspend fun getAlbum(
        @Path("id") albumId: String,
        @Header("Authorization") authHeader: String? = null,
    ): AlbumDto

    @POST("/v1/ratings")
    suspend fun rateAlbum(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: RatingRequest,
    )

    @POST("/v1/reviews")
    suspend fun createReview(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: ReviewRequest,
    )

    @PUT("/v1/reviews/{id}")
    suspend fun updateReview(
        @Path("id") reviewId: String,
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: UpdateReviewRequest,
    )

    @POST("/v1/lists")
    suspend fun createList(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: CreateListRequest,
    )

    @POST("/v1/lists/{id}/items")
    suspend fun addListItem(
        @Path("id") listId: String,
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: AddListItemRequest,
    )

    @GET("/v1/feed")
    suspend fun feed(
        @Header("Authorization") authHeader: String,
    ): CursorPage<ActivityEventDto>

    @POST("/v1/activity/{id}/react")
    suspend fun reactToActivity(
        @Path("id") activityId: String,
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: ReactionRequest,
    )

    @POST("/v1/account/export")
    suspend fun exportData(
        @Header("Authorization") authHeader: String,
    ): JsonObject

    @DELETE("/v1/account")
    suspend fun deleteAccount(
        @Header("Authorization") authHeader: String,
    )

    @GET("/v1/recaps/weekly/latest")
    suspend fun latestRecap(
        @Header("Authorization") authHeader: String,
    ): WeeklyRecapDto

    @POST("/v1/recaps/weekly/generate")
    suspend fun generateRecap(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
    ): WeeklyRecapDto

    @POST("/v1/push/tokens")
    suspend fun registerDeviceToken(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: DeviceTokenRequest,
    )

    @DELETE("/v1/push/tokens/{token}")
    suspend fun unregisterDeviceToken(
        @Path("token") token: String,
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
    )

    @GET("/v1/push/preferences")
    suspend fun getNotificationPreferences(
        @Header("Authorization") authHeader: String,
    ): NotificationPreferenceDto

    @PUT("/v1/push/preferences")
    suspend fun upsertNotificationPreferences(
        @Header("Authorization") authHeader: String,
        @Header("idempotency-key") idempotencyKey: String,
        @Body request: NotificationPreferenceDto,
    ): NotificationPreferenceDto

    @GET("/v1/notifications")
    suspend fun getNotifications(
        @Header("Authorization") authHeader: String,
    ): CursorPage<JsonObject>
}
