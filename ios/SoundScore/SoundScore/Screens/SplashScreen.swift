import SwiftUI

struct SplashScreen: View {
    var onComplete: () -> Void = {}

    // Animation state
    @State private var currentThemeIndex: Int = 0
    @State private var themeOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var glowRadius: CGFloat = 0
    @State private var cycling = true

    private let themes = AccentTheme.allCases
    private let cycleDuration: Double = 0.35
    private let totalCycles: Int = 12 // cycle through themes twice

    var body: some View {
        let theme = themes[currentThemeIndex % themes.count]

        ZStack {
            // Animated theme background
            Color.black.ignoresSafeArea()

            // Theme color wash
            theme.primary.opacity(0.10)
                .ignoresSafeArea()

            // Gradient base
            LinearGradient(
                colors: [theme.colors.darkElevated, theme.colors.darkBase],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Primary glow
            RadialGradient(
                colors: [
                    theme.primary.opacity(0.5),
                    theme.primary.opacity(0.15),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()
            .opacity(themeOpacity)

            // Secondary glow
            RadialGradient(
                colors: [theme.secondary.opacity(0.25), Color.clear],
                center: .bottomTrailing,
                startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(themeOpacity)

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: theme.primary.opacity(0.6), radius: glowRadius, y: 4)

                Spacer().frame(height: 20)

                // Title
                Text("SoundScore")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(SSColors.chromeLight)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Spacer().frame(height: 8)

                // Subtitle
                Text("Your taste, your journal.")
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.textSecondary)
                    .opacity(subtitleOpacity)

                Spacer()
                Spacer()

                // Get Started button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onComplete()
                    }
                } label: {
                    Text("Get Started")
                        .font(SSTypography.labelLarge)
                        .fontWeight(.bold)
                        .foregroundColor(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)

                Spacer().frame(height: 60)
            }
        }
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Phase 1: Rapid theme cycling (0–2s)
        themeOpacity = 1
        for i in 0..<totalCycles {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * cycleDuration) {
                withAnimation(.easeInOut(duration: cycleDuration * 0.8)) {
                    currentThemeIndex = i
                }
            }
        }

        // Phase 2: Settle on user's saved theme
        let settleTime = Double(totalCycles) * cycleDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
            let savedIndex = themes.firstIndex(of: ThemeManager.shared.current) ?? 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                currentThemeIndex = savedIndex
                cycling = false
            }
        }

        // Phase 3: Logo appears (at 0.8s — overlaps with cycling)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
                glowRadius = 20
            }
        }

        // Phase 4: Title slides up (at 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }

        // Phase 5: Subtitle fades in (at 1.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeIn(duration: 0.4)) {
                subtitleOpacity = 1.0
            }
        }

        // Phase 6: Button appears (at 2.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
}
