package com.soundscore.app.ui.theme

import androidx.compose.ui.graphics.Color

// ── Dark Base ──
val DarkBase = Color(0xFF0A0A0A)        // near-black, slightly warm
val DarkSurface = Color(0xFF111111)      // cards sit on this
val DarkElevated = Color(0xFF1A1A1A)     // modals, sheets

// ── Liquid Glass ──
val GlassBg = Color(0x0DFFFFFF)          // rgba(255,255,255,0.05)
val GlassBorder = Color(0x17FFFFFF)      // rgba(255,255,255,0.09)
val GlassHeavy = Color(0x14FFFFFF)       // rgba(255,255,255,0.08) — pressed state
val FeedItemBorder = Color(0x12FFFFFF)   // rgba(255,255,255,0.07) — feed cards

// ── Chrome ──
val ChromeLight = Color(0xE6FFFFFF)      // rgba(255,255,255,0.90) — headlines
val ChromeMedium = Color(0x99FFFFFF)     // rgba(255,255,255,0.60) — icons, dividers
val ChromeDim = Color(0x66FFFFFF)        // rgba(255,255,255,0.40) — secondary text
val ChromeFaint = Color(0x33FFFFFF)      // rgba(255,255,255,0.20) — disabled

// ── Electric Blue ──
val ElectricBlue = Color(0xFF4D9FFF)     // primary accent
val ElectricBlueGlow = Color(0x4D4D9FFF) // 0.3 opacity — glow behind CTAs
val ElectricBlueDim = Color(0x1F4D9FFF)  // 0.12 opacity — tag backgrounds

// ── Text ──
val TextPrimary = Color(0xE6FFFFFF)      // white @ 90% — body text
val TextSecondary = Color(0x59FFFFFF)    // white @ 35% — captions
val TextTertiary = Color(0x33FFFFFF)     // white @ 20% — timestamps

// ── Semantic ──
val Destructive = Color(0xFFFF4D4D)
val Success = Color(0xFF38EF7D)

// ── Album art placeholder gradients (start, end) ──
object AlbumColors {
    val purple = listOf(Color(0xFF1A0533), Color(0xFF533483))
    val teal   = listOf(Color(0xFF0D3B34), Color(0xFF38EF7D))
    val pink   = listOf(Color(0xFF4A0028), Color(0xFFB91D73))
    val blue   = listOf(Color(0xFF0A1628), Color(0xFF8E54E9))
    val gold   = listOf(Color(0xFF2A1500), Color(0xFFFFD200))
    val indigo = listOf(Color(0xFF0D0D2B), Color(0xFF24243E))
}
