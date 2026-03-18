package com.soundscore.app.ui.screens

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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.foundation.lazy.items
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.UserProfile
import com.soundscore.app.ui.components.AlbumArtwork
import com.soundscore.app.ui.components.AvatarCircle
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.EmptyState
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.GlassIconButton
import com.soundscore.app.ui.components.ScreenHeader
import com.soundscore.app.ui.components.SectionHeader
import com.soundscore.app.ui.components.StatPill
import com.soundscore.app.ui.components.SyncBanner
import com.soundscore.app.ui.theme.AccentAmber
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AccentViolet
import com.soundscore.app.ui.theme.AlbumColors
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.ProfileUiState
import com.soundscore.app.ui.viewmodel.ProfileViewModel

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    profileViewModel: ProfileViewModel = viewModel(),
) {
    val uiState by profileViewModel.uiState.collectAsStateWithLifecycle()
    ProfileScreenContent(
        uiState = uiState,
        modifier = modifier,
    )
}

@Composable
fun ProfileScreenContent(
    uiState: ProfileUiState,
    modifier: Modifier = Modifier,
) {
    val profile = uiState.profile

    if (profile == null) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Loading profile...", color = TextSecondary)
        }
        return
    }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 20.dp, top = 16.dp, end = 20.dp, bottom = 120.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            SyncBanner(message = uiState.syncMessage)
        }

        item {
            ProfileHeader(profile = profile)
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                StatPill(
                    value = "${profile.albumsCount}",
                    label = "Albums",
                    modifier = Modifier.weight(1f),
                    highlight = true,
                )
                StatPill(
                    value = "${profile.reviewCount}",
                    label = "Reviews",
                    modifier = Modifier.weight(1f),
                )
                StatPill(
                    value = "${profile.listCount}",
                    label = "Lists",
                    modifier = Modifier.weight(1f),
                )
                StatPill(
                    value = String.format("%.1f", profile.avgRating),
                    label = "Avg",
                    modifier = Modifier.weight(1f),
                    highlight = true,
                    accentColor = AccentAmber,
                )
            }
        }

        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
            ) {
                GlassIconButton(
                    icon = Icons.Outlined.Share,
                    label = "Share",
                    tint = AccentGreen,
                )
                GlassIconButton(
                    icon = Icons.Outlined.Download,
                    label = "Export",
                )
                GlassIconButton(
                    icon = Icons.Outlined.Settings,
                    label = "Settings",
                )
            }
        }

        if (uiState.favoriteAlbums.isNotEmpty()) {
            item {
                SectionHeader(eyebrow = "Favorites", title = "Pinned to your identity")
            }

            item {
                FavoriteGrid(albums = uiState.favoriteAlbums)
            }
        }

        item {
            SectionHeader(eyebrow = "Taste DNA", title = "Genres on repeat")
        }

        item {
            TasteTags(tags = profile.genres)
        }

        if (uiState.latestRecap != null) {
            item {
                SectionHeader(eyebrow = "Weekly recap", title = "Your week in music")
            }

            item {
                RecapCard(
                    totalLogs = uiState.latestRecap!!.totalLogs,
                    avgRating = uiState.latestRecap!!.averageRating,
                    shareText = uiState.latestRecap!!.shareText,
                )
            }
        }

        item {
            SectionHeader(eyebrow = "Activity", title = "Recent ratings")
        }

        items(uiState.recentActivity) { item ->
            GlassCard(
                cornerRadius = 16.dp,
                borderColor = FeedItemBorder,
                contentPadding = PaddingValues(10.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    AlbumArtwork(
                        artworkUrl = item.album.artworkUrl,
                        colors = item.album.artColors,
                        modifier = Modifier.size(44.dp),
                        cornerRadius = 12.dp,
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = item.album.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            text = item.action,
                            style = MaterialTheme.typography.bodySmall,
                            color = TextSecondary,
                        )
                    }
                    Text(
                        text = item.timeAgo,
                        style = MaterialTheme.typography.labelSmall,
                        color = TextTertiary,
                    )
                }
            }
        }

        if (uiState.recentActivity.isEmpty()) {
            item {
                EmptyState(
                    title = "Recent activity",
                    subtitle = "Your latest ratings and reviews will appear here.",
                    icon = Icons.Outlined.History,
                )
            }
        }
    }
}

