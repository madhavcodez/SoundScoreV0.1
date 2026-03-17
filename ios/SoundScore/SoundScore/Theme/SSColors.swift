import SwiftUI

enum SSColors {
    static let darkBase = Color(hex: 0x040506)
    static let darkSurface = Color(hex: 0x0A0D0F)
    static let darkElevated = Color(hex: 0x111618)

    static let glassBg = Color.white.opacity(0.07)
    static let glassBorder = Color.white.opacity(0.14)
    static let glassFrosted = Color.white.opacity(0.16)
    static let glassSheet = Color.white.opacity(0.10)

    static let chromeLight = Color.white.opacity(0.94)
    static let chromeMedium = Color.white.opacity(0.70)
    static let chromeDim = Color.white.opacity(0.44)
    static let chromeFaint = Color.white.opacity(0.24)

    static let accentGreen = Color(hex: 0x1ED760)
    static let accentAmber = Color(hex: 0xFFA726)
    static let accentCoral = Color(hex: 0xFF6B6B)
    static let accentViolet = Color(hex: 0xB388FF)

    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.43)

    static let accentGreenDim = Color(hex: 0x1ED760, alpha: 0.12)
    static let accentAmberDim = Color(hex: 0xFFA726, alpha: 0.12)
    static let accentCoralDim = Color(hex: 0xFF6B6B, alpha: 0.12)
    static let accentVioletDim = Color(hex: 0xB388FF, alpha: 0.12)

    static let feedItemBorder = Color.white.opacity(0.08)
    static let glassHighlight = Color.white.opacity(0.19)
}

enum AlbumColors {
    static let forest: [Color] = [Color(hex: 0x2D6A4F), Color(hex: 0x95D5B2)]
    static let lime: [Color] = [Color(hex: 0x4C956C), Color(hex: 0xD8F3DC)]
    static let ember: [Color] = [Color(hex: 0xE76F51), Color(hex: 0xF4A261)]
    static let orchid: [Color] = [Color(hex: 0x7B2CBF), Color(hex: 0xC77DFF)]
    static let lagoon: [Color] = [Color(hex: 0x0077B6), Color(hex: 0x90E0EF)]
    static let rose: [Color] = [Color(hex: 0xE63946), Color(hex: 0xFFB4A2)]
    static let midnight: [Color] = [Color(hex: 0x1D3557), Color(hex: 0x457B9D)]
    static let slate: [Color] = [Color(hex: 0x495057), Color(hex: 0xADB5BD)]
    static let coral: [Color] = [Color(hex: 0xFF6B6B), Color(hex: 0xFFC09F)]
    static let amber: [Color] = [Color(hex: 0xFFA726), Color(hex: 0xFFE082)]
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
