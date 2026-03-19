import SwiftUI

struct FeedScreen: View {
    @StateObject private var viewModel = FeedViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }
    @State private var appeared = false
    @State private var trendingMode: Int = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                SyncBanner(message: viewModel.syncMessage)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error, onRetry: { viewModel.refresh() })
                }

                ScreenHeader(
                    title: "Feed",
                    subtitle: "The pulse of your circle."
                )

                if viewModel.isLoading && viewModel.items.isEmpty {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                } else {
                    if !viewModel.trendingAlbums.isEmpty {
                        SectionHeader(eyebrow: "Trending", title: "Hot this week")

                        // Albums/Songs toggle
                        GlassSegmentedControl(items: ["Albums", "Songs"], selection: $trendingMode)

                        if trendingMode == 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(Array(viewModel.trendingAlbums.enumerated()), id: \.element.id) { index, album in
                                        TrendingHeroCard(album: album, rank: index + 1)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                onSelectAlbum(album)
                                            }
                                    }
                                }
                                .padding(.trailing, 8)
                            }
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(viewModel.trendingSongs.prefix(10)) { song in
                                        TrendingSongCard(song: song)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                onSelectAlbum(song.album)
                                            }
                                    }
                                }
                                .padding(.trailing, 8)
                            }
                        }
                    }

                    // Collections section (lists in feed)
                    if !viewModel.featuredLists.isEmpty {
                        SectionHeader(eyebrow: "Curated", title: "Collections")

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 12) {
                                ForEach(viewModel.featuredLists.prefix(4)) { showcase in
                                    CompactListCard(showcase: showcase, onSelectAlbum: onSelectAlbum)
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .refreshable { await SoundScoreRepository.shared.refresh() }
        .onAppear { appeared = true }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        GlassCard(tintColor: SSColors.accentCoral, cornerRadius: 16, borderColor: SSColors.accentCoral.opacity(0.3)) {
            HStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 14))
                    .foregroundColor(SSColors.accentCoral)
                Text(message)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.chromeLight)
                Spacer()
                if let onRetry {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onRetry()
                    } label: {
                        Text("Retry")
                            .font(SSTypography.labelMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(SSColors.accentCoral)
                    }
                }
            }
        }
    }
}

// MARK: - Trending Card (redesigned with rank badge, glow, border)

private struct TrendingHeroCard: View {
    let album: Album
    let rank: Int

    private var dominantColor: Color {
        album.artColors.first ?? ThemeManager.shared.primary
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 24)

            LinearGradient(
                colors: [.clear, .clear, SSColors.overlayDark.opacity(0.6), SSColors.overlayDark],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(SSTypography.titleLarge)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(album.artist)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
                Spacer().frame(height: 6)
                HStack {
                    StarRating(rating: album.avgRating, starSize: 12)
                    Spacer()
                    Text("\(album.logCount)")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(ThemeManager.shared.primary)
                }
            }
            .padding(14)

            // Rank badge
            VStack {
                HStack {
                    Text("#\(rank)")
                        .font(SSTypography.labelSmall)
                        .fontWeight(.black)
                        .foregroundColor(SSColors.chromeLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(dominantColor.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(10)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: 220, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(dominantColor.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: dominantColor.opacity(0.3), radius: 12, y: 4)
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
                        Text("\(item.album.artist) · \(String(item.album.year))")
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
                    ShareLink(item: "\(item.username) rated \(item.album.title) by \(item.album.artist)") {
                        ActionChip(text: "Share", icon: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Trending Song Card

private struct TrendingSongCard: View {
    let song: TrendingSong

    var body: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder,
                  contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 10) {
                AlbumArtwork(artworkUrl: song.album.artworkUrl, colors: song.album.artColors, cornerRadius: 12)
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(song.track.title)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Text(song.album.artist)
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                        .lineLimit(1)
                    StarRating(rating: song.avgRating, starSize: 11)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(width: 200)
    }
}

private func avatarColors(_ username: String) -> [Color] {
    let hash = abs(username.hashValue)
    let palettes: [[Color]] = [
        AlbumColors.forest, AlbumColors.rose, AlbumColors.orchid,
        AlbumColors.lagoon, AlbumColors.amber, AlbumColors.midnight,
        AlbumColors.lime, AlbumColors.ember, AlbumColors.coral,
        AlbumColors.slate,
    ]
    return palettes[hash % palettes.count]
}
