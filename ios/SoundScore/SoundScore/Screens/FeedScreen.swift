import SwiftUI

struct FeedScreen: View {
    @StateObject private var viewModel = FeedViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }
    @State private var appeared = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SyncBanner(message: viewModel.syncMessage)

                ScreenHeader(
                    title: "Feed",
                    subtitle: "What your people are logging right now."
                )

                if !viewModel.trendingAlbums.isEmpty {
                    SectionHeader(eyebrow: "Trending", title: "Hot this week")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(viewModel.trendingAlbums) { album in
                                TrendingHeroCard(album: album)
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        onSelectAlbum(album)
                                    }
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }

                if viewModel.items.isEmpty {
                    EmptyState(
                        title: "Your feed is quiet",
                        subtitle: "Follow friends to see their ratings, reviews, and lists here.",
                        icon: "person.2"
                    )
                } else {
                    SectionHeader(eyebrow: "Activity", title: "From your circle")

                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        FeedActivityCard(item: item, onSelectAlbum: onSelectAlbum) {
                            viewModel.toggleLike(item.id)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.04), value: appeared)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .onAppear { appeared = true }
    }
}

private struct TrendingHeroCard: View {
    let album: Album

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 24)

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .init(x: 0.5, y: 0.35),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(SSTypography.titleLarge)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(album.artist)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(.white.opacity(0.8))
                Spacer().frame(height: 6)
                HStack {
                    StarRating(rating: album.avgRating, starSize: 12)
                    Spacer()
                    Text("\(album.logCount)")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(SSColors.accentGreen)
                }
            }
            .padding(14)
        }
        .frame(width: 200, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }
}

private struct FeedActivityCard: View {
    let item: FeedItem
    var onSelectAlbum: (Album) -> Void = { _ in }
    let onToggleLike: () -> Void

    var body: some View {
        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        AvatarCircle(initials: String(item.username.prefix(2)), gradientColors: avatarColors(item.username))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("@\(item.username)")
                                .font(SSTypography.titleMedium)
                                .foregroundColor(SSColors.chromeLight)
                                .fontWeight(.bold)
                            Text(item.action)
                                .font(SSTypography.bodySmall)
                                .foregroundColor(SSColors.textSecondary)
                        }
                    }
                    Spacer()
                    Text(item.timeAgo)
                        .font(SSTypography.labelSmall)
                        .foregroundColor(SSColors.textTertiary)
                }

                HStack(spacing: 12) {
                    AlbumArtwork(artworkUrl: item.album.artworkUrl, colors: item.album.artColors, cornerRadius: 16)
                        .frame(width: 72, height: 72)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSelectAlbum(item.album)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.album.title)
                            .font(SSTypography.titleLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(SSColors.chromeLight)
                        Text("\(item.album.artist) · \(item.album.year)")
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textSecondary)
                        StarRating(rating: item.rating, starSize: 14)
                    }
                }

                if let snippet = item.reviewSnippet, !snippet.isEmpty {
                    Text("\"\(snippet)\"")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.chromeLight.opacity(0.9))
                        .italic()
                }

                HStack(spacing: 8) {
                    ActionChip(text: "\(item.likes)", icon: "heart", active: item.isLiked, onTap: onToggleLike)
                    ActionChip(text: "\(item.comments)", icon: "bubble.left")
                    ActionChip(text: "Share", icon: "square.and.arrow.up")
                }
            }
        }
    }
}

private func avatarColors(_ username: String) -> [Color] {
    switch username {
    case "rohan": return AlbumColors.forest
    case "priya": return AlbumColors.rose
    case "kai": return AlbumColors.orchid
    case "zara": return AlbumColors.lagoon
    case "alex": return AlbumColors.amber
    case "jordan": return AlbumColors.midnight
    case "mia": return AlbumColors.lime
    case "sam": return AlbumColors.ember
    default: return [SSColors.accentGreen, SSColors.accentCoral]
    }
}
