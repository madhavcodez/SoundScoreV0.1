package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class FeedUiState(
    val items: List<FeedItem> = emptyList(),
    val syncMessage: String? = null,
)

class FeedViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<FeedUiState> = combine(
        repository.feedItems,
        repository.syncMessage,
    ) { items, syncMessage ->
        FeedUiState(items = items, syncMessage = syncMessage)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = FeedUiState(),
    )

    init {
        viewModelScope.launch {
            repository.refresh()
        }
    }

    fun toggleLike(feedItemId: String) {
        viewModelScope.launch {
            repository.toggleLike(feedItemId)
        }
    }
}
