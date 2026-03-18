import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var metrics: [ProfileMetric]
    @Published var favoriteAlbums: [Album]
    @Published var genres: [String]
    @Published var notificationPreferences: NotificationPreferences
    @Published var recap: WeeklyRecap?
    @Published var recentActivity: [RecentLogEntry]
    @Published var syncMessage: String?
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published var showExportSuccess = false
    @Published var showDeleteConfirm = false

    var handle: String { profile?.handle ?? "@user" }
    var bio: String { profile?.bio ?? "" }

    init() {
        let repo = SoundScoreRepository.shared
        self.profile = repo.profile
        self.metrics = buildProfileMetrics(repo.profile)
        self.favoriteAlbums = buildFavoriteAlbums(repo.profile)
        self.genres = repo.profile.genres
        self.notificationPreferences = SeedData.defaultNotificationPreferences
        self.recap = repo.latestRecap
        self.syncMessage = repo.syncMessage
        self.isLoading = repo.isLoading
        self.errorMessage = repo.errorMessage
        self.recentActivity = buildRecentLogs(repo.albums, repo.ratings)

        repo.$profile
            .receive(on: RunLoop.main)
            .map { Optional($0) }
            .assign(to: &$profile)

        repo.$profile
            .receive(on: RunLoop.main)
            .map { buildProfileMetrics($0) }
            .assign(to: &$metrics)

        repo.$profile
            .receive(on: RunLoop.main)
            .map { buildFavoriteAlbums($0) }
            .assign(to: &$favoriteAlbums)

        repo.$profile
            .receive(on: RunLoop.main)
            .map { $0.genres }
            .assign(to: &$genres)

        repo.$latestRecap
            .receive(on: RunLoop.main)
            .assign(to: &$recap)

        Publishers.CombineLatest(repo.$albums, repo.$ratings)
            .receive(on: RunLoop.main)
            .map { buildRecentLogs($0, $1) }
            .assign(to: &$recentActivity)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)

        repo.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)

        repo.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)
    }

    func shareProfileText() -> String {
        guard let profile else { return "" }
        return "Check out my SoundScore profile: \(profile.handle)\n\(profile.albumsCount) albums logged · avg \(String(format: "%.1f", profile.avgRating))★"
    }

    func saveNotificationPreferences() {
        SoundScoreRepository.shared.outboxStore.enqueue(OutboxOperation(
            type: .updateNotificationPreferences,
            payload: [
                "socialEnabled": String(notificationPreferences.socialEnabled),
                "recapEnabled": String(notificationPreferences.recapEnabled),
                "commentEnabled": String(notificationPreferences.commentEnabled),
                "reactionEnabled": String(notificationPreferences.reactionEnabled),
                "quietHoursStart": String(notificationPreferences.quietHoursStart),
                "quietHoursEnd": String(notificationPreferences.quietHoursEnd),
            ]
        ))
        Task { await SoundScoreRepository.shared.syncOutbox() }
    }
}
