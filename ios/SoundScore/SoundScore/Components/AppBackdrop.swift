import SwiftUI

struct AppBackdrop: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Solid black base
            Color.black

            // Full-screen theme color wash
            themeManager.primary.opacity(0.10)

            // Base gradient with theme-tinted dark colors
            LinearGradient(
                colors: [SSColors.darkElevated, SSColors.darkBase],
                startPoint: .top, endPoint: .bottom
            )

            // Primary glow — strong, covers upper-left quadrant
            RadialGradient(
                colors: [
                    themeManager.primary.opacity(0.45),
                    themeManager.primary.opacity(0.15),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0, endRadius: 500
            )

            // Secondary glow — covers lower-right
            RadialGradient(
                colors: [
                    themeManager.secondary.opacity(0.20),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0, endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
}
