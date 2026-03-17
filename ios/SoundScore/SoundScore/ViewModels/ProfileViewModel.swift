import Foundation

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var metrics: [ProfileMetric]
    @Published var favoriteAlbums: [Album]
    @Published var notificationPreferences: NotificationPreferences
    @Published var latestRecap: WeeklyRecap?
    @Published var syncMessage: String?

    init() {
        let p = SeedData.myProfile
        self.profile = p
        self.metrics = buildProfileMetrics(p)
        self.favoriteAlbums = buildFavoriteAlbums(p)
        self.notificationPreferences = SeedData.defaultNotificationPreferences
        self.latestRecap = SeedData.initialRecap
        self.syncMessage = nil
    }
}
