package com.soundscore.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val SoundScoreColorScheme = darkColorScheme(
    primary = AccentGreen,
    onPrimary = DarkBase,
    primaryContainer = AccentGreenDim,
    onPrimaryContainer = AccentGreen,
    secondary = AccentAmber,
    onSecondary = DarkBase,
    secondaryContainer = AccentAmberDim,
    onSecondaryContainer = AccentAmber,
    tertiary = AccentCoral,
    onTertiary = DarkBase,
    tertiaryContainer = AccentCoralDim,
    onTertiaryContainer = AccentCoral,
    background = DarkBase,
    onBackground = TextPrimary,
    surface = DarkSurface,
    onSurface = TextPrimary,
    surfaceVariant = DarkElevated,
    onSurfaceVariant = TextSecondary,
    outline = GlassBorder,
    outlineVariant = ChromeFaint,
    error = Destructive,
    onError = DarkBase,
)

@Composable
fun SoundScoreTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            @Suppress("DEPRECATION")
            window.statusBarColor = Color.Transparent.toArgb()
            @Suppress("DEPRECATION")
            window.navigationBarColor = Color.Transparent.toArgb()
            WindowCompat.setDecorFitsSystemWindows(window, false)
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
