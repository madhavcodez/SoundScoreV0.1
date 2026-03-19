import SwiftUI

struct GlassSegmentedControl: View {
    let items: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, label in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = index
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(label)
                        .font(SSTypography.labelLarge)
                        .fontWeight(selection == index ? .bold : .medium)
                        .foregroundColor(selection == index ? SSColors.darkBase : SSColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection == index
                                ? AnyShapeStyle(ThemeManager.shared.primary)
                                : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(SSColors.glassBg)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(SSColors.glassBorder, lineWidth: 0.5))
    }
}
