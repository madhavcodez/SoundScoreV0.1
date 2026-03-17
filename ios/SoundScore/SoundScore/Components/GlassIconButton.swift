import SwiftUI

struct GlassIconButton: View {
    let icon: String
    let label: String
    var tint: Color = SSColors.chromeLight
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                    Circle()
                        .stroke(SSColors.glassBorder, lineWidth: 0.5)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(tint)
                }
                Text(label)
                    .font(SSTypography.labelSmall)
                    .foregroundColor(SSColors.chromeDim)
            }
        }
        .buttonStyle(.plain)
    }
}
