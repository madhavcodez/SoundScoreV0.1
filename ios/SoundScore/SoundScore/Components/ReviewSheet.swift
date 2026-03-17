import SwiftUI

struct ReviewSheet: View {
    let album: Album
    @Binding var rating: Float
    @State private var reviewText = ""
    @Environment(\.dismiss) private var dismiss

    private let maxChars = 500

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                AlbumArtwork(artworkUrl: album.artworkUrl, colors: album.artColors, cornerRadius: 12)
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title)
                        .font(SSTypography.titleLarge)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Text(album.artist)
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                }
                Spacer()
            }

            VStack(spacing: 6) {
                Text("Your rating")
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.textTertiary)
                StarRating(rating: rating, onRate: { newRating in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    rating = newRating
                }, starSize: 26)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            ZStack(alignment: .topLeading) {
                if reviewText.isEmpty {
                    Text("What did you think? The vibe, the production, the moment you knew...")
                        .font(SSTypography.bodyMedium)
                        .foregroundColor(SSColors.chromeFaint)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $reviewText)
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeLight)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: 140)
            .background(SSColors.glassBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(SSColors.glassBorder, lineWidth: 0.5)
            )
            .onChange(of: reviewText) { _, newValue in
                if newValue.count > maxChars {
                    reviewText = String(newValue.prefix(maxChars))
                }
            }

            HStack {
                Spacer()
                Text("\(reviewText.count)/\(maxChars)")
                    .font(SSTypography.labelSmall)
                    .foregroundColor(
                        reviewText.count > maxChars - 50 ? SSColors.accentCoral : SSColors.textTertiary
                    )
            }

            SSButton(text: "Save Review") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                dismiss()
            }

            SSGhostButton(text: "Cancel") {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
