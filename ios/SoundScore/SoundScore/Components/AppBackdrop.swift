import SwiftUI

struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SSColors.darkElevated, SSColors.darkBase],
                startPoint: .top, endPoint: .bottom
            )

            RadialGradient(
                colors: [SSColors.accentGreen.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 0, endRadius: 400
            )

            RadialGradient(
                colors: [SSColors.accentViolet.opacity(0.06), Color.clear],
                center: .bottomTrailing,
                startRadius: 0, endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}
