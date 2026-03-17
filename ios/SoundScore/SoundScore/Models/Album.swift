import SwiftUI

struct Album: Identifiable {
    let id: String
    let title: String
    let artist: String
    let year: Int
    let artColors: [Color]
    var artworkUrl: String?
    var avgRating: Float
    var logCount: Int
}
