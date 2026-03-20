import SwiftUI

// MARK: - Review Draft Card

struct CadenceReviewCard: View {
    let albumId: String
    let albumTitle: String
    let artworkUrl: String?
    let artColors: [Color]
    @State var reviewText: String
    @State var rating: Float
    var onSend: (String, Float) -> Void
    var onDiscard: () -> Void

    @State private var isEditing = false
    @State private var sent = false

    var body: some View {
        if sent {
            sentConfirmation
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                AlbumArtwork(artworkUrl: artworkUrl, colors: artColors, cornerRadius: 10)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review Draft")
                        .font(SSTypography.labelSmall)
                        .foregroundColor(ThemeManager.shared.primary)
                        .textCase(.uppercase)
                    Text(albumTitle)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                Spacer()
                StarRating(rating: rating, onRate: isEditing ? { rating = $0 } : nil, starSize: 12)
            }

            // Review text
            if isEditing {
                TextEditor(text: $reviewText)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 140)
                    .padding(10)
                    .background(SSColors.glassBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeManager.shared.primary.opacity(0.3), lineWidth: 1))
            } else {
                Text(reviewText)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeLight.opacity(0.9))
                    .italic()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SSColors.glassBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        sent = true
                    }
                    onSend(reviewText, rating)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                        Text("Send")
                            .font(SSTypography.labelLarge)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(SSColors.darkBase)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ThemeManager.shared.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isEditing ? "checkmark" : "pencil")
                            .font(.system(size: 12))
                        Text(isEditing ? "Done" : "Edit")
                            .font(SSTypography.labelMedium)
                    }
                    .foregroundColor(SSColors.chromeLight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(SSColors.glassBg)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(SSColors.glassBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    onDiscard()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.chromeFaint)
                        .frame(width: 32, height: 32)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ThemeManager.shared.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var sentConfirmation: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(SSColors.accentGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Review saved")
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                Text(albumTitle)
                    .font(SSTypography.bodySmall)
                    .foregroundColor(SSColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(SSColors.accentGreen.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SSColors.accentGreen.opacity(0.3), lineWidth: 1))
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Batch Rating Card

struct CadenceBatchRatingCard: View {
    let ratings: [CadenceAction]
    var onApplyAll: ([CadenceAction]) -> Void
    var onDiscard: () -> Void

    @State private var appliedIndices: Set<Int> = []
    @State private var allApplied = false

    var body: some View {
        if allApplied {
            appliedConfirmation
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(SSColors.accentAmber)
                Text("Batch Ratings")
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                Spacer()
                Text("\(ratings.count) albums")
                    .font(SSTypography.labelSmall)
                    .foregroundColor(SSColors.textTertiary)
            }

            ForEach(Array(ratings.enumerated()), id: \.element.id) { index, action in
                HStack(spacing: 10) {
                    let album = SoundScoreRepository.shared.albums.first { $0.id == action.albumId }
                    AlbumArtwork(
                        artworkUrl: album?.artworkUrl,
                        colors: album?.artColors ?? AlbumColors.forest,
                        cornerRadius: 8
                    )
                    .frame(width: 36, height: 36)

                    Text(action.albumTitle)
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .lineLimit(1)

                    Spacer()

                    if appliedIndices.contains(index) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SSColors.accentGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("\(action.value)/6")
                            .font(SSTypography.labelLarge)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.bold)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    applyAllWithAnimation()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 14))
                        Text("Apply All")
                            .font(SSTypography.labelLarge)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(SSColors.darkBase)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(SSColors.accentAmber)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Button { onDiscard() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.chromeFaint)
                        .frame(width: 32, height: 32)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(SSColors.accentAmber.opacity(0.3), lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var appliedConfirmation: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(SSColors.accentGreen)
            Text("\(ratings.count) albums rated")
                .font(SSTypography.titleMedium)
                .foregroundColor(SSColors.chromeLight)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(SSColors.accentGreen.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SSColors.accentGreen.opacity(0.3), lineWidth: 1))
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func applyAllWithAnimation() {
        for (index, _) in ratings.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    appliedIndices.insert(index)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(ratings.count) * 0.3 + 0.3) {
            onApplyAll(ratings)
            withAnimation(.spring(response: 0.4)) {
                allApplied = true
            }
        }
    }
}

// MARK: - Search Results Card

struct CadenceSearchResultsCard: View {
    let results: [SpotifyAlbumResult]
    var onAdd: (SpotifyAlbumResult) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ThemeManager.shared.primary)
                Text("Found Albums")
                    .font(SSTypography.titleMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.bold)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SSColors.chromeFaint)
                        .frame(width: 28, height: 28)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(results.enumerated()), id: \.element.spotifyId) { _, result in
                        VStack(spacing: 8) {
                            AsyncImage(url: URL(string: result.artworkUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    LinearGradient(
                                        colors: AlbumColors.forest,
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            Text(result.title)
                                .font(SSTypography.labelMedium)
                                .foregroundColor(SSColors.chromeLight)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .frame(width: 100)

                            Text(result.artist)
                                .font(SSTypography.labelSmall)
                                .foregroundColor(SSColors.textSecondary)
                                .lineLimit(1)
                                .frame(width: 100)

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onAdd(result)
                            } label: {
                                Text("Add")
                                    .font(SSTypography.labelSmall)
                                    .fontWeight(.bold)
                                    .foregroundColor(SSColors.darkBase)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(ThemeManager.shared.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ThemeManager.shared.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Quick Rate Card

struct CadenceQuickRateCard: View {
    let action: CadenceAction
    var onConfirm: (CadenceAction) -> Void
    var onDiscard: () -> Void

    @State private var confirmed = false

    var body: some View {
        if confirmed {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(SSColors.accentAmber)
                Text("Rated \(action.albumTitle) → \(action.value)/6")
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(SSColors.accentAmber.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SSColors.accentAmber.opacity(0.3), lineWidth: 1))
            .transition(.scale.combined(with: .opacity))
        } else {
            HStack(spacing: 10) {
                let album = SoundScoreRepository.shared.albums.first { $0.id == action.albumId }
                AlbumArtwork(
                    artworkUrl: album?.artworkUrl,
                    colors: album?.artColors ?? AlbumColors.forest,
                    cornerRadius: 10
                )
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.albumTitle)
                        .font(SSTypography.titleMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    StarRating(rating: Float(action.value) ?? 0, starSize: 12)
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        confirmed = true
                    }
                    onConfirm(action)
                } label: {
                    Text("Confirm")
                        .font(SSTypography.labelMedium)
                        .fontWeight(.bold)
                        .foregroundColor(SSColors.darkBase)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(SSColors.accentAmber)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button { onDiscard() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(SSColors.chromeFaint)
                        .frame(width: 28, height: 28)
                        .background(SSColors.glassBg)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(SSColors.accentAmber.opacity(0.3), lineWidth: 1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
