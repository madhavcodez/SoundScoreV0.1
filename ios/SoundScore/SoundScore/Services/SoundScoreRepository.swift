import Foundation
import SwiftUI
import Combine

class SoundScoreRepository: ObservableObject {
    static let shared = SoundScoreRepository()

    @Published var albums: [Album]
    @Published var feedItems: [FeedItem]
    @Published var profile: UserProfile
    @Published var ratings: [String: Float]
    @Published var tracksByAlbum: [String: [Track]]
    @Published var trackRatings: [String: Float]
    @Published var lists: [UserList]
    @Published var latestRecap: WeeklyRecap?
    @Published var syncMessage: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let api = SoundScoreAPI()
    let outboxStore = InMemoryOutboxStore()
    private lazy var outboxEngine = OutboxSyncEngine(store: outboxStore)

    private init() {
        self.albums = SeedData.albums
        self.feedItems = SeedData.feedItems
        self.profile = SeedData.myProfile
        self.ratings = SeedData.logInitialRatings
        self.tracksByAlbum = SeedData.sampleTracks
        self.trackRatings = [:]
        self.lists = SeedData.initialLists
        self.latestRecap = SeedData.initialRecap
        self.syncMessage = nil
        Task { await enrichAlbumsWithArtwork() }
    }

    // MARK: - Spotify Artwork Enrichment

    private func enrichAlbumsWithArtwork() async {
        let albumsNeedingArt = albums.filter { $0.artworkUrl == nil }
        guard !albumsNeedingArt.isEmpty else { return }

        for album in albumsNeedingArt {
            if let url = await SpotifyService.shared.artworkUrl(title: album.title, artist: album.artist) {
                await MainActor.run {
                    if let index = self.albums.firstIndex(where: { $0.id == album.id }) {
                        self.albums[index].artworkUrl = url
                    }
                    // Also update artwork in feedItems that reference this album
                    for i in self.feedItems.indices where self.feedItems[i].album.id == album.id {
                        self.feedItems[i].album.artworkUrl = url
                    }
                }
            }
            // Spotify rate limit: 1 request per ~100ms is safe with client credentials
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }

    // MARK: - Refresh from API

    func refresh() async {
        guard AuthManager.shared.isAuthenticated else { return }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let remoteAlbums = try await api.searchAlbums(query: "")
            let mapped = remoteAlbums.items.map { mapAlbum($0) }

            let remoteProfile = try await api.getProfile(handle: "")

            let remoteFeed = try await api.getFeed()
            let feedMapped = remoteFeed.items.map { mapFeedItem($0) }

            await MainActor.run {
                if !mapped.isEmpty { self.albums = mapped }
                self.profile = UserProfile(
                    handle: remoteProfile.handle,
                    bio: remoteProfile.bio,
                    logCount: remoteProfile.logCount,
                    reviewCount: remoteProfile.reviewCount,
                    listCount: remoteProfile.listCount,
                    topAlbums: self.profile.topAlbums,
                    genres: self.profile.genres,
                    avgRating: remoteProfile.avgRating,
                    albumsCount: remoteProfile.logCount,
                    followingCount: self.profile.followingCount,
                    followersCount: self.profile.followersCount,
                    favoriteAlbums: self.profile.favoriteAlbums
                )
                self.feedItems = feedMapped.isEmpty ? self.feedItems : feedMapped
                self.syncMessage = nil
            }

            if let recap = try? await api.getWeeklyRecap() {
                await MainActor.run {
                    self.latestRecap = WeeklyRecap(
                        id: recap.id,
                        weekStart: recap.weekStart,
                        weekEnd: recap.weekEnd,
                        totalLogs: recap.totalLogs,
                        averageRating: recap.averageRating,
                        shareText: recap.shareText,
                        deepLink: recap.deepLink
                    )
                }
            }
        } catch {
            await MainActor.run {
                self.syncMessage = "Offline mode: \(error.localizedDescription)"
                self.errorMessage = "Could not reach SoundScore servers. Showing cached data."
                self.isLoading = false
            }
            return
        }

        await MainActor.run {
            self.isLoading = false
        }
    }

    // MARK: - Local Queries