@Composable
private fun ProfileHeader(profile: UserProfile) {
    GlassCard(
        cornerRadius = 26.dp,
        borderColor = FeedItemBorder,
        frosted = true,
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            AvatarCircle(
                initials = profile.handle.removePrefix("@").take(2),
                gradientColors = listOf(AccentGreen, AccentViolet),
                size = 80.dp,
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = profile.handle,
                style = MaterialTheme.typography.headlineMedium,
                color = ChromeLight,
                fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = profile.bio,
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(12.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                ProfileCount(value = "${profile.followingCount}", label = "Following")
                ProfileCount(value = "${profile.followersCount}", label = "Followers")
            }
        }
    }
}

@Composable
private fun ProfileCount(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            color = ChromeLight,
            fontWeight = FontWeight.Bold,
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = TextTertiary,
        )
    }
}

@Composable
private fun FavoriteGrid(albums: List<Album>) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        albums.chunked(3).forEach { rowAlbums ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                rowAlbums.forEach { album ->
                    GlassCard(
                        modifier = Modifier.weight(1f),
                        fillMaxWidth = true,
                        cornerRadius = 18.dp,
                        borderColor = FeedItemBorder,
                        contentPadding = PaddingValues(6.dp),
                        onClick = { },
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            AlbumArtwork(
                                artworkUrl = album.artworkUrl,
                                colors = album.artColors,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(100.dp),
                                cornerRadius = 14.dp,
                            )
                            Text(
                                text = album.title,
                                style = MaterialTheme.typography.titleSmall,
                                maxLines = 1,
                                fontWeight = FontWeight.Medium,
                            )
                        }
                    }
                }
                repeat(3 - rowAlbums.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun TasteTags(tags: List<String>) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(tags.size) { index ->
            val tag = tags[index]
            val tagColors = when (index % 4) {
                0 -> AlbumColors.orchid
                1 -> AlbumColors.lagoon
                2 -> AlbumColors.ember
                else -> AlbumColors.rose
            }
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(
                        Brush.linearGradient(
                            listOf(tagColors.first().copy(alpha = 0.4f), tagColors.last().copy(alpha = 0.15f))
                        )
                    )
                    .border(0.5.dp, tagColors.last().copy(alpha = 0.3f), RoundedCornerShape(20.dp))
                    .padding(horizontal = 14.dp, vertical = 8.dp),
            ) {
                Text(
                    text = tag,
                    style = MaterialTheme.typography.labelMedium,
                    color = ChromeLight,
                    fontWeight = FontWeight.Medium,
                )
            }
        }
    }
}

@Composable
private fun RecapCard(
    totalLogs: Int,
    avgRating: Float,
    shareText: String,
) {
    GlassCard(
        cornerRadius = 22.dp,
        tintColor = AccentGreen,
        borderColor = AccentGreen.copy(alpha = 0.2f),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Column {
                    Text(
                        text = "$totalLogs",
                        style = MaterialTheme.typography.headlineMedium,
                        color = AccentGreen,
                        fontWeight = FontWeight.Black,
                    )
                    Text(
                        text = "ALBUMS LOGGED",
                        style = MaterialTheme.typography.labelSmall,
                        color = TextTertiary,
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = String.format("%.1f", avgRating),
                        style = MaterialTheme.typography.headlineMedium,
                        color = AccentAmber,
                        fontWeight = FontWeight.Black,
                    )
                    Text(
                        text = "AVG RATING",
                        style = MaterialTheme.typography.labelSmall,
                        color = TextTertiary,
                    )
                }
            }
            Text(
                text = shareText,
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                BlueButton(text = "View Recap", onClick = { })
                GlassIconButton(
                    icon = Icons.Outlined.Share,
                    label = "Share",
                    tint = AccentGreen,
                )
            }
        }
    }
}
