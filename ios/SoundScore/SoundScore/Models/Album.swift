import SwiftUI

struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let year: Int
    let artColors: [Color]
    var artworkUrl: String?
    var avgRating: Float
    var logCount: Int

    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
