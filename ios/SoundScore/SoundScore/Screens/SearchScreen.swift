import SwiftUI

struct SearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()
    var onSelectAlbum: (Album) -> Void = { _ in }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SyncBanner(message: viewModel.syncMessage)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                ScreenHeader(title: "Discover", subtitle: "Browse by mood, genre, or find the record in your head.")

                PillSearchBar(query: $viewModel.query)

                if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    browseContent
                } else if viewModel.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(ThemeManager.shared.primary)
                        Spacer()
                    }
                    .padding(.vertical, 32)
                } else {
                    searchResults
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
        .refreshable { await SoundScoreRepository.shared.refresh() }
    }

    @ViewBuilder
    private var browseContent: some View {
        if !viewModel.chartEntries.isEmpty {
            SectionHeader(eyebrow: "Trending now", title: "Most logged this week")

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(viewModel.chartEntries.prefix(4)) { entry in
                        TrendingSearchCard(album: entry.album, rank: entry.rank)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onSelectAlbum(entry.album)
                            }
                    }
                }
                .padding(.trailing, 8)
            }
        }

        SectionHeader(eyebrow: "Browse", title: "Explore by genre")

        let rows = stride(from: 0, to: viewModel.browseGenres.count, by: 2).map { i in
            Array(viewModel.browseGenres[i..<min(i + 2, viewModel.browseGenres.count)])
        }
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
            HStack(spacing: 10) {
                ForEach(row) { genre in
                    GenreCard(genre: genre, onTap: {
                        viewModel.query = genre.name
                    })
                }
                if row.count == 1 { Spacer() }
            }
        }

        SectionHeader(eyebrow: "Charts", title: "What SoundScore is logging")

        ForEach(viewModel.chartEntries) { entry in
            TrendChartRow(entry: entry)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSelectAlbum(entry.album)
                }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if viewModel.results.isEmpty {
            EmptyState(
                title: "No results found",
                subtitle: "Try a different search term or check your spelling.",
                icon: "magnifyingglass"
            )
        } else {
            SectionHeader(eyebrow: "Results", title: "\(viewModel.results.count) matches")

            ForEach(viewModel.results) { album in
                SearchResultCard(album: album)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSelectAlbum(album)
                    }
            }
        }
    }
}

private struct TrendingSearchCard: View {
    let album: Album
    let rank: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 20)

            LinearGradient(
                colors: [.clear, SSColors.overlayDark],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text(album.artist)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(10)

            VStack {
                HStack {
                    Text("#\(rank)")
                        .font(SSTypography.labelMedium)
                        .fontWeight(.black)
                        .foregroundColor(SSColors.darkBase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ThemeManager.shared.primary.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(width: 160, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }
}

private struct GenreCard: View {
    let genre: BrowseGenre
    var onTap: () -> Void = {}

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            GlassCard(tintColor: genre.colors.last, cornerRadius: 20, borderColor: SSColors.feedItemBorder) {
                VStack(alignment: .leading, spacing: 0) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: genre.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(genre.name)
                            .font(SSTypography.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(SSColors.chromeLight)
                        Text(genre.caption)
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
        }
        .buttonStyle(.plain)
    }
}

private struct SearchResultCard: View {
    let album: Album

    var body: some View {
        GlassCard(cornerRadius: 18, borderColor: SSColors.feedItemBorder, contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) {
            HStack(spacing: 12) {
                AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 16)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(SSTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(SSColors.chromeLight)
                    Text("\(album.artist) · \(album.year)")
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StarRating(rating: album.avgRating, starSize: 12)
                    Text("\(album.logCount) logs")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(SSColors.textTertiary)
                }
            }
        }
    }
}
