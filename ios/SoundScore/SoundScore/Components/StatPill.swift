import SwiftUI

struct StatPill: View {
    let value: String
    let label: String
    var highlight: Bool = false
    var accentColor: Color = ThemeManager.shared.primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(SSTypography.headlineMedium)
                .foregroundColor(highlight ? accentColor : SSColors.chromeLight)
                .fontWeight(.black)
            Text(label.uppercased())
                .font(SSTypography.labelSmall)
                .foregroundColor(SSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(highlight ? accentColor.opacity(0.08) : SSColors.glassBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlight ? accentColor.opacity(0.2) : SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }
}
