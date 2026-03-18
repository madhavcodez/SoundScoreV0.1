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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PlaylistAdd
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.ui.components.AlbumArtwork
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.EmptyState
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.MosaicCover
import com.soundscore.app.ui.components.PillSearchBar
import com.soundscore.app.ui.components.ScreenHeader
import com.soundscore.app.ui.components.SectionHeader
import com.soundscore.app.ui.components.SyncBanner
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.DarkElevated
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.ListShowcase
import com.soundscore.app.ui.viewmodel.ListsUiState
import com.soundscore.app.ui.viewmodel.ListsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ListsScreen(
    modifier: Modifier = Modifier,
    listsViewModel: ListsViewModel = viewModel(),
) {
    val uiState by listsViewModel.uiState.collectAsStateWithLifecycle()
    var showCreateSheet by remember { mutableStateOf(false) }
    var draftTitle by remember { mutableStateOf("") }

    if (showCreateSheet) {
        ModalBottomSheet(
            onDismissRequest = { showCreateSheet = false },
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
                    text = "Create a list",
                    style = MaterialTheme.typography.headlineSmall,
                    color = ChromeLight,
                )
                Spacer(Modifier.height(16.dp))
                PillSearchBar(
                    query = draftTitle,
                    onQueryChange = { draftTitle = it },
                    placeholder = "Albums I Would Defend...",
                )
                Spacer(Modifier.height(20.dp))
                BlueButton(
                    text = "Create",
                    onClick = {
                        if (draftTitle.isNotBlank()) {
                            listsViewModel.createList(draftTitle)
                            draftTitle = ""
                            showCreateSheet = false
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = draftTitle.isNotBlank(),
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }

    ListsScreenContent(
        uiState = uiState,
        modifier = modifier,
        onCreateClick = { showCreateSheet = true },
    )
}

@Composable
fun ListsScreenContent(
    uiState: ListsUiState,
    onCreateClick: () -> Unit,
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
                title = "Lists",
                subtitle = "Curated collections worth sharing.",
                actionLabel = "Create",
                onActionClick = onCreateClick,
            )
        }

        if (uiState.showcases.isNotEmpty()) {
            item {
                FeaturedListHero(showcase = uiState.showcases.first())
            }
        }

        if (uiState.showcases.size > 1) {
            item {
                SectionHeader(eyebrow = "Your lists", title = "Collections")
            }

            item {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(end = 8.dp),
                ) {
                    items(uiState.showcases.drop(1), key = { it.list.id }) { showcase ->
                        CompactListCard(showcase = showcase)
                    }
                }
            }
        }

        if (uiState.showcases.isEmpty()) {
            item {
                EmptyState(
                    title = "Build your first collection",
                    subtitle = "Arrange records into ranked moods, eras, or arguments worth sharing.",
                    icon = Icons.Outlined.PlaylistAdd,
                    actionLabel = "Create a list",
                    onAction = onCreateClick,
                )
            }
        }

    }
}

@Composable
private fun FeaturedListHero(showcase: ListShowcase) {
    GlassCard(
        cornerRadius = 24.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(0.dp),
    ) {
        Box(modifier = Modifier.fillMaxWidth().height(180.dp)) {
            val coverAlbum = showcase.coverAlbums.firstOrNull()
            if (coverAlbum != null) {
                AlbumArtwork(
                    artworkUrl = coverAlbum.artworkUrl,
                    colors = coverAlbum.artColors,
                    modifier = Modifier.fillMaxSize(),
                    cornerRadius = 0.dp,
                )
            }
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.75f)),
                            startY = 40f,
                        )
                    ),
            )
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(16.dp),
            ) {
                Text(
                    text = "FEATURED",
                    style = MaterialTheme.typography.labelSmall,
                    color = AccentGreen,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = showcase.list.title,
                    style = MaterialTheme.typography.headlineMedium,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = "${showcase.list.curatorHandle} · ${showcase.list.albumIds.size} albums · ${showcase.list.saves} saves",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.7f),
                )
            }
        }
    }
}

@Composable
private fun CompactListCard(showcase: ListShowcase) {
    GlassCard(
        modifier = Modifier.width(180.dp),
        fillMaxWidth = false,
        cornerRadius = 20.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(10.dp),
        onClick = { },
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            MosaicCover(
                albums = showcase.coverAlbums,
                cornerRadius = 14.dp,
            )
            Text(
                text = showcase.list.title,
                style = MaterialTheme.typography.titleMedium,
                color = ChromeLight,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
            )
            Text(
                text = "${showcase.list.albumIds.size} albums",
                style = MaterialTheme.typography.bodySmall,
                color = TextTertiary,
            )
        }
    }
}
