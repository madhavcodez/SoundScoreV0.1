import Foundation

class LogViewModel: ObservableObject {
    @Published var quickLogAlbums: [Album]
    @Published var ratings: [String: Float]
    @Published var summaryStats: [LogSummaryStat]
    @Published var recentLogs: [RecentLogEntry]
    @Published var syncMessage: String?

    init() {
        let albums = SeedData.albums
        let ratings = SeedData.logInitialRatings
        self.quickLogAlbums = albums
        self.ratings = ratings
        self.summaryStats = buildLogSummaryStats(ratings)
        self.recentLogs = buildRecentLogs(albums, ratings)
        self.syncMessage = nil
    }

    func updateRating(albumId: String, rating: Float) {
        ratings[albumId] = rating
        summaryStats = buildLogSummaryStats(ratings)
        recentLogs = buildRecentLogs(quickLogAlbums, ratings)
    }
}
