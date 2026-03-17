import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var metrics: [ProfileMetric]
    @Published var favoriteAlbums: [Album]
    @Published var notificationPreferences: NotificationPreferences
    @Published var latestRecap: WeeklyRecap?
    @Published var syncMessage: String?

    init() {
        let repo = SoundScoreRepository.shared
        self.profile = repo.profile
        self.metrics = buildProfileMetrics(repo.profile)
        self.favoriteAlbums = buildFavoriteAlbums(repo.profile)
        self.notificationPreferences = SeedData.defaultNotificationPreferences
        self.latestRecap = repo.latestRecap
        self.syncMessage = repo.syncMessage

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
    }
}
