package com.soundscore.app.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.ui.components.ActionChip
import com.soundscore.app.ui.components.AlbumArtwork
import com.soundscore.app.ui.components.AvatarCircle
import com.soundscore.app.ui.components.EmptyState
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.ScreenHeader
import com.soundscore.app.ui.components.SectionHeader
import com.soundscore.app.ui.components.StarRating
import com.soundscore.app.ui.components.SyncBanner
import com.soundscore.app.ui.theme.AccentCoral
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AlbumColors
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.FeedUiState
import com.soundscore.app.ui.viewmodel.FeedViewModel
import kotlinx.coroutines.delay

@Composable
fun FeedScreen(
    modifier: Modifier = Modifier,
    feedViewModel: FeedViewModel = viewModel(),
) {
    val uiState by feedViewModel.uiState.collectAsStateWithLifecycle()
    FeedScreenContent(
        uiState = uiState,
        modifier = modifier,
        onToggleLike = feedViewModel::toggleLike,
    )
}

@Composable
fun FeedScreenContent(
    uiState: FeedUiState,
    onToggleLike: (String) -> Unit,
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
                title = "Feed",
                subtitle = "What your people are logging right now.",
            )
        }

        if (uiState.trendingAlbums.isNotEmpty()) {
            item {
                SectionHeader(eyebrow = "Trending", title = "Hot this week")
            }

            item {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                    contentPadding = PaddingValues(end = 8.dp),
                ) {
                    items(uiState.trendingAlbums, key = { it.id }) { album ->
                        TrendingHeroCard(album = album)
                    }
                }
            }
        }

        if (uiState.items.isEmpty()) {
            item {
                EmptyState(
                    title = "Your feed is quiet",
                    subtitle = "Follow friends to see their ratings, reviews, and lists here.",
                    icon = Icons.Outlined.People,
                )
            }
        } else {
            item {
                SectionHeader(eyebrow = "Activity", title = "From your circle")
            }

            itemsIndexed(uiState.items, key = { _, it -> it.id }) { index, item ->
                var visible by remember(item.id) { mutableStateOf(false) }
                LaunchedEffect(item.id) {
                    delay((index * 40).toLong())
                    visible = true
                }

                AnimatedVisibility(
                    visible = visible,
                    enter = fadeIn(animationSpec = tween(300)) + slideInVertically(
                        initialOffsetY = { 30 },
                        animationSpec = tween(300),
                    ),
                ) {
                    FeedActivityCard(
                        item = item,
                        onToggleLike = { onToggleLike(item.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun TrendingHeroCard(album: Album) {
    GlassCard(
        modifier = Modifier.size(width = 200.dp, height = 260.dp),
        fillMaxWidth = false,
        cornerRadius = 24.dp,
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
                            colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.7f)),
                            startY = 100f,
                        )
                    ),
            )
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(14.dp),
            ) {
                Text(
                    text = album.title,
                    style = MaterialTheme.typography.titleLarge,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2,
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = album.artist,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.8f),
                )
                Spacer(Modifier.height(6.dp))
                Row(
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    StarRating(rating = album.avgRating, starSize = 12.dp)
                    Text(
                        text = "${album.logCount}",
                        style = MaterialTheme.typography.labelSmall,
                        color = AccentGreen,
                    )
                }
            }
        }
    }
}

@Composable
private fun FeedActivityCard(
    item: FeedItem,
    onToggleLike: () -> Unit,
) {
    GlassCard(
        cornerRadius = 22.dp,
        borderColor = FeedItemBorder,
        contentPadding = PaddingValues(12.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    AvatarCircle(
                        initials = item.username.take(2),
                        gradientColors = avatarColors(item.username),
                        size = 38.dp,
                    )
                    Column {
                        Text(
                            text = "@${item.username}",
                            style = MaterialTheme.typography.titleMedium,
                            color = ChromeLight,
                            fontWeight = FontWeight.Bold,
                        )
                        Text(
                            text = item.action,
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                    }
                }
                Text(
                    text = item.timeAgo,
                    style = MaterialTheme.typography.labelSmall,
                    color = TextTertiary,
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AlbumArtwork(
                    artworkUrl = item.album.artworkUrl,
                    colors = item.album.artColors,
                    modifier = Modifier.size(72.dp),
                    cornerRadius = 16.dp,
                )
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text(
                        text = item.album.title,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        text = "${item.album.artist} · ${item.album.year}",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary,
                    )
                    StarRating(rating = item.rating, starSize = 14.dp)
                }
            }

            if (!item.reviewSnippet.isNullOrBlank()) {
                Text(
                    text = "\"${item.reviewSnippet}\"",
                    style = MaterialTheme.typography.bodyMedium,
                    color = ChromeLight.copy(alpha = 0.9f),
                    fontStyle = FontStyle.Italic,
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ActionChip(
                    text = "${item.likes}",
                    icon = Icons.Outlined.FavoriteBorder,
                    active = item.isLiked,
                    onClick = onToggleLike,
                )
                ActionChip(
                    text = "${item.comments}",
                    icon = Icons.Outlined.ChatBubbleOutline,
                )
                ActionChip(
                    text = "Share",
                    icon = Icons.Outlined.Share,
                )
            }
        }
    }
}

private fun avatarColors(username: String): List<Color> {
    val palettes = listOf(
        AlbumColors.forest, AlbumColors.rose, AlbumColors.orchid,
        AlbumColors.lagoon, AlbumColors.amber, AlbumColors.midnight,
        AlbumColors.lime, AlbumColors.ember, AlbumColors.coral,
        AlbumColors.slate,
    )
    return palettes[kotlin.math.abs(username.hashCode()) % palettes.count()]
}
