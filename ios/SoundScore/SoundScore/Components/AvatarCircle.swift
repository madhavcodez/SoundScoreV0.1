import SwiftUI

struct AvatarCircle: View {
    let initials: String
    let gradientColors: [Color]
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            Text(initials.uppercased())
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
