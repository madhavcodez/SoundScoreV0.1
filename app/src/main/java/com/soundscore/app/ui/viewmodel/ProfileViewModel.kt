package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.model.NotificationPreferences
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.data.model.WeeklyRecap
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ProfileUiState(
    val profile: UserProfile? = null,
    val metrics: List<ProfileMetric> = emptyList(),
    val favoriteAlbums: List<Album> = emptyList(),
    val notificationPreferences: NotificationPreferences = NotificationPreferences(),
    val latestRecap: WeeklyRecap? = null,
    val syncMessage: String? = null,
    val recentActivity: List<FeedItem> = emptyList(),
)

class ProfileViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<ProfileUiState> = combine(
        repository.profile,
        repository.notificationPreferences,
        repository.latestRecap,
        repository.syncMessage,
        repository.feedItems,
    ) { profile, prefs, recap, syncMessage, feedItems ->
        ProfileUiState(
            profile = profile,
            metrics = buildProfileMetrics(profile),
            favoriteAlbums = buildFavoriteAlbums(profile),
            notificationPreferences = prefs,
            latestRecap = recap,
            syncMessage = syncMessage,
            recentActivity = feedItems.take(3),
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ProfileUiState(),
    )

    init {
        viewModelScope.launch {
            repository.refresh()
            repository.registerDeviceToken(
                platform = "android",
                token = "emulator-debug-token", // TODO: Replace with real FCM token from Firebase Messaging
            )
            repository.loadLatestRecap()
        }
    }

    fun buildShareText(): String {
        val profile = uiState.value.profile ?: return "SoundScore profile"
        return "${profile.handle} on SoundScore\n${profile.bio}\nAvg Rating: ${String.format("%.1f", profile.avgRating)}"
    }

    fun exportDataSnapshot(onComplete: (String) -> Unit) {
        viewModelScope.launch {
            val snapshot = repository.exportSnapshot()
            onComplete(snapshot)
        }
    }

    fun updateNotificationPreferences(preferences: NotificationPreferences) {
        viewModelScope.launch {
            repository.updateNotificationPreferences(preferences)
        }
    }

    fun generateRecap() {
        viewModelScope.launch {
            repository.generateLatestRecap()
        }
    }
}
