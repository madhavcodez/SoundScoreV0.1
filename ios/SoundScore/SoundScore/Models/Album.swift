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
    var spotifyId: String?
    var genres: [String]

    init(id: String, title: String, artist: String, year: Int, artColors: [Color],
         artworkUrl: String? = nil, avgRating: Float = 0, logCount: Int = 0,
         spotifyId: String? = nil, genres: [String] = []) {
        self.id = id
        self.title = title
        self.artist = artist
        self.year = year
        self.artColors = artColors
        self.artworkUrl = artworkUrl
        self.avgRating = avgRating
        self.logCount = logCount
        self.spotifyId = spotifyId
        self.genres = genres
    }

    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
