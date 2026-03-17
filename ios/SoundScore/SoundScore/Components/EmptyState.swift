import SwiftUI

struct EmptyState: View {
    let title: String
    let subtitle: String
    var icon: String?
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder) {
            VStack(spacing: 12) {
                if let icon {
                    ZStack {
                        Circle()
                            .fill(SSColors.glassBg)
                            .frame(width: 48, height: 48)
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(SSColors.chromeDim)
                    }
                }
                Text(title)
                    .font(SSTypography.titleLarge)
                    .foregroundColor(SSColors.chromeLight)
                Text(subtitle)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textTertiary)
                    .multilineTextAlignment(.center)
                if let actionLabel, let onAction {
                    SSButton(text: actionLabel, action: onAction)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
