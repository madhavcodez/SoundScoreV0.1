import SwiftUI

struct PillSearchBar: View {
    @Binding var query: String
    var placeholder: String = "Search albums, artists..."

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SSColors.chromeDim)

            TextField("", text: $query, prompt: Text(placeholder).foregroundColor(SSColors.chromeDim))
                .font(SSTypography.bodyLarge)
                .foregroundColor(SSColors.chromeLight)
                .tint(SSColors.accentGreen)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SSColors.chromeDim)
                }
            } else {
                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SSColors.chromeDim)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(SSColors.glassFrosted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(SSColors.glassBorder, lineWidth: 0.5)
        )
    }
}
