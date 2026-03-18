package com.soundscore.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarHalf
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.soundscore.app.ui.theme.AccentAmber
import com.soundscore.app.ui.theme.ChromeFaint

@Composable
fun StarRating(
    rating: Float,
    modifier: Modifier = Modifier,
    onRate: ((Float) -> Unit)? = null,
    starSize: Dp = 22.dp,
    maxStars: Int = 5,
) {
    val haptic = LocalHapticFeedback.current

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(1.dp),
    ) {
        for (i in 1..maxStars) {
            val starValue = i.toFloat()
            val isFilled = rating >= starValue - 0.5f

            val icon = when {
                rating >= starValue -> Icons.Filled.Star
                rating >= starValue - 0.5f -> Icons.Filled.StarHalf
                else -> Icons.Outlined.StarOutline
            }
            val tint = if (isFilled) AccentAmber else ChromeFaint

            val scale by animateFloatAsState(
                targetValue = if (isFilled) 1f else 0.85f,
                animationSpec = spring(dampingRatio = 0.45f, stiffness = 600f),
                label = "starBounce"
            )

            Icon(
                imageVector = icon,
                contentDescription = "Star $i",
                tint = tint,
                modifier = Modifier
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                    }
                    .then(
                        if (onRate != null) {
                            Modifier.clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null
                            ) {
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                onRate(starValue)
                            }
                        } else Modifier
                    ),
            )
        }
    }
}
