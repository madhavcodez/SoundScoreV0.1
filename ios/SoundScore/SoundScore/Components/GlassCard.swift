import SwiftUI

struct GlassCard<Content: View>: View {
    var tintColor: Color?
    var cornerRadius: CGFloat
    var borderColor: Color
    var contentPadding: EdgeInsets
    var frosted: Bool
    var onTap: (() -> Void)?
    let content: () -> Content

    @State private var isPressed = false

    init(
        tintColor: Color? = nil,
        cornerRadius: CGFloat = 20,
        borderColor: Color = SSColors.feedItemBorder,
        contentPadding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14),
        frosted: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.contentPadding = contentPadding
        self.frosted = frosted
        self.onTap = onTap
        self.content = content
    }

    var body: some View {
        content()
            .padding(contentPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.15), tint.opacity(0.03)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }
                    if frosted {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(SSColors.glassHighlight.opacity(0.06))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isPressed)
            .if(onTap != nil) { view in
                view.onTapGesture { onTap?() }
                    .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                        isPressed = pressing
                    }, perform: {})
            }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct PlaceholderScreen: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title)
                .font(SSTypography.displaySmall)
                .foregroundColor(SSColors.chromeLight)
            Text(subtitle)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SSColors.darkBase)
    }
}
