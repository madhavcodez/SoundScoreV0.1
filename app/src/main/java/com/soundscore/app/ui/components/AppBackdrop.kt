package com.soundscore.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.soundscore.app.ui.theme.AccentGreen
import com.soundscore.app.ui.theme.AccentViolet
import com.soundscore.app.ui.theme.DarkBase
import com.soundscore.app.ui.theme.DarkElevated

@Composable
fun AppBackdrop(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(DarkElevated, DarkBase, DarkBase)
                )
            )
            .background(
                Brush.radialGradient(
                    colors = listOf(AccentGreen.copy(alpha = 0.12f), Color.Transparent),
                    center = Offset(120f, -80f),
                    radius = 800f,
                )
            )
            .background(
                Brush.radialGradient(
                    colors = listOf(AccentViolet.copy(alpha = 0.06f), Color.Transparent),
                    center = Offset(900f, 300f),
                    radius = 600f,
                )
            ),
    )
}
