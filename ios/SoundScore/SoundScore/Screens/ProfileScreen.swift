import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }
    var onOpenSettings: () -> Void = {}
    @State private var appeared = false

    var body: some View {
        if let profile = viewModel.profile {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    SyncBanner(message: viewModel.syncMessage)

                    GlassCard(cornerRadius: 24, borderColor: SSColors.feedItemBorder, frosted: true) {
                        VStack(spacing: 12) {
                            AvatarCircle(
                                initials: String(profile.handle.dropFirst().prefix(2)),
                                gradientColors: [ThemeManager.shared.primary, SSColors.accentViolet],
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
                        ShareLink(item: viewModel.shareProfileText()) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(SSColors.glassBg)
                                        .frame(width: 44, height: 44)
                                    Circle()
                                        .stroke(SSColors.glassBorder, lineWidth: 0.5)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                        .foregroundColor(ThemeManager.shared.primary)
                                }
                                Text("Share")
                                    .font(SSTypography.labelSmall)
                                    .foregroundColor(SSColors.textTertiary)
                            }
                        }
                        Spacer()
                        GlassIconButton(icon: "arrow.down.circle", label: "Export", action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.showExportSuccess = true
                        })
                        Spacer()
                        GlassIconButton(icon: "gearshape", label: "Settings", action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenSettings()
                        })
                        Spacer()
                    }

                    if !viewModel.favoriteAlbums.isEmpty {
                        SectionHeader(eyebrow: "Favorites", title: "Pinned to your identity")
                        FavoriteGrid(albums: viewModel.favoriteAlbums, onSelectAlbum: onSelectAlbum, appeared: appeared)
                    }

                    SectionHeader(eyebrow: "Taste DNA", title: "Genres on repeat")
                    TasteTags(tags: profile.genres)

                    if let recap = viewModel.latestRecap {
                        SectionHeader(eyebrow: "Weekly recap", title: "Your week in music")
                        RecapCard(recap: recap, shareText: viewModel.shareProfileText())
                    }

                    if !viewModel.recentActivity.isEmpty {
                        SectionHeader(eyebrow: "Activity", title: "Recent ratings")
                        ForEach(viewModel.recentActivity) { item in
                            GlassCard(cornerRadius: 16, borderColor: SSColors.feedItemBorder,
                                      contentPadding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)) {
                                HStack(spacing: 10) {
                                    AlbumArtwork(artworkUrl: item.album.artworkUrl, colors: item.album.artColors, cornerRadius: 12)
                                        .frame(width: 44, height: 44)
                                        .onTapGesture { onSelectAlbum(item.album) }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.album.title)
                                            .font(SSTypography.titleMedium)
                                            .foregroundColor(SSColors.chromeLight)
                                            .fontWeight(.semibold)
                                        Text(item.action)
                                            .font(SSTypography.bodySmall)
                                            .foregroundColor(SSColors.textSecondary)
                                    }
                                    Spacer()
                                    Text(item.timeAgo)
                                        .font(SSTypography.labelSmall)
                                        .foregroundColor(SSColors.textTertiary)
                                }
                            }
                        }
                    } else {
                        EmptyState(
                            title: "Recent activity",
                            subtitle: "Your latest ratings and reviews will appear here.",
                            icon: "clock.arrow.circlepath"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .refreshable { await SoundScoreRepository.shared.refresh() }
            .onAppear { appeared = true }
            .alert("Export Queued", isPresented: $viewModel.showExportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your data export has been queued. You'll receive a download link when it's ready.")
            }
        } else {
            VStack(spacing: 12) {
                SkeletonView()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                SkeletonView()
                    .frame(width: 120, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                SkeletonView()
                    .frame(width: 200, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
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
    var onSelectAlbum: (Album) -> Void = { _ in }
    var appeared: Bool = false

    var body: some View {
        let rows = stride(from: 0, to: albums.count, by: 3).map { i in
            Array(albums[i..<min(i + 3, albums.count)])
        }
        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
            HStack(spacing: 10) {
                ForEach(Array(row.enumerated()), id: \.element.id) { colIndex, album in
                    let flatIndex = rowIndex * 3 + colIndex
                    GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6), onTap: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelectAlbum(album)
                    }) {
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
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.easeOut(duration: 0.3).delay(Double(flatIndex) * 0.06), value: appeared)
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
    let recap: WeeklyRecap
    let shareText: String

    var body: some View {
        GlassCard(tintColor: ThemeManager.shared.primary, cornerRadius: 22, borderColor: ThemeManager.shared.primary.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(recap.totalLogs)")
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(ThemeManager.shared.primary)
                            .fontWeight(.black)
                        Text("ALBUMS LOGGED")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", recap.averageRating))
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.black)
                        Text("AVG RATING")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                }
                Text(recap.shareText)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.textSecondary)
                HStack(spacing: 10) {
                    SSButton(text: "View Recap") {
                        // Deep link to recap view
                        if let url = URL(string: recap.deepLink) {
                            UIApplication.shared.open(url)
                        }
                    }
                    ShareLink(item: recap.shareText) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("Share")
                                .font(SSTypography.labelMedium)
                        }
                        .foregroundColor(ThemeManager.shared.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SSColors.glassBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(SSColors.glassBorder, lineWidth: 0.5)
                        )
                    }
                }
            }
        }
    }
}
