package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class LogUiState(
    val albums: List<Album> = emptyList(),
    val ratings: Map<String, Float> = emptyMap(),
    val writeLaterQueue: List<Album> = emptyList(),
)

class LogViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<LogUiState> = combine(
        repository.albums,
        repository.ratings,
    ) { albums, ratings ->
        LogUiState(
            albums = albums,
            ratings = ratings,
            writeLaterQueue = albums.take(3),
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = LogUiState(),
    )

    fun updateRating(albumId: String, rating: Float) {
        repository.updateRating(albumId, rating)
    }
}
