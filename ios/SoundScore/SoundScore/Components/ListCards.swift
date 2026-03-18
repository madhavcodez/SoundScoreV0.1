import SwiftUI

struct FeaturedListHero: View {
    let showcase: ListShowcase
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        Button {
            if let firstAlbum = showcase.coverAlbums.first {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelectAlbum(firstAlbum)
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let cover = showcase.coverAlbums.first {
                    AlbumArtwork(artworkUrl: cover.artworkUrl, colors: cover.artColors, cornerRadius: 24)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(SSColors.glassBg)
                }

                LinearGradient(
                    colors: [.clear, SSColors.overlayDark],
                    startPoint: .init(x: 0.5, y: 0.15),
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text("FEATURED")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(ThemeManager.shared.primary)
                        .fontWeight(.bold)
                    Text(showcase.list.title)
                        .font(SSTypography.headlineMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                    Text("\(showcase.list.curatorHandle) · \(showcase.list.albumIds.count) albums · \(showcase.list.saves) saves")
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                }
                .padding(16)
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactListCard: View {
    let showcase: ListShowcase
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10), onTap: {
            if let firstAlbum = showcase.coverAlbums.first {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelectAlbum(firstAlbum)
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                MosaicCover(albums: showcase.coverAlbums, cornerRadius: 14)
                Text(showcase.list.title)
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(showcase.list.albumIds.count) albums")
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textTertiary)
            }
        }
        .frame(width: 180)
    }
}
