import SwiftUI

enum CadenceState {
    case idle
    case thinking
    case happy
}

struct CadenceCharacter: View {
    var state: CadenceState = .idle
    var size: CGFloat = 120

    @State private var bobOffset: CGFloat = 0
    @State private var eyeOffset: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0

    private var primaryColor: Color { ThemeManager.shared.primary }

    var body: some View {
        ZStack {
            // Body: rounded teardrop (music note head shape)
            bodyShape
                .fill(
                    LinearGradient(
                        colors: [primaryColor, primaryColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: primaryColor.opacity(0.4), radius: 16, y: 6)

            // Eyes
            HStack(spacing: size * 0.15) {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size * 0.12)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size * 0.12)
            }
            .offset(y: -size * 0.05 + eyeOffset)

            // Smile (happy state)
            if state == .happy {
                smileArc
                    .stroke(Color.white, lineWidth: 2.5)
                    .frame(width: size * 0.2, height: size * 0.08)
                    .offset(y: size * 0.1)
            }

            // Headphones
            headphones
        }
        .scaleEffect(bounceScale)
        .offset(y: bobOffset)
        .onAppear { startAnimations() }
        .onChange(of: state) { startAnimations() }
    }

    // MARK: - Shapes

    private var bodyShape: some Shape {
        RoundedRectangle(cornerRadius: size * 0.35)
    }

    private var smileArc: some Shape {
        SmileShape()
    }

    private var headphones: some View {
        ZStack {
            // Band
            Capsule()
                .stroke(SSColors.chromeMedium, lineWidth: 3)
                .frame(width: size * 0.7, height: size * 0.15)
                .offset(y: -size * 0.4)

            // Left ear
            Circle()
                .fill(SSColors.chromeMedium)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.35, y: -size * 0.33)

            // Right ear
            Circle()
                .fill(SSColors.chromeMedium)
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.35, y: -size * 0.33)
        }
    }

    // MARK: - Arms

    // MARK: - Animations

    private func startAnimations() {
        switch state {
        case .idle:
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                bobOffset = -6
            }
            withAnimation(.default) {
                eyeOffset = 0
                bounceScale = 1.0
            }

        case .thinking:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bobOffset = -4
                bounceScale = 1.03
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                eyeOffset = -4
            }

        case .happy:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                bounceScale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceScale = 1.0
                }
            }
            withAnimation(.default) {
                eyeOffset = 0
                bobOffset = 0
            }
        }
    }
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
