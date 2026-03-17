import SwiftUI

struct ActionChip: View {
    let text: String
    let icon: String
    var active: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(text)
                    .font(SSTypography.labelSmall)
            }
            .foregroundColor(active ? SSColors.accentGreen : SSColors.chromeDim)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(active ? SSColors.accentGreenDim : SSColors.glassBg)
            )
            .overlay(
                Capsule()
                    .stroke(active ? SSColors.accentGreen.opacity(0.3) : SSColors.feedItemBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
