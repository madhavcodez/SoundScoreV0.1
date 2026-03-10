package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

data class ProfileUiState(
    val profile: UserProfile? = null,
)

class ProfileViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<ProfileUiState> = repository.profile
        .map { ProfileUiState(profile = it) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ProfileUiState(),
        )

    fun buildShareText(): String {
        val profile = uiState.value.profile ?: return "SoundScore profile"
        return "${profile.handle} on SoundScore\n${profile.bio}\nAvg Rating: ${String.format("%.1f", profile.avgRating)}"
    }

    fun exportDataSnapshot(): String {
        return repository.exportSnapshot()
    }
}
