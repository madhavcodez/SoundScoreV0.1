import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.iconFilled : tab.icon)
                            .font(.system(size: selectedTab == tab ? 24 : 20))
                            .foregroundColor(
                                selectedTab == tab
                                    ? ThemeManager.shared.primary
                                    : SSColors.chromeDim
                            )

                        Capsule()
                            .fill(ThemeManager.shared.primary)
                            .frame(width: selectedTab == tab ? 16 : 0, height: 3)
                            .opacity(selectedTab == tab ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(SSColors.glassBorder, lineWidth: 0.5)
                )
        )
    }
}
