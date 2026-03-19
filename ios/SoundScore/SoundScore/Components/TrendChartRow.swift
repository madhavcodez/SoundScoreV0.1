import SwiftUI

struct TrendChartRow: View {
    let entry: ChartEntry

    private var rankColor: Color {
        switch entry.rank {
        case 1: return ThemeManager.shared.primary
        case 2: return SSColors.accentAmber
        case 3: return SSColors.accentCoral
        default: return SSColors.chromeDim
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored accent strip
            RoundedRectangle(cornerRadius: 1)
                .fill(rankColor)
                .frame(width: 3)
                .padding(.vertical, 6)

            HStack(spacing: 12) {
                // Rank number
                Text("\(entry.rank)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(rankColor)
                    .frame(width: 28)

                AlbumArtwork(
                    artworkUrl: entry.album.artworkUrl,
                    colors: entry.album.artColors,
                    cornerRadius: 12
                )
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.album.title)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(SSColors.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }
}
