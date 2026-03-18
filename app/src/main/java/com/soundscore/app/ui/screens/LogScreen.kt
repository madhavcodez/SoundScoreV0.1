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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.data.model.Album
import com.soundscore.app.ui.components.AlbumArtwork
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.ScreenHeader
import com.soundscore.app.ui.components.SectionHeader
import com.soundscore.app.ui.components.StarRating
import com.soundscore.app.ui.components.StatPill
import com.soundscore.app.ui.components.SyncBanner
import com.soundscore.app.ui.components.TimelineEntry
import com.soundscore.app.ui.theme.AccentAmber
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AccentGreenDim
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.DarkBase
import com.soundscore.app.ui.theme.DarkElevated
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.LogUiState
import com.soundscore.app.ui.viewmodel.LogViewModel
import com.soundscore.app.ui.viewmodel.RecentLogEntry

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LogScreen(
    modifier: Modifier = Modifier,
    logViewModel: LogViewModel = viewModel(),
) {
    val uiState by logViewModel.uiState.collectAsStateWithLifecycle()
    var showSearchSheet by remember { mutableStateOf(false) }

    if (showSearchSheet) {
        ModalBottomSheet(
            onDismissRequest = { showSearchSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = DarkElevated,
            shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 16.dp),
            ) {
                Text(
                    text = "Log an album",
                    style = MaterialTheme.typography.headlineSmall,
                    color = ChromeLight,
                )
                Spacer(Modifier.height(16.dp))
                Text(
                    text = "Album search coming soon. Use the Quick Rate cards below to log albums.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextSecondary,
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        LogScreenContent(
            uiState = uiState,
            onRate = logViewModel::updateRating,
        )

        FloatingActionButton(
            onClick = { showSearchSheet = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 20.dp, bottom = 24.dp),
            shape = CircleShape,
            containerColor = AccentGreen,
            contentColor = DarkBase,
        ) {
            Icon(Icons.Filled.Add, contentDescription = "Log Album")
        }
    }
}

@Composable
fun LogScreenContent(
    uiState: LogUiState,
    onRate: (String, Float) -> Unit,
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
                title = "Diary",
                subtitle = "Your listening journal. Rate, log, repeat.",
            )
        }

        item {
            GlassCard(
                cornerRadius = 22.dp,
                borderColor = FeedItemBorder,
                frosted = true,
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                ) {
                    uiState.summaryStats.forEach { stat ->
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = stat.value,
                                style = MaterialTheme.typography.headlineMedium,
                                color = if (stat.label == "This week") AccentGreen else ChromeLight,
                                fontWeight = FontWeight.Black,
                            )
                            Spacer(Modifier.height(2.dp))
                            Text(
                                text = stat.label.uppercase(),
                                style = MaterialTheme.typography.labelSmall,
                                color = TextTertiary,
                            )
                        }
                    }
                }
            }
        }

        item {
            SectionHeader(
                eyebrow = "Quick rate",
                title = "Tap to rate",
            )
        }

        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(end = 8.dp),
            ) {
                items(uiState.quickLogAlbums, key = { it.id }) { album ->
                    QuickRateCard(
                        album = album,
                        rating = uiState.ratings[album.id] ?: 0f,
                        onRate = { onRate(album.id, it) },
                    )
                }
            }
        }

        if (uiState.recentLogs.isNotEmpty()) {
            item {
                SectionHeader(
                    eyebrow = "Recent",
                    title = "Your diary entries",
                )
            }

            items(uiState.recentLogs, key = { "${it.album.id}-${it.timeLabel}" }) { entry ->
                TimelineEntry(
                    dateLabel = entry.dateLabel,
                    timeLabel = entry.timeLabel,
                ) {
                    DiaryEntryCard(entry = entry)
                }
            }
        }

        item {
            GlassCard(
                cornerRadius = 20.dp,
                borderColor = FeedItemBorder,
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text(
                        text = "Write Later",
                        style = MaterialTheme.typography.titleMedium,
                        color = ChromeLight,
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "Queue albums for later review — coming soon",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextTertiary,
                    )
                }
            }
        }
    }
}

@Composable
private fun QuickRateCard(
    album: Album,
    rating: Float,
    onRate: (Float) -> Unit,
) {
    GlassCard(
        modifier = Modifier.width(140.dp),
        cornerRadius = 20.dp,
        fillMaxWidth = false,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(8.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Box {
                AlbumArtwork(
                    artworkUrl = album.artworkUrl,
                    colors = album.artColors,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(130.dp),
                    cornerRadius = 14.dp,
                )
                if (rating > 0f) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(6.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(DarkBase.copy(alpha = 0.7f))
                            .padding(horizontal = 6.dp, vertical = 3.dp),
                    ) {
                        Text(
                            text = String.format("%.1f", rating),
                            style = MaterialTheme.typography.labelSmall,
                            color = AccentAmber,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
            Text(
                text = album.title,
                style = MaterialTheme.typography.titleSmall,
                maxLines = 1,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = album.artist,
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary,
                maxLines = 1,
            )
            StarRating(
                rating = rating,
                onRate = onRate,
                starSize = 14.dp,
            )
        }
    }
}

@Composable
private fun DiaryEntryCard(entry: RecentLogEntry) {
    GlassCard(
        cornerRadius = 18.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AlbumArtwork(
                artworkUrl = entry.album.artworkUrl,
                colors = entry.album.artColors,
                modifier = Modifier.size(56.dp),
                cornerRadius = 14.dp,
            )
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Text(
                    text = entry.album.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text = entry.album.artist,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
                if (entry.caption.isNotBlank()) {
                    Text(
                        text = entry.caption,
                        style = MaterialTheme.typography.bodySmall,
                        color = TextTertiary,
                        maxLines = 1,
                    )
                }
            }
            StarRating(rating = entry.rating, starSize = 12.dp)
        }
    }
}


