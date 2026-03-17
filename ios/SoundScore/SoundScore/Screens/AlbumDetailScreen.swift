import SwiftUI

struct AlbumDetailScreen: View {
    let album: Album
    @State private var userRating: Float = 0
    @State private var showReviewSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                heroSection
                metadataSection
                rateReviewSection
                listsContainingAlbum
                alsoByArtist
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 36, height: 36)
                        Circle()
                            .stroke(SSColors.glassBorder, lineWidth: 0.5)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SSColors.chromeLight)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            ReviewSheet(album: album, rating: $userRating)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(SSColors.darkElevated)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 28)
                .frame(height: 300)
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(SSTypography.displayMedium)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(album.artist)
                    .font(SSTypography.bodyLarge)
                    .foregroundColor(.white.opacity(0.85))
                Text("\(album.year)")
                    .font(SSTypography.bodySmall)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }

    private var metadataSection: some View {
        HStack {
            HStack(spacing: 6) {
                StarRating(rating: album.avgRating, starSize: 22)
                Text(String(format: "%.1f", album.avgRating))
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.accentAmber)
                    .fontWeight(.bold)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 14))
                    .foregroundColor(SSColors.accentGreen)
                Text("\(album.logCount) logs")
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var rateReviewSection: some View {
        GlassCard(tintColor: SSColors.accentGreen, cornerRadius: 22, borderColor: SSColors.accentGreen.opacity(0.2)) {
            VStack(spacing: 14) {
                Text("Rate & Review")
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("Your rating")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.textSecondary)
                    Spacer()
                    StarRating(rating: userRating, onRate: { newRating in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        userRating = newRating
                    }, starSize: 22)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showReviewSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14))
                        Text("Write a review...")
                    }
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeMedium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SSColors.glassBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SSColors.glassBorder, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var listsContainingAlbum: some View {
        let matchingLists = SeedData.initialLists.filter { $0.albumIds.contains(album.id) }
        return Group {
            if !matchingLists.isEmpty {
                SectionHeader(eyebrow: "Your lists", title: "In your collections")

                ForEach(matchingLists) { list in
                    GlassCard(cornerRadius: 16, borderColor: SSColors.feedItemBorder,
                              contentPadding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 14))
                                .foregroundColor(SSColors.accentViolet)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(list.title)
                                    .font(SSTypography.titleMedium)
                                    .foregroundColor(SSColors.chromeLight)
                                    .fontWeight(.semibold)
                                Text("\(list.albumIds.count) albums · \(list.curatorHandle)")
                                    .font(SSTypography.bodySmall)
                                    .foregroundColor(SSColors.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(SSColors.chromeFaint)
                        }
                    }
                }
            }
        }
    }

    private var alsoByArtist: some View {
        let otherAlbums = SeedData.albums.filter { $0.artist == album.artist && $0.id != album.id }
        return Group {
            SectionHeader(eyebrow: "More", title: "Also by \(album.artist)")

            if otherAlbums.isEmpty {
                GlassCard(cornerRadius: 16, borderColor: SSColors.feedItemBorder) {
                    Text("No other albums in your library yet.")
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(otherAlbums) { other in
                            NavigationLink(value: other) {
                                VStack(spacing: 6) {
                                    AlbumArtwork(artworkUrl: other.artworkUrl, colors: other.artColors, cornerRadius: 14)
                                        .frame(width: 100, height: 100)
                                    Text(other.title)
                                        .font(SSTypography.titleMedium)
                                        .foregroundColor(SSColors.chromeLight)
                                        .lineLimit(1)
                                }
                                .frame(width: 100)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
