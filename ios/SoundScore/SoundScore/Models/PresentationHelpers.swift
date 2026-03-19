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

struct TrendingSong: Identifiable {
    var id: String { track.id }
    let track: Track
    let album: Album
    let avgRating: Float
}

struct RecentSongLogEntry: Identifiable {
    var id: String { track.id }
    let track: Track
    let album: Album
    let rating: Float
    let dateLabel: String
}

// MARK: - Taste DNA

struct TasteDNA {
    let topGenres: [(genre: String, weight: Float)]
    let ratingStyle: String
    let decadeBreakdown: [(decade: String, pct: Float)]
    let diversityScore: Float
    let topArtists: [String]
    let controversialPick: (album: String, rating: Float, communityAvg: Float)?
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

func buildTrendingSongs(
    tracksByAlbum: [String: [Track]],
    trackRatings: [String: Float],
    albums: [Album]
) -> [TrendingSong] {
    var songs: [TrendingSong] = []
    for (albumId, tracks) in tracksByAlbum {
        guard let album = albums.first(where: { $0.id == albumId }) else { continue }
        for track in tracks {
            let rating = trackRatings[track.id] ?? 0
            if rating > 0 {
                songs.append(TrendingSong(track: track, album: album, avgRating: rating))
            }
        }
    }
    // If no rated tracks yet, use album ratings as proxy for top tracks
    if songs.isEmpty {
        for (albumId, tracks) in tracksByAlbum {
            guard let album = albums.first(where: { $0.id == albumId }) else { continue }
            for track in tracks.prefix(2) {
                songs.append(TrendingSong(track: track, album: album, avgRating: album.avgRating))
            }
        }
    }
    return songs.sorted { $0.avgRating > $1.avgRating }
}

func buildRecentSongLogs(
    tracksByAlbum: [String: [Track]],
    trackRatings: [String: Float],
    albums: [Album]
) -> [RecentSongLogEntry] {
    let moments = ["Today", "Yesterday", "Mar 16", "Mar 15", "Mar 14", "Mar 13"]
    var entries: [RecentSongLogEntry] = []
    let ratedTracks = trackRatings.sorted { $0.value > $1.value }

    for (index, (trackId, rating)) in ratedTracks.prefix(moments.count).enumerated() {
        for (albumId, tracks) in tracksByAlbum {
            if let track = tracks.first(where: { $0.id == trackId }),
               let album = albums.first(where: { $0.id == albumId }) {
                entries.append(RecentSongLogEntry(
                    track: track, album: album,
                    rating: rating, dateLabel: moments[index]
                ))
                break
            }
        }
    }

    // If no rated tracks, show top tracks from rated albums
    if entries.isEmpty {
        for (albumId, tracks) in tracksByAlbum {
            guard let album = albums.first(where: { $0.id == albumId }) else { continue }
            for track in tracks.prefix(1) {
                entries.append(RecentSongLogEntry(
                    track: track, album: album,
                    rating: album.avgRating,
                    dateLabel: moments[min(entries.count, moments.count - 1)]
                ))
            }
            if entries.count >= 6 { break }
        }
    }
    return entries
}

func buildTasteDNA(albums: [Album], ratings: [String: Float]) -> TasteDNA {
    // Genre aggregation weighted by rating
    var genreWeights: [String: Float] = [:]
    var totalWeight: Float = 0
    for (albumId, rating) in ratings {
        guard let album = albums.first(where: { $0.id == albumId }) else { continue }
        for genre in album.genres {
            genreWeights[genre, default: 0] += rating
            totalWeight += rating
        }
    }
    let topGenres: [(String, Float)] = genreWeights
        .map { (genre: $0.key, weight: totalWeight > 0 ? $0.value / totalWeight : 0) }
        .sorted { $0.1 > $1.1 }
        .prefix(6)
        .map { ($0.0, $0.1) }

    // Rating style
    let avgRating = ratings.isEmpty ? 0 : ratings.values.reduce(0, +) / Float(ratings.count)
    let ratingStyle: String
    switch avgRating {
    case ..<3.0: ratingStyle = "Harsh Critic"
    case 3.0..<4.0: ratingStyle = "Fair Judge"
    default: ratingStyle = "Generous Rater"
    }

    // Decade breakdown
    var decadeCounts: [String: Int] = [:]
    for (albumId, _) in ratings {
        guard let album = albums.first(where: { $0.id == albumId }) else { continue }
        let decade = "\(album.year / 10 * 10)s"
        decadeCounts[decade, default: 0] += 1
    }
    let totalRated = Float(max(ratings.count, 1))
    let decadeBreakdown = decadeCounts
        .map { (decade: $0.key, pct: Float($0.value) / totalRated) }
        .sorted { $0.pct > $1.pct }

    // Diversity score
    let uniqueGenres = Set(albums.filter { ratings[$0.id] != nil }.flatMap(\.genres))
    let diversityScore = min(Float(uniqueGenres.count) / 15.0, 1.0)

    // Top artists
    var artistCounts: [String: Int] = [:]
    for (albumId, _) in ratings {
        guard let album = albums.first(where: { $0.id == albumId }) else { continue }
        artistCounts[album.artist, default: 0] += 1
    }
    let topArtists = artistCounts.sorted { $0.value > $1.value }.prefix(5).map(\.key)

    // Controversial pick
    var controversialPick: (album: String, rating: Float, communityAvg: Float)?
    var maxDeviation: Float = 0
    for (albumId, userRating) in ratings {
        guard let album = albums.first(where: { $0.id == albumId }) else { continue }
        let deviation = abs(userRating - album.avgRating)
        if deviation > maxDeviation && deviation > 1.0 {
            maxDeviation = deviation
            controversialPick = (album: album.title, rating: userRating, communityAvg: album.avgRating)
        }
    }

    return TasteDNA(
        topGenres: topGenres,
        ratingStyle: ratingStyle,
        decadeBreakdown: decadeBreakdown,
        diversityScore: diversityScore,
        topArtists: topArtists,
        controversialPick: controversialPick
    )
}
