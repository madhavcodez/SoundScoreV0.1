import SwiftUI

struct MosaicCover: View {
    let albums: [Album]
    var cornerRadius: CGFloat = 14
    var size: CGFloat = 110

    var body: some View {
        let cellSize = (size - 4) / 2

        LazyVGrid(columns: [GridItem(.fixed(cellSize), spacing: 4), GridItem(.fixed(cellSize), spacing: 4)], spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                if index < albums.count {
                    AlbumArtwork(
                        artworkUrl: albums[index].artworkUrl,
                        colors: albums[index].artColors,
                        cornerRadius: index == 0 ? cornerRadius * 0.5 : cornerRadius * 0.5
                    )
                    .frame(width: cellSize, height: cellSize)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius * 0.5)
                        .fill(SSColors.glassBg)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
