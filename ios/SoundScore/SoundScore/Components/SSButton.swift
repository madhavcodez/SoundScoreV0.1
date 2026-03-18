import SwiftUI

struct SSButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(SSTypography.labelLarge)
                .foregroundColor(SSColors.darkBase)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(ThemeManager.shared.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct SSGhostButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(SSTypography.labelLarge)
                .foregroundColor(SSColors.chromeLight)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(SSColors.glassBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
