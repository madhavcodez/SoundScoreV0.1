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
        Button {
            if let firstAlbum = showcase.coverAlbums.first {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSelectAlbum(firstAlbum)
            }
        } label: {
            ZStack(alignment: .bottom) {
                MosaicCover(albums: showcase.coverAlbums, cornerRadius: 20, size: 180)

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .clear, SSColors.overlayDark.opacity(0.8), SSColors.overlayDark],
                    startPoint: .init(x: 0.5, y: 0.0),
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 3) {
                    Text(showcase.list.title)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text("\(showcase.list.curatorHandle) · \(showcase.list.albumIds.count) albums")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(SSColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