    func searchAlbums(query: String) -> [Album] {
        let normalized = query.trimmingCharacters(in: .whitespaces)
        if normalized.isEmpty { return albums }
        let lower = normalized.lowercased()
        return albums.filter {
            $0.title.lowercased().contains(lower) ||
            $0.artist.lowercased().contains(lower)
        }
    }

    // MARK: - Track Operations

    func fetchTracks(albumId: String) async {
        // If we already have tracks from seed data, skip
        if let existing = tracksByAlbum[albumId], !existing.isEmpty { return }

        // Try API first
        do {
            let remoteTracks = try await api.getAlbumTracks(albumId: albumId)
            let mapped = remoteTracks.map { dto in
                Track(
                    id: dto.id, albumId: dto.albumId, title: dto.title,
                    trackNumber: dto.trackNumber, durationMs: dto.durationMs,
                    spotifyId: dto.spotifyId
                )
            }
            if !mapped.isEmpty {
                await MainActor.run { self.tracksByAlbum[albumId] = mapped }
                return
            }
        } catch {
            // Fall through to Spotify
        }

        // Try Spotify if album has a known spotifyId
        if let album = albums.first(where: { $0.id == albumId }) {
            let results = await SpotifyService.shared.searchAlbums(query: "\(album.title) \(album.artist)", limit: 1)
            if let spotifyAlbum = results.first {
                let spotifyTracks = await SpotifyService.shared.fetchAlbumTracks(spotifyAlbumId: spotifyAlbum.spotifyId)
                let mapped = spotifyTracks.map { st in
                    Track(
                        id: "st_\(albumId)_\(st.trackNumber)",
                        albumId: albumId,
                        title: st.title,
                        trackNumber: st.trackNumber,
                        durationMs: st.durationMs,
                        spotifyId: st.spotifyId
                    )
                }
                if !mapped.isEmpty {
                    await MainActor.run { self.tracksByAlbum[albumId] = mapped }
                }
            }
        }
    }

    func updateTrackRating(trackId: String, albumId: String, rating: Float) {
        trackRatings[trackId] = rating
        outboxStore.enqueue(OutboxOperation(
            type: .rateTrack,
            payload: ["trackId": trackId, "albumId": albumId, "rating": String(rating)]
        ))
        Task { await syncOutbox() }
    }

    // MARK: - Mutations (optimistic + outbox)

    func updateRating(albumId: String, rating: Float) {
        outboxStore.enqueue(OutboxOperation(
            type: .rateAlbum,
            payload: ["albumId": albumId, "rating": String(rating)]
        ))
        ratings[albumId] = rating

        let values = ratings.values
        let avg = values.isEmpty
            ? profile.avgRating
            : values.reduce(0, +) / Float(values.count)

        profile = UserProfile(
            handle: profile.handle, bio: profile.bio,
            logCount: profile.logCount, reviewCount: profile.reviewCount,
            listCount: profile.listCount, topAlbums: profile.topAlbums,
            genres: profile.genres, avgRating: avg,
            albumsCount: profile.albumsCount,
            followingCount: profile.followingCount,
            followersCount: profile.followersCount,
            favoriteAlbums: profile.favoriteAlbums
        )
        Task { await syncOutbox() }
    }

    func toggleLike(feedItemId: String) {
        outboxStore.enqueue(OutboxOperation(
            type: .toggleReaction,
            payload: ["feedItemId": feedItemId]
        ))
        guard let index = feedItems.firstIndex(where: { $0.id == feedItemId }) else { return }
        feedItems[index].isLiked.toggle()
        feedItems[index].likes = max(0, feedItems[index].likes + (feedItems[index].isLiked ? 1 : -1))
        Task { await syncOutbox() }
    }

    func saveReview(albumId: String, reviewText: String, rating: Float) {
        outboxStore.enqueue(OutboxOperation(
            type: .createReview,
            payload: [
                "albumId": albumId,
                "body": reviewText,
                "rating": String(rating),
            ]
        ))
        // Also persist the rating optimistically
        if rating > 0 {
            updateRating(albumId: albumId, rating: rating)
        }
        Task { await syncOutbox() }
    }

