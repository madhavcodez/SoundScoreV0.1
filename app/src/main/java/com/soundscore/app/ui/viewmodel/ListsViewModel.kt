package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.UserList
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ListsUiState(
    val lists: List<UserList> = emptyList(),
    val showcases: List<ListShowcase> = emptyList(),
    val syncMessage: String? = null,
)

class ListsViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<ListsUiState> = combine(
        repository.lists,
        repository.albums,
        repository.syncMessage,
    ) { lists, albums, syncMessage ->
        ListsUiState(
            lists = lists,
            showcases = resolveListShowcases(lists, albums),
            syncMessage = syncMessage,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ListsUiState(),
    )

    fun createList(title: String) {
        viewModelScope.launch {
            repository.createList(title)
        }
    }
}
