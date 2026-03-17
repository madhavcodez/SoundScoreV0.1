package com.soundscore.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.soundscore.app.data.model.Album
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AccentGreenDim
import com.soundscore.app.ui.theme.ChromeLight
import com.soundscore.app.ui.theme.FeedItemBorder
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.TextSecondary
import com.soundscore.app.ui.theme.TextTertiary
import com.soundscore.app.ui.viewmodel.ChartEntry

@Composable
fun ScreenHeader(
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onActionClick: (() -> Unit)? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.displaySmall,
                color = ChromeLight,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary,
            )
        }

        if (actionLabel != null) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(20.dp))
                    .background(AccentGreenDim)
                    .border(0.5.dp, AccentGreen.copy(alpha = 0.28f), RoundedCornerShape(20.dp))
                    .then(if (onActionClick != null) Modifier.clickable(onClick = onActionClick) else Modifier)
                    .padding(horizontal = 14.dp, vertical = 8.dp),
            ) {
                Text(
                    text = actionLabel,
                    style = MaterialTheme.typography.labelMedium,
                    color = AccentGreen,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

@Composable
fun SectionHeader(
    eyebrow: String,
    title: String,
    modifier: Modifier = Modifier,
    trailing: String? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Bottom,
    ) {
        Column {
            Text(
                text = eyebrow.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = TextTertiary,
                fontWeight = FontWeight.Bold,
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
                color = ChromeLight,
            )
        }
        if (trailing != null) {
            Text(
                text = trailing,
                style = MaterialTheme.typography.labelMedium,
                color = AccentGreen,
            )
        }
    }
}

@Composable
fun StatPill(
    value: String,
    label: String,
    modifier: Modifier = Modifier,
    highlight: Boolean = false,
    accentColor: androidx.compose.ui.graphics.Color = AccentGreen,
) {
    val backgroundColor = if (highlight) accentColor.copy(alpha = 0.10f) else GlassBg
    val borderColor = if (highlight) accentColor.copy(alpha = 0.24f) else FeedItemBorder

    Column(
        modifier = modifier
            .clip(RoundedCornerShape(18.dp))
            .background(backgroundColor)
            .border(0.5.dp, borderColor, RoundedCornerShape(18.dp))
            .padding(horizontal = 14.dp, vertical = 12.dp),
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            color = if (highlight) accentColor else ChromeLight,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(2.dp))
        Text(
            text = label.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = if (highlight) accentColor.copy(alpha = 0.8f) else TextTertiary,
        )
    }
}

@Composable
fun ActionChip(
    text: String,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    active: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (active) AccentGreenDim else GlassBg)
            .border(
                0.5.dp,
                if (active) AccentGreen.copy(alpha = 0.24f) else GlassBorder,
                RoundedCornerShape(20.dp),
            )
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (active) AccentGreen else TextSecondary,
            modifier = Modifier.size(14.dp),
        )
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium,
            color = if (active) AccentGreen else TextSecondary,
        )
    }
}

@Composable
fun MosaicCover(
    albums: List<Album>,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 18.dp,
) {
    val coverSlots = albums.take(4).map { it as Album? } + List((4 - albums.take(4).size).coerceAtLeast(0)) { null }

    GlassCard(
        modifier = modifier,
        fillMaxWidth = false,
        cornerRadius = cornerRadius,
        contentPadding = PaddingValues(5.dp),
        borderColor = FeedItemBorder,
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            coverSlots.chunked(2).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    row.forEach { album ->
                        if (album != null) {
                            AlbumArtwork(
                                artworkUrl = album.artworkUrl,
                                colors = album.artColors,
                                modifier = Modifier.size(52.dp),
                                cornerRadius = 10.dp,
                            )
                        } else {
                            Box(
                                modifier = Modifier
                                    .size(52.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(GlassBg),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TrendChartRow(
    entry: ChartEntry,
    modifier: Modifier = Modifier,
) {
    GlassCard(
        modifier = modifier,
        cornerRadius = 20.dp,
        borderColor = FeedItemBorder,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(AccentGreenDim),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = entry.rank.toString(),
                    style = MaterialTheme.typography.labelLarge,
                    color = AccentGreen,
                    fontWeight = FontWeight.Bold,
                )
            }

            AlbumArtwork(
                artworkUrl = entry.album.artworkUrl,
                colors = entry.album.artColors,
                modifier = Modifier.size(48.dp),
                cornerRadius = 14.dp,
            )

            Column(modifier = Modifier.weight(1f)) {
                Text(entry.album.title, style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.height(2.dp))
                Text(
                    text = "${entry.album.artist} · ${entry.album.logCount} logs",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                )
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Outlined.TrendingUp,
                    contentDescription = null,
                    tint = AccentGreen,
                    modifier = Modifier.size(14.dp),
                )
                Text(
                    text = entry.movementLabel,
                    style = MaterialTheme.typography.labelMedium,
                    color = AccentGreen,
                )
            }
        }
    }
}