    func createList(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        outboxStore.enqueue(OutboxOperation(
            type: .createList,
            payload: ["title": trimmed]
        ))

        let newList = UserList(
            id: "l_\(UUID().uuidString.prefix(8))",
            title: trimmed, note: nil, albumIds: [],
            curatorHandle: AuthManager.shared.currentHandle ?? "@user",
            saves: 0
        )
        lists.append(newList)
        Task { await syncOutbox() }
    }

    // MARK: - Outbox Sync

    func syncOutbox() async {
        await outboxEngine.flush { [self] op in
            switch op.type {
            case .rateAlbum:
                let albumId = op.payload["albumId"] ?? ""
                let rating = Float(op.payload["rating"] ?? "0") ?? 0
                try await api.createRating(
                    albumId: albumId, value: rating,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .rateTrack:
                let trackId = op.payload["trackId"] ?? ""
                let albumId = op.payload["albumId"] ?? ""
                let rating = Float(op.payload["rating"] ?? "0") ?? 0
                try await api.createTrackRating(
                    trackId: trackId, albumId: albumId, value: rating,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .createReview:
                let albumId = op.payload["albumId"] ?? ""
                let body = op.payload["body"] ?? ""
                try await api.createReview(
                    albumId: albumId, body: body,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .toggleReaction:
                let activityId = op.payload["feedItemId"] ?? ""
                try await api.reactToActivity(
                    id: activityId, reaction: "like",
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .createList:
                let title = op.payload["title"] ?? ""
                try await api.createList(
                    title: title,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .exportData:
                break
            case .registerDeviceToken:
                let platform = op.payload["platform"] ?? ""
                let token = op.payload["deviceToken"] ?? ""
                try await api.registerDevice(
                    platform: platform, token: token,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            case .updateNotificationPreferences:
                let prefs = NotificationPreferenceDto(
                    socialEnabled: op.payload["socialEnabled"] == "true",
                    recapEnabled: op.payload["recapEnabled"] == "true",
                    commentEnabled: op.payload["commentEnabled"] == "true",
                    reactionEnabled: op.payload["reactionEnabled"] == "true",
                    quietHoursStart: Int(op.payload["quietHoursStart"] ?? "22") ?? 22,
                    quietHoursEnd: Int(op.payload["quietHoursEnd"] ?? "7") ?? 7
                )
                try await api.updatePreferences(
                    prefs,
                    idempotencyKey: op.idempotencyKey.uuidString
                )
            }
        }

        let pending = outboxStore.pending
        await MainActor.run {
            if pending.isEmpty {
                self.syncMessage = nil
            } else {
                self.syncMessage = "Pending \(pending.count) offline ops"
            }
        }
    }

    // MARK: - Mappers

    private func mapAlbum(_ dto: AlbumDto) -> Album {
        let colors = SeedData.albums.first { $0.id == dto.id }?.artColors
            ?? SeedData.albums.randomElement()?.artColors
            ?? AlbumColors.forest
        let genres = SeedData.albums.first { $0.id == dto.id }?.genres ?? []
        return Album(
            id: dto.id, title: dto.title, artist: dto.artist, year: dto.year,
            artColors: colors, artworkUrl: dto.artworkUrl,
            avgRating: dto.avgRating, logCount: dto.logCount,
            genres: genres
        )
    }

    private func mapFeedItem(_ event: ActivityEventDto) -> FeedItem {
        let resolvedAlbum = albums.first { $0.id == event.activityObject.id }
            ?? albums.first
            ?? SeedData.albums[0]
        let action: String
        switch event.type {
        case "RATED_ALBUM": action = "rated"
        case "WROTE_REVIEW": action = "reviewed"
        case "CREATED_LIST": action = "created a list"
        case "ADDED_LIST_ITEM": action = "updated a list"
        default: action = "posted"
        }
        return FeedItem(
            id: event.id, username: event.actorId, action: action,
            album: resolvedAlbum,
            rating: resolvedAlbum.avgRating,
            reviewSnippet: nil,
            likes: event.reactions, comments: event.comments,
            timeAgo: formatTimeAgo(event.createdAt), isLiked: false
        )
    }

    private func formatTimeAgo(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoDate) else {
            return String(isoDate.prefix(16))
        }
        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86400: return "\(seconds / 3600)h"
        case ..<604800: return "\(seconds / 86400)d"
        default: return "\(seconds / 604800)w"
        }
    }
}
