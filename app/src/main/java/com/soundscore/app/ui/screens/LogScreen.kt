package com.soundscore.app.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.soundscore.app.data.model.Album
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.ui.components.AlbumArtPlaceholder
import com.soundscore.app.ui.components.StarRating
import com.soundscore.app.ui.theme.*

@Composable
fun LogScreen(modifier: Modifier = Modifier) {
    val ratings = remember {
        mutableStateMapOf<String, Float>().apply { putAll(SeedData.logInitialRatings) }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
    ) {
        // ── Header ──
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Log", style = MaterialTheme.typography.headlineMedium)
            Text("+ Manual", style = MaterialTheme.typography.labelLarge, color = ElectricBlue)
        }

        // ── Recently played ──
        SectionLabel("Recently played")

        // 3-column grid via chunked rows
        SeedData.albums.chunked(3).forEach { rowAlbums ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp)
                    .padding(bottom = 7.dp),
                horizontalArrangement = Arrangement.spacedBy(7.dp),
            ) {
                rowAlbums.forEach { album ->
                    AlbumTile(
                        album = album,
                        rating = ratings[album.id] ?: 0f,
                        onRate = { ratings[album.id] = it },
                        modifier = Modifier.weight(1f),
                    )
                }
                // Fill remaining slots if row is not full
                repeat(3 - rowAlbums.size) {
                    Spacer(Modifier.weight(1f))
                }
            }
        }

        // ── Write later queue ──
        Spacer(Modifier.height(7.dp))
        SectionLabel("Write later queue")

        SeedData.albums.take(3).forEach { album ->
            QueueItem(album = album)
        }

        Spacer(Modifier.height(16.dp))
    }
}

@Composable
private fun AlbumTile(
    album: Album,
    rating: Float,
    onRate: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    var isPressed by remember { mutableStateOf(false) }
    
    // Album tile press ripple effect
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.94f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 400f),
        label = "albumTileScale"
    )

    val shape = RoundedCornerShape(11.dp)
    Box(
        modifier = modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clip(shape)
            .background(Color(0x0AFFFFFF))
            .border(1.dp, FeedItemBorder, shape)
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    }
                )
            },
    ) {
        Column {
            AlbumArtPlaceholder(
                colors = album.artColors,
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(1f),
                cornerRadius = 0.dp,
            )
            Column(modifier = Modifier.padding(horizontal = 6.dp, vertical = 5.dp)) {
                Text(
                    album.title,
                    style = MaterialTheme.typography.labelSmall,
                    color = ChromeMedium,
                    maxLines = 1,
                )
                Spacer(Modifier.height(3.dp))
                StarRating(
                    rating = rating,
                    starSize = 10.dp,
                    onRate = onRate,
                )
            }
        }
    }
}

@Composable
private fun QueueItem(album: Album) {
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 3.dp)
            .clip(shape)
            .background(Color(0x0AFFFFFF))
            .border(1.dp, FeedItemBorder, shape)
            .padding(horizontal = 11.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        AlbumArtPlaceholder(
            colors = album.artColors,
            modifier = Modifier.size(30.dp),
            cornerRadius = 6.dp,
        )
        Spacer(Modifier.width(9.dp))
        Text(
            album.title,
            style = MaterialTheme.typography.bodyMedium,
            color = ChromeMedium,
            modifier = Modifier.weight(1f),
            maxLines = 1,
        )
        Text(
            "Write →",
            style = MaterialTheme.typography.labelSmall,
            color = ElectricBlue,
        )
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        color = TextTertiary,
        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
