import SwiftUI

struct SyncBanner: View {
    let message: String?

    var body: some View {
        if let message {
            HStack(spacing: 8) {
                Image(systemName: "icloud.slash")
                    .font(.system(size: 14, weight: .medium))
                Text(message)
                    .font(SSTypography.bodySmall)
            }
            .foregroundColor(SSColors.accentAmber)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(SSColors.accentAmberDim)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
