import SwiftUI

struct AlbumArtwork: View {
    let artworkUrl: String?
    let colors: [Color]
    var cornerRadius: CGFloat = 16

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let url = artworkUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            shimmerOverlay(size: geo.size)
                        }
                    }
                } else {
                    shimmerOverlay(size: geo.size)
                }

                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.black.opacity(0.22)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func shimmerOverlay(size: CGSize) -> some View {
        Rectangle()
            .fill(Color.clear)
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white.opacity(0.08), Color.white.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: size.width * 0.6)
                .offset(x: shimmerOffset)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                    shimmerOffset = size.width + 200
                }
            }
    }
}
