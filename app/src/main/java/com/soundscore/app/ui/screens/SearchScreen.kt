package com.soundscore.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.data.model.Album
import com.soundscore.app.ui.components.AlbumArtwork
import com.soundscore.app.ui.components.EmptyState
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.PillSearchBar
import com.soundscore.app.ui.components.ScreenHeader
import com.soundscore.app.ui.components.SectionHeader
import com.soundscore.app.ui.components.StarRating
import com.soundscore.app.ui.components.SyncBanner
import com.soundscore.app.ui.components.TrendChartRow
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.BrowseGenre
import com.soundscore.app.ui.viewmodel.SearchUiState
import com.soundscore.app.ui.viewmodel.SearchViewModel

@Composable
fun SearchScreen(
    modifier: Modifier = Modifier,
    searchViewModel: SearchViewModel = viewModel(),
) {
    val uiState by searchViewModel.uiState.collectAsStateWithLifecycle()
    SearchScreenContent(
        uiState = uiState,
        modifier = modifier,
        onQueryChange = searchViewModel::updateQuery,
    )
}

@Composable
fun SearchScreenContent(
    uiState: SearchUiState,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 20.dp, top = 16.dp, end = 20.dp, bottom = 120.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            SyncBanner(message = uiState.syncMessage)
        }

        item {
            ScreenHeader(
                title = "Discover",
                subtitle = "Browse by mood, genre, or find the record in your head.",
            )
        }

        item {
            PillSearchBar(
                query = uiState.query,
                onQueryChange = onQueryChange,
            )
        }

        if (uiState.query.isBlank()) {
            if (uiState.chartEntries.isNotEmpty()) {
                item {
                    SectionHeader(eyebrow = "Trending now", title = "Most logged this week")
                }

                item {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                        contentPadding = PaddingValues(end = 8.dp),
                    ) {
                        items(uiState.chartEntries.take(4), key = { it.album.id }) { entry ->
                            TrendingSearchCard(
                                album = entry.album,
                                rank = entry.rank,
                            )
                        }
                    }
                }
            }

            item {
                SectionHeader(eyebrow = "Browse", title = "Explore by genre")
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    uiState.browseGenres.chunked(2).forEach { rowGenres ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            rowGenres.forEach { genre ->
                                GenreCard(genre = genre, modifier = Modifier.weight(1f))
                            }
                            if (rowGenres.size == 1) {
                                Spacer(Modifier.weight(1f))
                            }
                        }
                    }
                }
            }

            item {
                SectionHeader(eyebrow = "Charts", title = "What SoundScore is logging")
            }

            items(uiState.chartEntries, key = { it.album.id }) { entry ->
                TrendChartRow(entry = entry)
            }

        } else {
            item {
                SectionHeader(
                    eyebrow = "Results",
                    title = "${uiState.results.size} matches",
                )
            }

            items(uiState.results, key = { it.id }) { album ->
                SearchResultCard(album = album)
            }

            if (uiState.results.isEmpty()) {
                item {
                    EmptyState(
                        title = "No results found",
                        subtitle = "Try a different search term or check your spelling.",
                        icon = Icons.Outlined.SearchOff,
                    )
                }
            }
        }
    }
}

@Composable
private fun TrendingSearchCard(
    album: Album,
    rank: Int,
) {
    GlassCard(
        modifier = Modifier.size(width = 160.dp, height = 200.dp),
        fillMaxWidth = false,
        cornerRadius = 20.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(0.dp),
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            AlbumArtwork(
                artworkUrl = album.artworkUrl,
                colors = album.artColors,
                modifier = Modifier.fillMaxSize(),
                cornerRadius = 0.dp,
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.65f)),
                            startY = 80f,
                        )
                    ),
            )
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(AccentGreen.copy(alpha = 0.9f))
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            ) {
                Text(
                    text = "#$rank",
                    style = MaterialTheme.typography.labelMedium,
                    color = Color.Black,
                    fontWeight = FontWeight.Black,
                )
            }
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(10.dp),
            ) {
                Text(
                    text = album.title,
                    style = MaterialTheme.typography.titleSmall,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                )
                Text(
                    text = album.artist,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f),
                    maxLines = 1,
                )
            }
        }
    }
}

@Composable
private fun GenreCard(
    genre: BrowseGenre,
    modifier: Modifier = Modifier,
) {
    GlassCard(
        modifier = modifier.height(120.dp),
        fillMaxWidth = true,
        cornerRadius = 20.dp,
        tintColor = genre.colors.last(),
        borderColor = FeedItemBorder,
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(Brush.linearGradient(genre.colors)),
            )
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = genre.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = genre.caption,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
            }
        }
    }
}

@Composable
private fun SearchResultCard(album: Album) {
    GlassCard(
        cornerRadius = 18.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AlbumArtwork(
                artworkUrl = album.artworkUrl,
                colors = album.artColors,
                modifier = Modifier.size(64.dp),
                cornerRadius = 16.dp,
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = album.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = "${album.artist} · ${album.year}",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                StarRating(rating = album.avgRating, starSize = 12.dp)
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "${album.logCount} logs",
                    style = MaterialTheme.typography.labelSmall,
                    color = TextTertiary,
                )
            }
        }
    }
}
