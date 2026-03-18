package com.soundscore.app.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import coil.request.ImageRequest

@Composable
fun AlbumArtwork(
    artworkUrl: String?,
    colors: List<Color>,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 12.dp,
) {
    val infiniteTransition = rememberInfiniteTransition(label = "artShimmer")
    val shimmerShift by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(3200, easing = LinearEasing),
        ),
        label = "artShimmerShift",
    )
    val shape = if (cornerRadius == 0.dp) RectangleShape else RoundedCornerShape(cornerRadius)

    Box(
        modifier = modifier
            .clip(shape)
            .background(Brush.linearGradient(colors)),
    ) {
        if (!artworkUrl.isNullOrBlank()) {
            AsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(artworkUrl)
                    .crossfade(true)
                    .build(),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0f),
                            Color.White.copy(alpha = 0.08f),
                            Color.White.copy(alpha = 0f),
                        ),
                        start = androidx.compose.ui.geometry.Offset(shimmerShift, shimmerShift),
                        end = androidx.compose.ui.geometry.Offset(shimmerShift + 260f, shimmerShift + 260f),
                    )
                ),
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.Black.copy(alpha = 0.06f),
                            Color.Black.copy(alpha = 0.22f),
                        )
                    )
                ),
        )
    }
}

@Composable
fun AlbumArtPlaceholder(
    colors: List<Color>,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 12.dp,
) {
    AlbumArtwork(
        artworkUrl = null,
        colors = colors,
        modifier = modifier,
        cornerRadius = cornerRadius,
    )
}
