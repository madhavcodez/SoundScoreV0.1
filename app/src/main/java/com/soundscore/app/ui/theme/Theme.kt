package com.soundscore.app.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val SoundScoreColorScheme = darkColorScheme(
    // Primary = Electric Blue
    primary = ElectricBlue,
    onPrimary = DarkBase,
    primaryContainer = ElectricBlueDim,
    onPrimaryContainer = ElectricBlue,

    // Surface = Dark layers
    background = DarkBase,
    onBackground = TextPrimary,
    surface = DarkSurface,
    onSurface = TextPrimary,
    surfaceVariant = DarkElevated,
    onSurfaceVariant = TextSecondary,

    // Outlines
    outline = GlassBorder,
    outlineVariant = ChromeFaint,

    // Error
    error = Destructive,
    onError = DarkBase,
)

@Composable
fun SoundScoreTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = DarkBase.toArgb()
            window.navigationBarColor = DarkBase.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = false
                isAppearanceLightNavigationBars = false
            }
        }
    }

    MaterialTheme(
        colorScheme = SoundScoreColorScheme,
        typography = SoundScoreTypography,
        content = content,
    )
}
