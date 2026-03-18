import SwiftUI

struct SplashScreen: View {
    var onComplete: () -> Void = {}

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            AppBackdrop()

            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(ThemeManager.shared.primary)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("SoundScore")
                    .font(SSTypography.displayMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}
