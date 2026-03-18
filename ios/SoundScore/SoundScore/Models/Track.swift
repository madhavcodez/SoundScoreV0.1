import Foundation

struct Track: Identifiable, Hashable {
    let id: String
    let albumId: String
    let title: String
    let trackNumber: Int
    let durationMs: Int?
    let spotifyId: String?

    var formattedDuration: String {
        guard let ms = durationMs else { return "--:--" }
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
