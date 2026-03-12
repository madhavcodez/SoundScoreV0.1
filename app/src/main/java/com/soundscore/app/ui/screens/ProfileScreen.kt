package com.soundscore.app.ui.screens

import android.content.Intent
import android.widget.Toast
import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.soundscore.app.data.model.NotificationPreferences
import com.soundscore.app.ui.components.AlbumArtPlaceholder
import com.soundscore.app.ui.components.BlueButton
import com.soundscore.app.ui.components.GhostButton
import com.soundscore.app.ui.components.GlassCard
import com.soundscore.app.ui.theme.AlbumColors
import com.soundscore.app.ui.theme.ChromeDim
import com.soundscore.app.ui.theme.ChromeFaint
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.DarkBase
import com.soundscore.app.ui.theme.ElectricBlue
import com.soundscore.app.ui.theme.ElectricBlueDim
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.ProfileViewModel

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    profileViewModel: ProfileViewModel = viewModel(),
) {
    val uiState by profileViewModel.uiState.collectAsStateWithLifecycle()
    val profile = uiState.profile

    if (profile == null) {
        Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Loading profile…", color = TextSecondary)
        }
        return
    }

    val context = LocalContext.current
    val clipboard = LocalClipboardManager.current

    var startAnimation by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        startAnimation = true
    }

    val logCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.logCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "logCount",
    )
    val reviewCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.reviewCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "reviewCount",
    )
    val listCountAnimate by animateIntAsState(
        targetValue = if (startAnimation) profile.listCount else 0,
        animationSpec = tween(durationMillis = 800),
        label = "listCount",
    )

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
    ) {
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

        item {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(listOf(ElectricBlue, AlbumColors.purple.last())),
                        )
                        .border(2.dp, ElectricBlue.copy(alpha = 0.4f), CircleShape),
                )
                Spacer(Modifier.size(14.dp))
                Column {
                    Text(profile.handle, style = MaterialTheme.typography.titleLarge)
                    Text(profile.bio, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    Spacer(Modifier.size(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                        StatChip("$logCountAnimate", "Logs")
                        StatChip("$reviewCountAnimate", "Reviews")
                        StatChip("$listCountAnimate", "Lists")
                    }
                }
            }
        }

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
                            .clip(RoundedCornerShape(9.dp))
                            .border(1.dp, GlassBorder, RoundedCornerShape(9.dp)),
                    ) {
                        AlbumArtPlaceholder(
                            colors = album.artColors,
                            cornerRadius = 9.dp,
                            modifier = Modifier.fillMaxSize(),
                        )
                        Box(
                            modifier = Modifier
                                .align(Alignment.BottomStart)
                                .fillMaxWidth()
                                .background(
                                    Brush.verticalGradient(
                                        listOf(
                                            DarkBase.copy(alpha = 0f),
                                            DarkBase.copy(alpha = 0.75f),
                                        ),
                                    ),
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
                    val isHighlighted = genre in highlighted
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(20.dp))
                            .background(if (isHighlighted) ElectricBlueDim else GlassBg)
                            .border(
                                1.dp,
                                if (isHighlighted) ElectricBlue.copy(alpha = 0.3f) else GlassBorder,
                                RoundedCornerShape(20.dp),
                            )
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                    ) {
                        Text(
                            genre,
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isHighlighted) ElectricBlue else ChromeDim,
                        )
                    }
                }
            }
        }

        item {
            Spacer(Modifier.height(16.dp))
            Text(
                "NOTIFICATIONS",
                style = MaterialTheme.typography.labelMedium,
                color = TextTertiary,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
            )
            NotificationPreferencesCard(
                preferences = uiState.notificationPreferences,
                onPreferencesChange = profileViewModel::updateNotificationPreferences,
            )
        }

        item {
            Spacer(Modifier.height(12.dp))
            Text(
                "WEEKLY RECAP",
                style = MaterialTheme.typography.labelMedium,
                color = TextTertiary,
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp),
            )
            RecapCard(
                summary = uiState.latestRecap?.shareText ?: "No recap yet",
                onGenerate = profileViewModel::generateRecap,
            )
        }

        item {
            Spacer(Modifier.height(16.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                BlueButton(
                    "Share profile card",
                    onClick = {
                        val text = profileViewModel.buildShareText()
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        context.startActivity(Intent.createChooser(intent, "Share profile"))
                    },
                    modifier = Modifier.weight(1.2f),
                )
                GhostButton(
                    "Export data",
                    onClick = {
                        profileViewModel.exportDataSnapshot { snapshot ->
                            clipboard.setText(AnnotatedString(snapshot))
                            Toast.makeText(context, "Export snapshot copied", Toast.LENGTH_SHORT).show()
                        }
                    },
                    modifier = Modifier.weight(1f),
                )
            }
        }

        if (!uiState.syncMessage.isNullOrBlank()) {
            item {
                Spacer(Modifier.height(10.dp))
                Text(
                    text = uiState.syncMessage ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                    modifier = Modifier.padding(horizontal = 14.dp),
                )
            }
        }
    }
}

@Composable
private fun NotificationPreferencesCard(
    preferences: NotificationPreferences,
    onPreferencesChange: (NotificationPreferences) -> Unit,
) {
    GlassCard(cornerRadius = 14.dp, modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)) {
        PreferenceRow(
            label = "Social activity",
            enabled = preferences.socialEnabled,
            onToggle = { onPreferencesChange(preferences.copy(socialEnabled = it)) },
        )
        PreferenceRow(
            label = "Recap ready",
            enabled = preferences.recapEnabled,
            onToggle = { onPreferencesChange(preferences.copy(recapEnabled = it)) },
        )
        PreferenceRow(
            label = "Comments",
            enabled = preferences.commentEnabled,
            onToggle = { onPreferencesChange(preferences.copy(commentEnabled = it)) },
        )
        PreferenceRow(
            label = "Reactions",
            enabled = preferences.reactionEnabled,
            onToggle = { onPreferencesChange(preferences.copy(reactionEnabled = it)) },
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "Quiet hours: ${preferences.quietHoursStart}:00–${preferences.quietHoursEnd}:00",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary,
                modifier = Modifier.weight(1f),
            )
            TextButton(onClick = {
                val nextStart = if (preferences.quietHoursStart == 0) 23 else preferences.quietHoursStart - 1
                onPreferencesChange(preferences.copy(quietHoursStart = nextStart))
            }) {
                Text("-1h")
            }
            TextButton(onClick = {
                val nextStart = (preferences.quietHoursStart + 1) % 24
                onPreferencesChange(preferences.copy(quietHoursStart = nextStart))
            }) {
                Text("+1h")
            }
        }
    }
}

@Composable
private fun PreferenceRow(
    label: String,
    enabled: Boolean,
    onToggle: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = ChromeLight,
            modifier = Modifier.weight(1f),
        )
        Switch(checked = enabled, onCheckedChange = onToggle)
    }
}

@Composable
private fun RecapCard(
    summary: String,
    onGenerate: () -> Unit,
) {
    GlassCard(cornerRadius = 14.dp, modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)) {
        Text(summary, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        Spacer(Modifier.height(8.dp))
        BlueButton(text = "Generate latest recap", onClick = onGenerate)
    }
}

@Composable
private fun StatChip(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, style = MaterialTheme.typography.titleMedium, color = ChromeLight)
        Text(label.uppercase(), style = MaterialTheme.typography.labelSmall, color = TextTertiary)
    }
}
