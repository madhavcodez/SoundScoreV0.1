import SwiftUI

struct SyncBanner: View {
    let message: String?

    var body: some View {
        if message != nil {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(SSColors.accentAmber)
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .font(SSTypography.labelMedium)
                    .fontWeight(.semibold)
            }
            .foregroundColor(SSColors.accentAmber)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(SSColors.accentAmberDim)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SSColors.accentAmber.opacity(0.3), lineWidth: 0.5))
            .frame(maxWidth: .infinity, alignment: .center)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
