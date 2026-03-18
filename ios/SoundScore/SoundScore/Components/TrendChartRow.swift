import SwiftUI

struct TrendChartRow: View {
    let entry: ChartEntry

    var body: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.primaryDim)
                        .frame(width: 32, height: 32)
                    Text("\(entry.rank)")
                        .font(SSTypography.labelLarge)
                        .foregroundColor(ThemeManager.shared.primary)
                }

                AlbumArtwork(
                    artworkUrl: entry.album.artworkUrl,
                    colors: entry.album.artColors,
                    cornerRadius: 12
                )
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.album.title)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text("\(entry.album.artist) · \(entry.album.logCount) logs")
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(entry.movementLabel)
                        .font(SSTypography.labelSmall)
                        .fontWeight(.bold)
                }
                .foregroundColor(ThemeManager.shared.primary)
            }
        }
    }
}
