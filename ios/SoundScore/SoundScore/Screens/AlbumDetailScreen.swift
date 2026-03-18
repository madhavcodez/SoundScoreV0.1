import SwiftUI

struct AlbumDetailScreen: View {
    let album: Album
    @StateObject private var viewModel: AlbumDetailViewModel
    @State private var showAlbumRatingSheet = false
    @State private var selectedTrack: Track?
    @State private var ratingTab: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(album: Album) {
        self.album = album
        self._viewModel = StateObject(wrappedValue: AlbumDetailViewModel(album: album))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                heroSection
                metadataSection
                ratingTabPicker
                if ratingTab == 0 {
                    rateReviewSection
                    listsContainingAlbum
                    alsoByArtist
                } else {
                    tracklistSection
                    songsBreakdown
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(AppBackdrop())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    toolbarCircle {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SSColors.chromeLight)
                    }
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: "\(album.title) by \(album.artist) — rated on SoundScore") {
                    toolbarCircle {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SSColors.chromeLight)
                    }
                }
            }
        }
        .sheet(isPresented: $showAlbumRatingSheet) {
            AlbumRatingSheet(
                album: album,
                rating: viewModel.userRating,
                onRate: { viewModel.updateAlbumRating($0) },
                onSaveReview: { SoundScoreRepository.shared.saveReview(albumId: album.id, reviewText: $0, rating: viewModel.userRating) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(SSColors.darkElevated)
        }
        .sheet(item: $selectedTrack) { track in
            SongRatingSheet(
                track: track,
                albumTitle: album.title,
                rating: viewModel.trackRatings[track.id] ?? 0,
                onRate: { viewModel.updateTrackRating(trackId: track.id, rating: $0) }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(SSColors.darkElevated)
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private func toolbarCircle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Circle()
                .fill(SSColors.darkElevated.opacity(0.8))
                .frame(width: 36, height: 36)
            Circle()
                .stroke(SSColors.glassBorder, lineWidth: 0.5)
                .frame(width: 36, height: 36)
            content()
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 24)
                .frame(height: 340)
                .frame(maxWidth: .infinity)

            LinearGradient(
                colors: [.clear, .clear, SSColors.overlayDark.opacity(0.5), SSColors.overlayDark],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(SSTypography.displayMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(album.artist)
                    .font(SSTypography.bodyLarge)
                    .foregroundColor(SSColors.chromeLight)
                Text(String(album.year))
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.chromeDim)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        HStack {
            HStack(spacing: 6) {
                StarRating(rating: album.avgRating, starSize: 22)
                Text(String(format: "%.1f", album.avgRating))
                    .font(SSTypography.headlineSmall)
                    .foregroundColor(SSColors.accentAmber)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .fixedSize()
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeManager.shared.primary)
                Text("\(album.logCount) logs")
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Segmented Tab

    private var ratingTabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Album", index: 0)
            tabButton(title: "Songs", index: 1)
        }
        .padding(3)
        .background(SSColors.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SSColors.glassBorder, lineWidth: 0.5)
        )
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                ratingTab = index
            }
        } label: {
            Text(title)
                .font(SSTypography.labelLarge)
                .fontWeight(ratingTab == index ? .bold : .regular)
                .foregroundColor(ratingTab == index ? SSColors.chromeLight : SSColors.chromeMedium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    ratingTab == index
                        ? ThemeManager.shared.primary.opacity(0.2)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tracklist

    private var tracklistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                eyebrow: "Tracklist",
                title: "\(viewModel.tracks.count) tracks",
                trailing: viewModel.isLoadingTracks ? "Loading..." : nil
            )

            if viewModel.isLoadingTracks && viewModel.tracks.isEmpty {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonView()
                        .frame(height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                    trackRow(track, isEven: index % 2 == 0)
                }
            }
        }
    }

    private func trackRow(_ track: Track, isEven: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedTrack = track
        } label: {
            HStack(spacing: 10) {
                Text("\(track.trackNumber)")
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.textTertiary)
                    .frame(width: 22, alignment: .trailing)

                Text(track.title)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .lineLimit(1)

                Spacer()

                Text(track.formattedDuration)
                    .font(SSTypography.labelSmall)
                    .foregroundColor(SSColors.textTertiary)
                    .frame(width: 40, alignment: .trailing)

                // Rating badge
                if let rating = viewModel.trackRatings[track.id], rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(SSColors.accentAmber)
                        Text(String(format: "%.1f", rating))
                            .font(SSTypography.labelSmall)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(SSColors.accentAmber.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Text("Rate")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(SSColors.chromeFaint)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isEven ? SSColors.glassBg : SSColors.glassBg.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(SSColors.feedItemBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Songs Breakdown

    private var songsBreakdown: some View {
        let ratedTracks = viewModel.tracks.filter { viewModel.trackRatings[$0.id] != nil && viewModel.trackRatings[$0.id]! > 0 }
        let avgSongRating: Float = ratedTracks.isEmpty ? 0 : ratedTracks.map { viewModel.trackRatings[$0.id]! }.reduce(0, +) / Float(ratedTracks.count)
        let highest = ratedTracks.max(by: { (viewModel.trackRatings[$0.id] ?? 0) < (viewModel.trackRatings[$1.id] ?? 0) })
        let lowest = ratedTracks.min(by: { (viewModel.trackRatings[$0.id] ?? 0) < (viewModel.trackRatings[$1.id] ?? 0) })

        return Group {
            if !ratedTracks.isEmpty {
                GlassCard(tintColor: ThemeManager.shared.primary.opacity(0.3), cornerRadius: 18, borderColor: ThemeManager.shared.primary.opacity(0.15)) {
                    VStack(spacing: 10) {
                        Text("Songs Breakdown")
                            .font(SSTypography.labelMedium)
                            .foregroundColor(SSColors.textSecondary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", avgSongRating))
                                    .font(SSTypography.headlineMedium)
                                    .foregroundColor(SSColors.accentAmber)
                                    .fontWeight(.bold)
                                Text("AVG")
                                    .font(SSTypography.labelSmall)
                                    .foregroundColor(SSColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)

                            if let h = highest {
                                VStack(spacing: 2) {
                                    Text(h.title)
                                        .font(SSTypography.titleMedium)
                                        .foregroundColor(SSColors.chromeLight)
                                        .lineLimit(1)
                                    Text("HIGHEST")
                                        .font(SSTypography.labelSmall)
                                        .foregroundColor(SSColors.accentGreen)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            if let l = lowest, lowest?.id != highest?.id {
                                VStack(spacing: 2) {
                                    Text(l.title)
                                        .font(SSTypography.titleMedium)
                                        .foregroundColor(SSColors.chromeLight)
                                        .lineLimit(1)
                                    Text("LOWEST")
                                        .font(SSTypography.labelSmall)
                                        .foregroundColor(SSColors.accentCoral)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }

                        Text("\(ratedTracks.count)/\(viewModel.tracks.count) songs rated")
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Rate & Review (tappable for modal)

    private var rateReviewSection: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showAlbumRatingSheet = true
        } label: {
            GlassCard(tintColor: ThemeManager.shared.primary.opacity(0.4), cornerRadius: 22, borderColor: ThemeManager.shared.primary.opacity(0.15)) {
                VStack(spacing: 14) {
                    HStack {
                        Text("Your Album Rating")
                            .font(SSTypography.headlineSmall)
                            .foregroundColor(SSColors.chromeLight)
                            .fontWeight(.bold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(SSColors.chromeFaint)
                    }

                    HStack {
                        StarRating(rating: viewModel.userRating, starSize: 22)
                        Spacer()
                        if viewModel.userRating > 0 {
                            Text(String(format: "%.1f / 6", viewModel.userRating))
                                .font(SSTypography.headlineSmall)
                                .foregroundColor(SSColors.accentAmber)
                                .fontWeight(.bold)
                        } else {
                            Text("Tap to rate & review")
                                .font(SSTypography.bodyMedium)
                                .foregroundColor(SSColors.textTertiary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lists

    private var listsContainingAlbum: some View {
        let matchingLists = SoundScoreRepository.shared.lists.filter { $0.albumIds.contains(album.id) }
        return Group {
            if !matchingLists.isEmpty {
                SectionHeader(eyebrow: "Your lists", title: "In your collections")
                ForEach(matchingLists) { list in
                    GlassCard(tintColor: SSColors.accentViolet.opacity(0.3), cornerRadius: 16, borderColor: SSColors.accentViolet.opacity(0.15),
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

    // MARK: - Also By Artist

    private var alsoByArtist: some View {
        let otherAlbums = SoundScoreRepository.shared.albums.filter { $0.artist == album.artist && $0.id != album.id }
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
                                        .frame(width: 120, height: 120)
                                    Text(other.title)
                                        .font(SSTypography.titleMedium)
                                        .foregroundColor(SSColors.chromeLight)
                                        .lineLimit(1)
                                }
                                .frame(width: 120)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
