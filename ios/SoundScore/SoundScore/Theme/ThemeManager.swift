import SwiftUI

struct ThemeColorScheme {
    let darkBase: Color
    let darkSurface: Color
    let darkElevated: Color
}

enum AccentTheme: String, CaseIterable, Identifiable {
    case emerald, bonfire, rose, amethyst, midnight, gilt

    var id: String { rawValue }

    var label: String {
        switch self {
        case .emerald:  return "Emerald"
        case .bonfire:  return "Bonfire"
        case .rose:     return "Rose"
        case .amethyst: return "Amethyst"
        case .midnight: return "Midnight"
        case .gilt:     return "Gilt"
        }
    }

    var primary: Color {
        switch self {
        case .emerald:  return Color(hex: 0x1ED760)
        case .bonfire:  return Color(hex: 0xFF8C42)
        case .rose:     return Color(hex: 0xFF6B8A)
        case .amethyst: return Color(hex: 0xB388FF)
        case .midnight: return Color(hex: 0x4FC3F7)
        case .gilt:     return Color(hex: 0xFFD54F)
        }
    }

    var primaryDim: Color { primary.opacity(0.12) }

    var secondary: Color {
        switch self {
        case .emerald:  return Color(hex: 0xFFA726)
        case .bonfire:  return Color(hex: 0xFF6B6B)
        case .rose:     return Color(hex: 0xFFA726)
        case .amethyst: return Color(hex: 0x4FC3F7)
        case .midnight: return Color(hex: 0xB388FF)
        case .gilt:     return Color(hex: 0xFF8C42)
        }
    }

    var secondaryDim: Color { secondary.opacity(0.12) }

    var backdropGlow: Color { primary.opacity(0.40) }
    var backdropSecondaryGlow: Color { secondary.opacity(0.18) }

    var colors: ThemeColorScheme {
        switch self {
        case .emerald:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x020A04),
                darkSurface: Color(hex: 0x061A10),
                darkElevated: Color(hex: 0x0A2A18)
            )
        case .bonfire:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x0A0402),
                darkSurface: Color(hex: 0x180E06),
                darkElevated: Color(hex: 0x2A1808)
            )
        case .rose:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x0A0306),
                darkSurface: Color(hex: 0x18080E),
                darkElevated: Color(hex: 0x2A0E18)
            )
        case .amethyst:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x060210),
                darkSurface: Color(hex: 0x0E081A),
                darkElevated: Color(hex: 0x1C0E2A)
            )
        case .midnight:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x020410),
                darkSurface: Color(hex: 0x060E1E),
                darkElevated: Color(hex: 0x0C182E)
            )
        case .gilt:
            return ThemeColorScheme(
                darkBase: Color(hex: 0x0A0802),
                darkSurface: Color(hex: 0x181206),
                darkElevated: Color(hex: 0x2A2008)
            )
        }
    }

    /// Migration from old rawValues
    static func from(legacy raw: String) -> AccentTheme {
        switch raw {
        case "mint":     return .emerald
        case "sunset":   return .bonfire
        case "coral":    return .rose
        case "lavender": return .amethyst
        case "ocean":    return .midnight
        case "gold":     return .gilt
        default:         return AccentTheme(rawValue: raw) ?? .emerald
        }
    }
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
    var colors: ThemeColorScheme { current.colors }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "ss_accentTheme") ?? "emerald"
        self.current = AccentTheme.from(legacy: saved)
    }
}
