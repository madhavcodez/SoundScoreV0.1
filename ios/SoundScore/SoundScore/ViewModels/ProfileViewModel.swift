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
    @Published var tasteDNA: TasteDNA?
    @Published var soundDNASummary: String?
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
        self.tasteDNA = buildTasteDNA(albums: repo.albums, ratings: repo.ratings)

        // Load cached Sound DNA summary
        self.soundDNASummary = UserDefaults.standard.string(forKey: "ss_soundDNASummary")

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

        Publishers.CombineLatest(repo.$albums, repo.$ratings)
            .receive(on: RunLoop.main)
            .map { buildTasteDNA(albums: $0, ratings: $1) }
            .assign(to: &$tasteDNA)

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

    func generateSoundDNA() {
        guard soundDNASummary == nil, let dna = tasteDNA, !dna.topGenres.isEmpty else { return }
        guard !Secrets.geminiAPIKey.isEmpty else { return }

        let genreList = dna.topGenres.prefix(5).map(\.genre).joined(separator: ", ")
        let prompt = "Based on these music genres: \(genreList), rating style: \(dna.ratingStyle), diversity: \(String(format: "%.1f", dna.diversityScore)). Generate exactly 3 evocative words (adjective noun noun or adjective adjective noun) that capture this listener's sonic identity. Example: 'Chaotic Midnight Energy' or 'Velvet Bass Cathedral'. Just the 3 words, nothing else."

        Task {
            do {
                let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(Secrets.geminiAPIKey)")!
                let body: [String: Any] = [
                    "contents": [["role": "user", "parts": [["text": prompt]]]],
                    "generationConfig": ["temperature": 1.0, "maxOutputTokens": 20],
                ]
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, _) = try await URLSession.shared.data(for: request)
                struct GR: Decodable { let candidates: [GC]? }
                struct GC: Decodable { let content: GCo? }
                struct GCo: Decodable { let parts: [GP]? }
                struct GP: Decodable { let text: String? }
                let decoded = try JSONDecoder().decode(GR.self, from: data)
                if let text = decoded.candidates?.first?.content?.parts?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    await MainActor.run {
                        self.soundDNASummary = text
                        UserDefaults.standard.set(text, forKey: "ss_soundDNASummary")
                    }
                }
            } catch {
                #if DEBUG
                print("[SoundDNA] Generation error: \(error)")
                #endif
            }
        }
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
