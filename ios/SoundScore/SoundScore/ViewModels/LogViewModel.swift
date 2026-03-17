import Foundation
import Combine

class LogViewModel: ObservableObject {
    @Published var quickLogAlbums: [Album]
    @Published var ratings: [String: Float]
    @Published var summaryStats: [LogSummaryStat]
    @Published var recentLogs: [RecentLogEntry]
    @Published var syncMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.quickLogAlbums = repo.albums
        self.ratings = repo.ratings
        self.summaryStats = buildLogSummaryStats(repo.ratings)
        self.recentLogs = buildRecentLogs(repo.albums, repo.ratings)
        self.syncMessage = repo.syncMessage

        repo.$albums
            .receive(on: RunLoop.main)
            .assign(to: &$quickLogAlbums)

        repo.$ratings
            .receive(on: RunLoop.main)
            .assign(to: &$ratings)

        repo.$ratings
            .receive(on: RunLoop.main)
            .map { buildLogSummaryStats($0) }
            .assign(to: &$summaryStats)

        Publishers.CombineLatest(repo.$albums, repo.$ratings)
            .receive(on: RunLoop.main)
            .map { buildRecentLogs($0, $1) }
            .assign(to: &$recentLogs)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)
    }

    func updateRating(albumId: String, rating: Float) {
        SoundScoreRepository.shared.updateRating(albumId: albumId, rating: rating)
    }
}
