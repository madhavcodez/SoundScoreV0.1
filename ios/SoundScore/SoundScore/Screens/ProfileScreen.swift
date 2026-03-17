import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        if let profile = viewModel.profile {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    SyncBanner(message: viewModel.syncMessage)

                    GlassCard(cornerRadius: 26, borderColor: SSColors.feedItemBorder, frosted: true) {
                        VStack(spacing: 12) {
                            AvatarCircle(
                                initials: String(profile.handle.dropFirst().prefix(2)),
                                gradientColors: [SSColors.accentGreen, SSColors.accentViolet],
                                size: 80
                            )
                            Text(profile.handle)
                                .font(SSTypography.headlineMedium)
                                .foregroundColor(SSColors.chromeLight)
                                .fontWeight(.bold)
                            Text(profile.bio)
                                .font(SSTypography.bodyMedium)
                                .foregroundColor(SSColors.textSecondary)
                                .multilineTextAlignment(.center)
                            HStack(spacing: 24) {
                                ProfileCount(value: "\(profile.followingCount)", label: "Following")
                                ProfileCount(value: "\(profile.followersCount)", label: "Followers")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    HStack(spacing: 10) {
                        StatPill(value: "\(profile.albumsCount)", label: "Albums", highlight: true)
                        StatPill(value: "\(profile.reviewCount)", label: "Reviews")
                        StatPill(value: "\(profile.listCount)", label: "Lists")
                        StatPill(value: String(format: "%.1f", profile.avgRating), label: "Avg", highlight: true, accentColor: SSColors.accentAmber)
                    }

                    HStack {
                        Spacer()
                        GlassIconButton(icon: "square.and.arrow.up", label: "Share", tint: SSColors.accentGreen)
                        Spacer()
                        GlassIconButton(icon: "arrow.down.circle", label: "Export")
                        Spacer()
                        GlassIconButton(icon: "gearshape", label: "Settings")
                        Spacer()
                    }

                    if !viewModel.favoriteAlbums.isEmpty {
                        SectionHeader(eyebrow: "Favorites", title: "Pinned to your identity")
                        FavoriteGrid(albums: viewModel.favoriteAlbums)
                    }

                    SectionHeader(eyebrow: "Taste DNA", title: "Genres on repeat")
                    TasteTags(tags: profile.genres)

                    if let recap = viewModel.latestRecap {
                        SectionHeader(eyebrow: "Weekly recap", title: "Your week in music")
                        RecapCard(totalLogs: recap.totalLogs, avgRating: recap.averageRating, shareText: recap.shareText)
                    }

                    EmptyState(
                        title: "Recent activity",
                        subtitle: "Your latest ratings and reviews will appear here.",
                        icon: "clock.arrow.circlepath"
                    )

                    EmptyState(
                        title: "Achievements",
                        subtitle: "Badges and milestones — coming soon.",
                        icon: "trophy"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        } else {
            Text("Loading profile...")
                .foregroundColor(SSColors.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ProfileCount: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(SSTypography.titleLarge)
                .foregroundColor(SSColors.chromeLight)
                .fontWeight(.bold)
            Text(label)
                .font(SSTypography.labelSmall)
                .foregroundColor(SSColors.textTertiary)
        }
    }
}

private struct FavoriteGrid: View {
    let albums: [Album]

    var body: some View {
        let rows = stride(from: 0, to: albums.count, by: 3).map { i in
            Array(albums[i..<min(i + 3, albums.count)])
        }
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
            HStack(spacing: 10) {
                ForEach(row) { album in
                    GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6), onTap: {}) {
                        VStack(spacing: 6) {
                            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 14)
                                .frame(height: 100)
                            Text(album.title)
                                .font(SSTypography.titleMedium)
                                .fontWeight(.medium)
                                .foregroundColor(SSColors.chromeLight)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                ForEach(0..<(3 - row.count), id: \.self) { _ in
                    Spacer().frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct TasteTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                    let tagColors: [Color] = {
                        switch index % 4 {
                        case 0: return AlbumColors.orchid
                        case 1: return AlbumColors.lagoon
                        case 2: return AlbumColors.ember
                        default: return AlbumColors.rose
                        }
                    }()
                    Text(tag)
                        .font(SSTypography.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(SSColors.chromeLight)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [tagColors.first!.opacity(0.4), tagColors.last!.opacity(0.15)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(tagColors.last!.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

private struct RecapCard: View {
    let totalLogs: Int
    let avgRating: Float
    let shareText: String

    var body: some View {
        GlassCard(tintColor: SSColors.accentGreen, cornerRadius: 22, borderColor: SSColors.accentGreen.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(totalLogs)")
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.accentGreen)
                            .fontWeight(.black)
                        Text("ALBUMS LOGGED")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", avgRating))
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.black)
                        Text("AVG RATING")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                }
                Text(shareText)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.textSecondary)
                HStack(spacing: 10) {
                    SSButton(text: "View Recap", action: {})
                    GlassIconButton(icon: "square.and.arrow.up", label: "Share", tint: SSColors.accentGreen)
                }
            }
        }
    }
}
