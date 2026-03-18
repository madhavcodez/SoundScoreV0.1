import SwiftUI

enum AccentTheme: String, CaseIterable, Identifiable {
    case mint, sunset, coral, lavender, ocean, gold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mint: return "Mint"
        case .sunset: return "Sunset"
        case .coral: return "Coral"
        case .lavender: return "Lavender"
        case .ocean: return "Ocean"
        case .gold: return "Gold"
        }
    }

    var primary: Color {
        switch self {
        case .mint:     return Color(hex: 0x1ED760)
        case .sunset:   return Color(hex: 0xFF8C42)
        case .coral:    return Color(hex: 0xFF6B6B)
        case .lavender: return Color(hex: 0xB388FF)
        case .ocean:    return Color(hex: 0x4FC3F7)
        case .gold:     return Color(hex: 0xFFD54F)
        }
    }

    var primaryDim: Color { primary.opacity(0.12) }

    var secondary: Color {
        switch self {
        case .mint:     return Color(hex: 0xFFA726)
        case .sunset:   return Color(hex: 0xFF6B6B)
        case .coral:    return Color(hex: 0xFFA726)
        case .lavender: return Color(hex: 0x4FC3F7)
        case .ocean:    return Color(hex: 0xB388FF)
        case .gold:     return Color(hex: 0xFF8C42)
        }
    }

    var secondaryDim: Color { secondary.opacity(0.12) }

    var backdropGlow: Color { primary.opacity(0.10) }
    var backdropSecondaryGlow: Color { secondary.opacity(0.05) }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: AccentTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "ss_accentTheme") }
    }

    var primary: Color { current.primary }
    var primaryDim: Color { current.primaryDim }
    var secondary: Color { current.secondary }
    var secondaryDim: Color { current.secondaryDim }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "ss_accentTheme") ?? "mint"
        self.current = AccentTheme(rawValue: saved) ?? .mint
    }
}
