package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.UserList
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

data class ListsUiState(
    val lists: List<UserList> = emptyList(),
)

class ListsViewModel : ViewModel() {
    private val repository = AppContainer.repository

    val uiState: StateFlow<ListsUiState> = repository.lists
        .map { ListsUiState(lists = it) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ListsUiState(),
        )

    fun createList(title: String) {
        repository.createList(title)
    }
}
