import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var metrics: [ProfileMetric]
    @Published var favoriteAlbums: [Album]
    @Published var notificationPreferences: NotificationPreferences
    @Published var latestRecap: WeeklyRecap?
    @Published var syncMessage: String?
    @Published var isLoading: Bool
    @Published var recentActivity: [FeedItem]
    @Published var errorMessage: String?
    @Published var showExportSuccess = false
    @Published var showDeleteConfirm = false

    init() {
        let repo = SoundScoreRepository.shared
        self.profile = repo.profile
        self.metrics = buildProfileMetrics(repo.profile)
        self.favoriteAlbums = buildFavoriteAlbums(repo.profile)
        self.notificationPreferences = SeedData.defaultNotificationPreferences
        self.latestRecap = repo.latestRecap
        self.syncMessage = repo.syncMessage
        self.isLoading = repo.isLoading
        self.errorMessage = repo.errorMessage
        self.recentActivity = Array(repo.feedItems.prefix(3))

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

        repo.$latestRecap
            .receive(on: RunLoop.main)
            .assign(to: &$latestRecap)

        repo.$syncMessage
            .receive(on: RunLoop.main)
            .assign(to: &$syncMessage)

        repo.$isLoading
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)

        repo.$errorMessage
            .receive(on: RunLoop.main)
            .assign(to: &$errorMessage)

        repo.$feedItems
            .receive(on: RunLoop.main)
            .map { Array($0.prefix(3)) }
            .assign(to: &$recentActivity)
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
