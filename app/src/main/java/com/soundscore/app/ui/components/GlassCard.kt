package com.soundscore.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder
import com.soundscore.app.ui.theme.GlassHighlight

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    tintColor: Color? = null,
    cornerRadius: Dp = 20.dp,
    borderColor: Color = GlassBorder,
    contentPadding: PaddingValues = PaddingValues(horizontal = 14.dp, vertical = 14.dp),
    fillMaxWidth: Boolean = true,
    frosted: Boolean = false,
    onClick: (() -> Unit)? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    var isPressed by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.97f else 1f,
        animationSpec = spring(dampingRatio = 0.65f, stiffness = 500f),
        label = "glassScale"
    )

    val shape = RoundedCornerShape(cornerRadius)

    val bgBrush = if (tintColor != null) {
        Brush.linearGradient(
            colors = listOf(
                tintColor.copy(alpha = 0.14f),
                GlassBg.copy(alpha = 0.60f),
                tintColor.copy(alpha = 0.04f),
            )
        )
    } else {
        Brush.verticalGradient(
            colors = listOf(
                GlassHighlight.copy(alpha = if (frosted) 0.28f else 0.20f),
                GlassBg,
            )
        )
    }

    val interactionModifier = if (onClick != null) {
        Modifier.pointerInput(onClick) {
            detectTapGestures(
                onPress = {
                    isPressed = true
                    tryAwaitRelease()
                    isPressed = false
                },
                onTap = { onClick() },
            )
        }
    } else {
        Modifier
    }

    Box(
        modifier = modifier
            .then(if (fillMaxWidth) Modifier.fillMaxWidth() else Modifier)
            .graphicsLayer {
                this.scaleX = scale
                this.scaleY = scale
            }
            .clip(shape)
            .background(brush = bgBrush, shape = shape)
            .border(
                width = 0.5.dp,
                brush = Brush.verticalGradient(
                    listOf(Color.White.copy(alpha = 0.14f), borderColor)
                ),
                shape = shape,
            )
            .then(interactionModifier)
            .padding(contentPadding),
        content = content,
    )
}
