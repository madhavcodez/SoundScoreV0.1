import SwiftUI

struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SSTypography.displayMedium)
                    .foregroundColor(SSColors.chromeLight)
                Text(subtitle)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.textSecondary)
            }
            Spacer()
            if let actionLabel, let onAction {
                Button(action: onAction) {
                    Text(actionLabel)
                        .font(SSTypography.labelLarge)
                        .foregroundColor(SSColors.accentGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(SSColors.accentGreenDim)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
