package com.soundscore.app.ui.theme

import androidx.compose.ui.graphics.Color

// ── Dark Base ──
val DarkBase = Color(0xFF040506)
val DarkSurface = Color(0xFF0A0D0F)
val DarkElevated = Color(0xFF111618)

// ── Liquid Glass ──
val GlassBg = Color(0x12FFFFFF)
val GlassBorder = Color(0x24FFFFFF)
val GlassHeavy = Color(0x1CFFFFFF)
val GlassHighlight = Color(0x30FFFFFF)
val GlassUltraLight = Color(0x0AFFFFFF)
val GlassSheet = Color(0x1AFFFFFF)
val GlassFrosted = Color(0x28FFFFFF)
val FeedItemBorder = Color(0x14FFFFFF)

// ── Semantic Surfaces ──
val SurfaceCard = Color(0x0EFFFFFF)
val SurfaceModal = Color(0x1EFFFFFF)
val SurfaceOverlay = Color(0xCC000000)

// ── Chrome ──
val ChromeLight = Color(0xF0FFFFFF)
val ChromeMedium = Color(0xB3FFFFFF)
val ChromeDim = Color(0x70FFFFFF)
val ChromeFaint = Color(0x3DFFFFFF)

// ── Primary Accent (Green) ──
val AccentGreen = Color(0xFF1ED760)
val AccentGreenStrong = Color(0xFF19B24F)
val AccentGreenGlow = Color(0x661ED760)
val AccentGreenDim = Color(0x201ED760)
val AccentGreenMuted = Color(0x101ED760)

// ── Secondary Accents ──
val AccentAmber = Color(0xFFFFA726)
val AccentAmberDim = Color(0x20FFA726)
val AccentCoral = Color(0xFFFF6B6B)
val AccentCoralDim = Color(0x20FF6B6B)
val AccentViolet = Color(0xFFB388FF)
val AccentVioletDim = Color(0x20B388FF)

// Back-compat aliases
val ElectricBlue = AccentGreen
val ElectricBlueGlow = AccentGreenGlow
val ElectricBlueDim = AccentGreenDim

// ── Text ──
val TextPrimary = Color(0xF2FFFFFF)
val TextSecondary = Color(0xB8FFFFFF)
val TextTertiary = Color(0x6EFFFFFF)

// ── Semantic ──
val Destructive = Color(0xFFFF4D4D)
val Success = Color(0xFF38EF7D)

// ── Album art placeholder gradients (start, end) ──
object AlbumColors {
    val forest = listOf(Color(0xFF09130E), Color(0xFF1E7A4E))
    val lime = listOf(Color(0xFF102915), Color(0xFF1ED760))
    val ember = listOf(Color(0xFF2B110C), Color(0xFFCC6A2C))
    val orchid = listOf(Color(0xFF1B102C), Color(0xFF7550D8))
    val lagoon = listOf(Color(0xFF061B26), Color(0xFF2FC0B8))
    val rose = listOf(Color(0xFF2A0E1A), Color(0xFFC4548B))
    val midnight = listOf(Color(0xFF09111A), Color(0xFF2D4A67))
    val slate = listOf(Color(0xFF0E1114), Color(0xFF4A5568))
    val coral = listOf(Color(0xFF1A0A0A), Color(0xFFFF6B6B))
    val amber = listOf(Color(0xFF1A1208), Color(0xFFFFA726))

    val purple = orchid
    val teal = lagoon
    val pink = rose
    val blue = midnight
    val gold = ember
    val indigo = forest
}
