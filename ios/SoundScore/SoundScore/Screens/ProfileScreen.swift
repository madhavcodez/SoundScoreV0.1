import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel = ProfileViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }
    var onOpenSettings: () -> Void = {}
    @State private var appeared = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SyncBanner(message: viewModel.syncMessage)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                heroBanner
                statsRow
                actionBar

                if !viewModel.favoriteAlbums.isEmpty {
                    favoritesSection
                }

                if !viewModel.genres.isEmpty {
                    tasteDNASection
                }

                if let recap = viewModel.recap {
                    recapCard(recap)
                }

                if !viewModel.recentActivity.isEmpty {
                    recentActivitySection
                }
            }
            .padding(.bottom, 120)
        }
        .refreshable { await SoundScoreRepository.shared.refresh() }
        .onAppear { appeared = true }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                let artworks = viewModel.favoriteAlbums.prefix(4)
                if !artworks.isEmpty {
                    GeometryReader { geo in
                        let size = geo.size
                        ZStack {
                            ForEach(Array(artworks.enumerated()), id: \.element.id) { index, album in
                                AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 0)
                                    .frame(width: size.width / 2, height: 140)
                                    .offset(
                                        x: index % 2 == 0 ? -size.width / 4 : size.width / 4,
                                        y: index < 2 ? -70 : 70
                                    )
                            }
                        }
                        .frame(width: size.width, height: size.height)
                        .blur(radius: 30)
                    }
                } else {
                    ThemeManager.shared.primary.opacity(0.15)
                }

                LinearGradient(
                    colors: [SSColors.overlayMedium, SSColors.overlayDark],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .frame(height: 280)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(ThemeManager.shared.primary.opacity(0.2))
                        .frame(width: 106, height: 106)
                        .blur(radius: 12)

                    AvatarCircle(
                        initials: String(viewModel.handle.dropFirst().prefix(2)),
                        gradientColors: [ThemeManager.shared.primary, SSColors.accentViolet],
                        size: 96
                    )
                    .overlay(
                        Circle()
                            .stroke(ThemeManager.shared.primary, lineWidth: 3)
                            .frame(width: 96, height: 96)
                    )
                    .shadow(color: ThemeManager.shared.primary.opacity(0.4), radius: 12, y: 4)
                }

                Text(viewModel.handle)
                    .font(SSTypography.displayMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)

                Text(viewModel.bio)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.metrics) { metric in
                GlassCard(cornerRadius: 16, borderColor: SSColors.feedItemBorder,
                          contentPadding: EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)) {
                    VStack(spacing: 4) {
                        Text(metric.value)
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(metric.label == "Albums" ? ThemeManager.shared.primary : SSColors.chromeLight)
                            .fontWeight(.black)
                        Text(metric.label.uppercased())
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private var actionBar: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder,
                  contentPadding: EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)) {
            HStack(spacing: 12) {
                Button {} label: {
                    Text("Edit Profile")
                        .font(SSTypography.labelLarge)
                        .foregroundColor(SSColors.chromeLight)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(ThemeManager.shared.primary.opacity(0.25))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                ShareLink(item: viewModel.shareProfileText()) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(SSColors.chromeMedium)
                        .frame(width: 36, height: 36)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }

                Button { onOpenSettings() } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundColor(SSColors.chromeMedium)
                        .frame(width: 36, height: 36)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Top picks", title: "Favorites", trailing: "See All")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(viewModel.favoriteAlbums.enumerated()), id: \.element.id) { index, album in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSelectAlbum(album)
                        } label: {
                            ZStack(alignment: .bottom) {
                                AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 18)

                                LinearGradient(
                                    colors: [.clear, SSColors.overlayDark],
                                    startPoint: .init(x: 0.5, y: 0.4), endPoint: .bottom
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(album.title)
                                        .font(SSTypography.titleMedium)
                                        .foregroundColor(SSColors.chromeLight)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                    Text(album.artist)
                                        .font(SSTypography.labelSmall)
                                        .foregroundColor(SSColors.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: 140, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(SSColors.feedItemBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08), value: appeared)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Taste DNA

    private var tasteDNASection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Your vibe", title: "Taste DNA")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    let palettes: [[Color]] = [
                        AlbumColors.forest, AlbumColors.orchid, AlbumColors.lagoon,
                        AlbumColors.ember, AlbumColors.rose, AlbumColors.midnight,
                    ]
                    ForEach(Array(viewModel.genres.enumerated()), id: \.offset) { index, genre in
                        Text(genre)
                            .font(SSTypography.labelLarge)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: palettes[index % palettes.count],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Recap

    private func recapCard(_ recap: WeeklyRecap) -> some View {
        GlassCard(tintColor: ThemeManager.shared.primary, cornerRadius: 22, borderColor: ThemeManager.shared.primary.opacity(0.2)) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(ThemeManager.shared.primary)
                    Text("Weekly Recap")
                        .font(SSTypography.headlineSmall)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                    Spacer()
                }

                HStack {
                    VStack(spacing: 2) {
                        Text("\(recap.totalLogs)")
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.chromeLight)
                            .fontWeight(.black)
                        Text("LOGS")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", recap.averageRating))
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.black)
                        Text("AVG")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }

                ShareLink(item: recap.shareText) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                        Text("Share Recap")
                            .font(SSTypography.labelMedium)
                    }
                    .foregroundColor(ThemeManager.shared.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeManager.shared.primary.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(eyebrow: "Recent", title: "Activity")
                .padding(.horizontal, 20)

            ForEach(viewModel.recentActivity) { entry in
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(LinearGradient(colors: entry.album.artColors, startPoint: .top, endPoint: .bottom))
                        .frame(width: 3)
                        .padding(.vertical, 4)

                    HStack(spacing: 10) {
                        AlbumArtwork(artworkUrl: entry.album.artworkUrl, colors: entry.album.artColors, cornerRadius: 12)
                            .frame(width: 56, height: 56)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSelectAlbum(entry.album)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.album.title)
                                .font(SSTypography.titleMedium)
                                .foregroundColor(SSColors.chromeLight)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(entry.album.artist)
                                .font(SSTypography.bodySmall)
                                .foregroundColor(SSColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            StarRating(rating: entry.rating, starSize: 10)
                            Text(entry.dateLabel)
                                .font(SSTypography.labelSmall)
                                .foregroundColor(SSColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .background(SSColors.glassBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SSColors.feedItemBorder, lineWidth: 0.5))
                .padding(.horizontal, 20)
            }
        }
    }
}
