import SwiftUI

struct AlbumRatingSheet: View {
    let album: Album
    @State var rating: Float
    var onRate: (Float) -> Void
    var onSaveReview: (String) -> Void
    @State private var reviewText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Album header
                HStack(spacing: 14) {
                    AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 16)
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(album.title)
                            .font(SSTypography.headlineSmall)
                            .foregroundColor(SSColors.chromeLight)
                            .fontWeight(.bold)
                            .lineLimit(2)
                        Text(album.artist)
                            .font(SSTypography.bodyMedium)
                            .foregroundColor(SSColors.textSecondary)
                        Text(String(album.year))
                            .font(SSTypography.bodySmall)
                            .foregroundColor(SSColors.textTertiary)
                    }

                    Spacer()
                }

                // Rating
                VStack(spacing: 10) {
                    StarRating(rating: rating, onRate: { newRating in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        rating = newRating
                    }, starSize: 32, maxStars: 6)

                    if rating > 0 {
                        Text(String(format: "%.1f / 6", rating))
                            .font(SSTypography.headlineMedium)
                            .foregroundColor(SSColors.accentAmber)
                            .fontWeight(.bold)
                    } else {
                        Text("Tap to rate")
                            .font(SSTypography.bodyMedium)
                            .foregroundColor(SSColors.textTertiary)
                    }
                }
                .padding(.vertical, 8)

                // Review
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(SSTypography.labelMedium)
                        .foregroundColor(SSColors.textSecondary)
                        .textCase(.uppercase)

                    TextEditor(text: $reviewText)
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.chromeLight)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100, maxHeight: 200)
                        .padding(12)
                        .background(SSColors.glassBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SSColors.glassBorder, lineWidth: 0.5)
                        )

                    HStack {
                        Text("\(reviewText.count)/500")
                            .font(SSTypography.labelSmall)
                            .foregroundColor(reviewText.count > 500 ? SSColors.accentCoral : SSColors.textTertiary)
                        Spacer()
                    }
                }

                // Save
                SSButton(text: "Save") {
                    onRate(rating)
                    if !reviewText.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSaveReview(reviewText)
                    }
                    dismiss()
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.chromeMedium)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }
}
