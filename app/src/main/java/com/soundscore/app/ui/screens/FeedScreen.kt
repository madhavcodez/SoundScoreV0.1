package com.soundscore.app.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.soundscore.app.data.model.FeedItem
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.ui.components.AlbumArtPlaceholder
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.components.StarRating
import com.soundscore.app.ui.theme.*
import kotlinx.coroutines.delay

@Composable
fun FeedScreen(modifier: Modifier = Modifier) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 16.dp),
    ) {
        // ── Page title ──
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Feed", style = MaterialTheme.typography.headlineMedium)
                // Avatar circle matching mockup
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(CircleShape)
                        .background(
                            androidx.compose.ui.graphics.Brush.linearGradient(
                                listOf(ElectricBlue, AlbumColors.purple.last())
                            )
                        )
                        .border(1.5.dp, ElectricBlue.copy(alpha = 0.4f), CircleShape),
                )
            }
        }

        // ── Friends strip ──
        item {
            val names = listOf("you", "rohan", "priya", "kai", "ananya")
            val colors = listOf(
                listOf(ElectricBlue, AlbumColors.purple.last()),
                AlbumColors.teal,
                AlbumColors.pink,
                AlbumColors.blue,
                AlbumColors.gold,
            )
            LazyRow(
                contentPadding = PaddingValues(horizontal = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.padding(bottom = 12.dp),
            ) {
                items(names.size) { i ->
                    val isMe = i == 0
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .background(
                                    androidx.compose.ui.graphics.Brush.linearGradient(colors[i])
                                )
                                .border(
                                    width = if (isMe) 1.5.dp else 1.dp,
                                    color = if (isMe) ElectricBlue else ChromeFaint.copy(alpha = 0.12f),
                                    shape = CircleShape,
                                ),
                        )
                        Spacer(Modifier.height(3.dp))
                        Text(
                            names[i],
                            style = MaterialTheme.typography.labelSmall,
                            color = TextTertiary,
                        )
                    }
                }
            }
        }

        // ── Feed items ──
        itemsIndexed(SeedData.feedItems, key = { _, item -> item.id }) { index, item ->
            // Staggered list entrance
            var visible by remember { mutableStateOf(false) }
            LaunchedEffect(Unit) {
                delay(index * 80L)
                visible = true
            }
            
            AnimatedVisibility(
                visible = visible,
                enter = fadeIn(animationSpec = tween(400)) + 
                        slideInVertically(initialOffsetY = { 40 }, animationSpec = tween(400)),
            ) {
                FeedCard(item)
            }
        }
    }
}

@Composable
private fun FeedCard(item: FeedItem) {
    // Pulsing glow on liked heart
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.6f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )

    GlassCard(
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
        tintColor = item.album.artColors.firstOrNull(),
        cornerRadius = 16.dp,
        borderColor = FeedItemBorder,
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            AlbumArtPlaceholder(
                colors = item.album.artColors,
                modifier = Modifier.size(48.dp),
                cornerRadius = 9.dp,
            )
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                // @username highlighted + action text
                Text(
                    buildAnnotatedString {
                        withStyle(SpanStyle(color = TextPrimary, fontWeight = FontWeight.SemiBold)) {
                            append("@${item.username}")
                        }
                        withStyle(SpanStyle(color = ChromeDim)) {
                            append(" ${item.action}")
                        }
                    },
                    style = MaterialTheme.typography.bodySmall,
                )
                Text(item.album.title, style = MaterialTheme.typography.titleSmall)
                Text(
                    "${item.album.artist} · ${item.album.year}",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
                Spacer(Modifier.height(3.dp))
                StarRating(rating = item.rating, starSize = 12.dp)

                if (!item.reviewSnippet.isNullOrBlank()) {
                    Spacer(Modifier.height(3.dp))
                    Text(
                        "\"${item.reviewSnippet}\"",
                        style = MaterialTheme.typography.bodySmall,
                        fontStyle = FontStyle.Italic,
                        color = ChromeDim,
                    )
                }

                Spacer(Modifier.height(5.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        "♥ ${item.likes}",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (item.isLiked) ElectricBlue else TextTertiary,
                        modifier = Modifier.graphicsLayer {
                            alpha = if (item.isLiked) pulseAlpha else 1f
                        }
                    )
                    Text("💬 ${item.comments}", style = MaterialTheme.typography.labelSmall, color = TextTertiary)
                    Text("+ Log", style = MaterialTheme.typography.labelSmall, color = TextTertiary)
                }
            }
            Text(item.timeAgo, style = MaterialTheme.typography.labelSmall, color = TextTertiary)
        }
    }
}
