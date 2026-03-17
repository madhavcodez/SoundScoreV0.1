import SwiftUI

struct LogSummaryStat {
    let value: String
    let label: String
    let caption: String
}

struct RecentLogEntry: Identifiable {
    var id: String { "\(album.id)-\(timeLabel)" }
    let album: Album
    let rating: Float
    let dateLabel: String
    let timeLabel: String
    let caption: String
}

struct BrowseGenre: Identifiable {
    var id: String { name }
    let name: String
    let caption: String
    let colors: [Color]
}

struct ChartEntry: Identifiable {
    var id: String { album.id }
    let rank: Int
    let album: Album
    let movementLabel: String
}

struct ListShowcase: Identifiable {
    var id: String { list.id }
    let list: UserList
    let coverAlbums: [Album]
}

struct ProfileMetric: Identifiable {
    var id: String { label }
    let value: String
    let label: String
}

func buildTrendingAlbums(_ albums: [Album]) -> [Album] {
    albums.sorted { $0.logCount > $1.logCount }
}

func buildLogSummaryStats(_ ratings: [String: Float]) -> [LogSummaryStat] {
    let average = ratings.isEmpty ? 0 : ratings.values.reduce(0, +) / Float(ratings.count)
    let weekLogs = ratings.count
    let streak = min(ratings.count + 2, 9)
    return [
        LogSummaryStat(value: "\(weekLogs)", label: "This week", caption: "New logs"),
        LogSummaryStat(value: String(format: "%.1f★", average), label: "Average", caption: "Your current pace"),
        LogSummaryStat(value: "\(streak) d", label: "Streak", caption: "Listening every day"),
    ]
}

func buildRecentLogs(_ albums: [Album], _ ratings: [String: Float]) -> [RecentLogEntry] {
    let moments: [(String, String, String)] = [
        ("Today", "11:48 PM", "Late-night replay. Worth the full write-up."),
        ("Yesterday", "7:12 PM", "Instant favorite chorus. Logged before dinner."),
        ("Mar 11", "9:03 AM", "Sharp production details on the second listen."),
        ("Mar 09", "6:41 PM", "Saved for the weekend drive and it landed."),
    ]
    return albums
        .sorted { (ratings[$0.id] ?? 0) > (ratings[$1.id] ?? 0) }
        .prefix(moments.count)
        .enumerated()
        .map { index, album in
            let (date, time, caption) = moments[index]
            return RecentLogEntry(
                album: album,
                rating: ratings[album.id] ?? album.avgRating,
                dateLabel: date,
                timeLabel: time,
                caption: caption
            )
        }
}

func buildBrowseGenres() -> [BrowseGenre] {
    [
        BrowseGenre(name: "Alt Rap", caption: "Dense bars, stranger palettes", colors: AlbumColors.forest),
        BrowseGenre(name: "Night Pop", caption: "Glossy hooks with a bite", colors: AlbumColors.rose),
        BrowseGenre(name: "Leftfield R&B", caption: "Warm low end, sharp edges", colors: AlbumColors.lagoon),
        BrowseGenre(name: "Indie Mutations", caption: "Guitars that still feel digital", colors: AlbumColors.orchid),
    ]
}

func buildChartEntries(_ albums: [Album]) -> [ChartEntry] {
    let labels = ["+18%", "+12%", "+9%", "+6%", "+4%"]
    return albums
        .sorted { $0.logCount > $1.logCount }
        .prefix(labels.count)
        .enumerated()
        .map { index, album in
            ChartEntry(rank: index + 1, album: album, movementLabel: labels[index])
        }
}

func resolveListShowcases(_ lists: [UserList], _ albums: [Album]) -> [ListShowcase] {
    lists.map { list in
        let covers = list.albumIds.compactMap { id in albums.first { $0.id == id } }.prefix(4)
        return ListShowcase(list: list, coverAlbums: Array(covers))
    }
}

func buildProfileMetrics(_ profile: UserProfile) -> [ProfileMetric] {
    [
        ProfileMetric(value: "\(profile.albumsCount)", label: "Albums"),
        ProfileMetric(value: "\(profile.listCount)", label: "Lists"),
        ProfileMetric(value: "\(profile.followingCount)", label: "Following"),
        ProfileMetric(value: "\(profile.followersCount)", label: "Followers"),
    ]
}

func buildFavoriteAlbums(_ profile: UserProfile) -> [Album] {
    Array(profile.favoriteAlbums.prefix(6))
}
