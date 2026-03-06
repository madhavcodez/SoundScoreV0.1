package com.soundscore.app.ui.screens

import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import com.soundscore.app.data.model.SeedData
import com.soundscore.app.ui.components.AlbumArtPlaceholder
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.GhostButton
import com.soundscore.app.ui.theme.*

@Composable
fun ProfileScreen(modifier: Modifier = Modifier) {
    val profile = SeedData.myProfile
    
    // Profile stat counter
    var startAnimation by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        startAnimation = true
    }

    val logCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.logCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "logCount"
    )
    val reviewCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.reviewCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "reviewCount"
    )
    val listCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.listCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "listCount"
    )

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
    ) {
        // ── Header ──
        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 18.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Profile", style = MaterialTheme.typography.headlineMedium)
                Text("⚙", style = MaterialTheme.typography.titleLarge, color = ChromeFaint)
            }
        }

        // ── Avatar + stats ──
        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                verticalAlignment = Alignment.Top,
            ) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(listOf(ElectricBlue, AlbumColors.purple.last()))
                        )
                        .border(2.dp, ElectricBlue.copy(alpha = 0.4f), CircleShape),
                )
                Spacer(Modifier.width(14.dp))
                Column {
                    Text(profile.handle, style = MaterialTheme.typography.titleLarge)
                    Text(profile.bio, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    Spacer(Modifier.height(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                        StatChip("$logCountAnimate", "Logs")
                        StatChip("$reviewCountAnimate", "Reviews")
                        StatChip("$listCountAnimate", "Lists")
                    }
                }
            }
        }

        // ── Top albums ──
        item {
            Spacer(Modifier.height(16.dp))
            Text(
                "TOP ALBUMS",
                style = MaterialTheme.typography.labelMedium,
                color = TextTertiary,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
            )
        }
        item {
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                contentPadding = PaddingValues(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(5.dp),
                verticalArrangement = Arrangement.spacedBy(5.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                userScrollEnabled = false,
            ) {
                items(profile.topAlbums) { (album, rating) ->
                    Box(
                        modifier = Modifier
                            .aspectRatio(1f)
                            .clip(RoundedCornerShape(9.dp))
                            .border(1.dp, GlassBorder, RoundedCornerShape(9.dp)),
                    ) {
                        AlbumArtPlaceholder(
                            colors = album.artColors,
                            cornerRadius = 9.dp,
                            modifier = Modifier.fillMaxSize(),
                        )
                        // Score badge
                        Box(
                            modifier = Modifier
                                .align(Alignment.BottomStart)
                                .fillMaxWidth()
                                .background(
                                    Brush.verticalGradient(
                                        listOf(
                                            DarkBase.copy(alpha = 0f),
                                            DarkBase.copy(alpha = 0.75f),
                                        )
                                    )
                                )
                                .padding(4.dp),
                        ) {
                            Text(
                                "$rating",
                                style = MaterialTheme.typography.labelSmall,
                                color = ElectricBlue,
                            )
                        }
                    }
                }
            }
        }

        // ── Taste DNA ──
        item {
            Spacer(Modifier.height(14.dp))
            Text(
                "TASTE DNA",
                style = MaterialTheme.typography.labelMedium,
                color = TextTertiary,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
            )
        }
        @OptIn(ExperimentalLayoutApi::class)
        item {
            FlowRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                val highlighted = setOf("Indie", "Rap", "Avg 3.9 ★")
                profile.genres.forEach { genre ->
                    val isHl = genre in highlighted
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .background(if (isHl) ElectricBlueDim else GlassBg)
                            .border(
                                1.dp,
                                if (isHl) ElectricBlue.copy(alpha = 0.3f) else GlassBorder,
                                RoundedCornerShape(20.dp),
                            )
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                    ) {
                        Text(
                            genre,
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isHl) ElectricBlue else ChromeDim,
                        )
                    }
                }
            }
        }

        // ── CTAs ──
        item {
            Spacer(Modifier.height(16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                BlueButton("Share profile card", onClick = { /* TODO */ }, modifier = Modifier.weight(1.2f))
                GhostButton("Export data", onClick = { /* TODO */ }, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun StatChip(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleMedium, color = ChromeLight)
        Text(label.uppercase(), style = MaterialTheme.typography.labelSmall, color = TextTertiary)
    }
}
