package com.soundscore.app.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.repository.AppContainer
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SearchUiState(
    val query: String = "",
    val results: List<Album> = emptyList(),
    val browseGenres: List<BrowseGenre> = emptyList(),
    val chartEntries: List<ChartEntry> = emptyList(),
    val syncMessage: String? = null,
)

class SearchViewModel : ViewModel() {
    private val repository = AppContainer.repository
    private val query = MutableStateFlow("")

    val uiState: StateFlow<SearchUiState> = combine(
        query,
        repository.albums,
        repository.syncMessage,
    ) { text, albums, syncMessage ->
        val results = resolveSearchResults(text, albums, repository::searchAlbums)
        SearchUiState(
            query = text,
            results = results,
            browseGenres = buildBrowseGenres(),
            chartEntries = buildChartEntries(albums),
            syncMessage = syncMessage,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = SearchUiState(),
    )

    init {
        viewModelScope.launch {
            repository.refresh()
        }
    }

    fun updateQuery(next: String) {
        query.update { next }
    }
}
