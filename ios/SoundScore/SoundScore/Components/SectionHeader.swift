import SwiftUI

struct SectionHeader: View {
    let eyebrow: String
    let title: String
    var trailing: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(eyebrow.uppercased())
                    .font(SSTypography.labelSmall)
                    .foregroundColor(SSColors.textTertiary)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(SSTypography.labelSmall)
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
            Text(title)
                .font(SSTypography.headlineSmall)
                .foregroundColor(SSColors.chromeLight)
        }
    }
}
