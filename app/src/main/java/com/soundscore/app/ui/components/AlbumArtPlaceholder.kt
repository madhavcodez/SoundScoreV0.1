package com.soundscore.app.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Gradient placeholder with a subtle "shimmer" and depth for the liquid glass look.
 */
@Composable
fun AlbumArtPlaceholder(
    colors: List<Color>,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 10.dp,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "shimmer")
    val shimmerShift by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmerShift"
    )

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius))
            .background(
                brush = Brush.linearGradient(
                    colors = colors,
                )
            )
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.0f),
                        Color.White.copy(alpha = 0.05f),
                        Color.White.copy(alpha = 0.0f),
                    ),
                    start = androidx.compose.ui.geometry.Offset(shimmerShift, shimmerShift),
                    end = androidx.compose.ui.geometry.Offset(shimmerShift + 200f, shimmerShift + 200f)
                )
            ),
    )
}
