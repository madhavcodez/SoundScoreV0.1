import SwiftUI

struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SSColors.darkElevated, SSColors.darkBase],
                startPoint: .top, endPoint: .bottom
            )

            RadialGradient(
                colors: [ThemeManager.shared.current.backdropGlow, Color.clear],
                center: .topLeading,
                startRadius: 0, endRadius: 400
            )

            RadialGradient(
                colors: [ThemeManager.shared.current.backdropSecondaryGlow, Color.clear],
                center: .bottomTrailing,
                startRadius: 0, endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}
