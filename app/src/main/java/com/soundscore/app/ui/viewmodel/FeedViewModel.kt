package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.SharingStarted
import androidx.lifecycle.viewModelScope

data class FeedUiState(
    val items: List<FeedItem> = emptyList(),
)

class FeedViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<FeedUiState> = repository.feedItems
        .map { FeedUiState(items = it) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = FeedUiState(),
        )

    fun toggleLike(feedItemId: String) {
        repository.toggleLike(feedItemId)
    }
}
