import SwiftUI

struct SongRatingSheet: View {
    let track: Track
    let albumTitle: String
    @State var rating: Float
    var onRate: (Float) -> Void
    @State private var note: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Track header
            HStack(spacing: 12) {
                Text("\(track.trackNumber)")
                    .font(SSTypography.labelMedium)
                    .fontWeight(.bold)
                    .foregroundColor(SSColors.chromeLight)
                    .frame(width: 28, height: 28)
                    .background(ThemeManager.shared.primary.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(SSTypography.headlineSmall)
                        .foregroundColor(SSColors.chromeLight)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    Text(albumTitle)
                        .font(SSTypography.bodySmall)
                        .foregroundColor(SSColors.textSecondary)
                }

                Spacer()

                Text(track.formattedDuration)
                    .font(SSTypography.labelMedium)
                    .foregroundColor(SSColors.textTertiary)
            }

            // Star rating
            VStack(spacing: 8) {
                StarRating(rating: rating, onRate: { newRating in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    rating = newRating
                }, starSize: 28, maxStars: 6)

                if rating > 0 {
                    Text(String(format: "%.1f / 6", rating))
                        .font(SSTypography.headlineSmall)
                        .foregroundColor(SSColors.accentAmber)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical, 4)

            // Note field
            TextField("Add a note about this track...", text: $note, axis: .vertical)
                .font(SSTypography.bodyMedium)
                .foregroundColor(SSColors.chromeLight)
                .lineLimit(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(SSColors.glassBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SSColors.glassBorder, lineWidth: 0.5)
                )

            HStack {
                Text("\(note.count)/200")
                    .font(SSTypography.labelSmall)
                    .foregroundColor(note.count > 200 ? SSColors.accentCoral : SSColors.textTertiary)
                Spacer()
            }
            .padding(.top, -12)

            // Save button
            SSButton(text: "Save") {
                onRate(rating)
                dismiss()
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(SSTypography.bodyMedium)
                    .foregroundColor(SSColors.chromeMedium)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
