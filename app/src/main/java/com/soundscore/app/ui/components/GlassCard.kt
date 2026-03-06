package com.soundscore.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.soundscore.app.ui.theme.GlassBg
import com.soundscore.app.ui.theme.GlassBorder

/**
 * Liquid glass card with Apple-like dynamic movement and haptic-style scaling.
 *
 * @param tintColor    Optional color that "bleeds" through the glass.
 * @param cornerRadius Corner rounding. Default 16dp.
 * @param borderColor  Border color. Default GlassBorder (9% white).
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    tintColor: Color? = null,
    cornerRadius: Dp = 16.dp,
    borderColor: Color = GlassBorder,
    onClick: (() -> Unit)? = null,
    content: @Composable BoxScope.() -> Unit,
) {
    var isPressed by remember { mutableStateOf(false) }
    
    // Smooth spring animation for the "liquid" scale effect
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.96f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 400f),
        label = "scale"
    )

    val shape = RoundedCornerShape(cornerRadius)

    val bgModifier = if (tintColor != null) {
        Modifier.background(
            brush = Brush.linearGradient(
                colors = listOf(
                    tintColor.copy(alpha = 0.18f),
                    GlassBg.copy(alpha = 0.4f),
                    tintColor.copy(alpha = 0.05f),
                )
            ),
            shape = shape,
        )
    } else {
        Modifier.background(
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color.White.copy(alpha = 0.08f),
                    GlassBg,
                )
            ),
            shape = shape
        )
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                this.scaleX = scale
                this.scaleY = scale
            }
            .clip(shape)
            .then(bgModifier)
            .border(
                width = 0.5.dp, 
                brush = Brush.verticalGradient(
                    listOf(Color.White.copy(alpha = 0.15f), borderColor)
                ), 
                shape = shape
            )
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    },
                    onTap = { onClick?.invoke() }
                )
            }
            .padding(12.dp),
        content = content,
    )
}
