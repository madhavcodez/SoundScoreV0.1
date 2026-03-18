import SwiftUI

struct LogScreen: View {
    @StateObject private var viewModel = LogViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }
    @State private var showSearchSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    SyncBanner(message: viewModel.syncMessage)

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    ScreenHeader(title: "Diary", subtitle: "Your listening journal. Rate, log, repeat.")

                    if viewModel.isLoading && viewModel.quickLogAlbums.isEmpty {
                        SkeletonView()
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    } else {
                        GlassCard(cornerRadius: 22, borderColor: SSColors.feedItemBorder, frosted: true) {
                            HStack {
                                ForEach(Array(viewModel.summaryStats.enumerated()), id: \.offset) { _, stat in
                                    VStack(spacing: 2) {
                                        Text(stat.value)
                                            .font(SSTypography.headlineMedium)
                                            .foregroundColor(stat.label == "This week" ? ThemeManager.shared.primary : SSColors.chromeLight)
                                            .fontWeight(.black)
                                        Text(stat.label.uppercased())
                                            .font(SSTypography.labelSmall)
                                            .foregroundColor(SSColors.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    SectionHeader(eyebrow: "Quick rate", title: "Tap to rate")

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(viewModel.quickLogAlbums) { album in
                                QuickRateCard(
                                    album: album,
                                    rating: viewModel.ratings[album.id] ?? 0,
                                    onRate: { viewModel.updateRating(albumId: album.id, rating: $0) },
                                    onSelectAlbum: onSelectAlbum
                                )
                            }
                        }
                        .padding(.trailing, 8)
                    }

                    if !viewModel.recentLogs.isEmpty {
                        SectionHeader(eyebrow: "Recent", title: "Your diary entries")

                        ForEach(viewModel.recentLogs) { entry in
                            TimelineEntry(dateLabel: entry.dateLabel, timeLabel: entry.timeLabel) {
                                DiaryEntryCard(entry: entry, onSelectAlbum: onSelectAlbum)
                            }
                        }
                    }

                    GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder) {
                        VStack(spacing: 4) {
                            Text("Write Later")
                                .font(SSTypography.titleMedium)
                                .foregroundColor(SSColors.chromeLight)
                            Text("Queue albums for later review — coming soon")
                                .font(SSTypography.bodySmall)
                                .foregroundColor(SSColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .refreshable { await SoundScoreRepository.shared.refresh() }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showSearchSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SSColors.darkBase)
                    .frame(width: 56, height: 56)
                    .background(ThemeManager.shared.primary)
                    .clipShape(Circle())
                    .shadow(color: ThemeManager.shared.primary.opacity(0.3), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showSearchSheet) {
            QuickLogSearchSheet(onSelectAlbum: { album in
                showSearchSheet = false
                onSelectAlbum(album)
            })
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(SSColors.darkElevated)
        }
    }
}

// MARK: - Quick Log Search Sheet

private struct QuickLogSearchSheet: View {
    @StateObject private var viewModel = SearchViewModel()
    var onSelectAlbum: (Album) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log an album")
                .font(SSTypography.headlineSmall)
                .foregroundColor(SSColors.chromeLight)

            PillSearchBar(query: $viewModel.query, placeholder: "Search albums to log...")

            if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                EmptyState(
                    title: "No matches",
                    subtitle: "Try a different search term.",
                    icon: "magnifyingglass"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.results) { album in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSelectAlbum(album)
                            } label: {
                                HStack(spacing: 12) {
                                    AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 12)
                                        .frame(width: 48, height: 48)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(album.title)
                                            .font(SSTypography.titleMedium)
                                            .foregroundColor(SSColors.chromeLight)
                                            .fontWeight(.semibold)
                                        Text(album.artist)
                                            .font(SSTypography.bodySmall)
                                            .foregroundColor(SSColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(SSColors.chromeFaint)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

private struct QuickRateCard: View {
    let album: Album
    let rating: Float
    let onRate: (Float) -> Void
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        GlassCard(cornerRadius: 20, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 14)
                        .frame(width: 124, height: 130)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSelectAlbum(album)
                        }
                    if rating > 0 {
                        Text(String(format: "%.1f", rating))
                            .font(SSTypography.labelSmall)
                            .fontWeight(.bold)
                            .foregroundColor(SSColors.accentAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(SSColors.darkBase.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(album.title)
                    .font(SSTypography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(SSColors.chromeLight)
                    .lineLimit(1)
                Text(album.artist)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
                    .lineLimit(1)
                StarRating(rating: rating, onRate: onRate, starSize: 14)
            }
        }
        .frame(width: 140)
    }
}

private struct DiaryEntryCard: View {
    let entry: RecentLogEntry
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 10) {
                AlbumArtwork(artworkUrl: entry.album.artworkUrl, colors: entry.album.artColors, cornerRadius: 14)
                    .frame(width: 56, height: 56)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelectAlbum(entry.album)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.album.title)
                        .font(SSTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(SSColors.chromeLight)
                    Text(entry.album.artist)
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                    if !entry.caption.isEmpty {
                        Text(entry.caption)
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                StarRating(rating: entry.rating, starSize: 12)
            }
        }
    }
}
