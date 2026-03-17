import SwiftUI

struct TimelineEntry<Content: View>: View {
    let dateLabel: String
    let timeLabel: String
    let content: () -> Content

    init(dateLabel: String, timeLabel: String, @ViewBuilder content: @escaping () -> Content) {
        self.dateLabel = dateLabel
        self.timeLabel = timeLabel
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(dateLabel)
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.accentGreen)
                Text(timeLabel)
                    .font(SSTypography.labelSmall)
                    .foregroundColor(SSColors.chromeDim)
                Rectangle()
                    .fill(SSColors.glassBorder)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 48)

            content()
        }
    }
}
