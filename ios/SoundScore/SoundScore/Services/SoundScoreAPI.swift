import Foundation

// MARK: - API Response DTOs

struct CursorPage<T: Decodable>: Decodable {
    let items: [T]
    let nextCursor: String?
}

struct AlbumDto: Decodable {
    let id: String
    let title: String
    let artist: String
    let year: Int
    let artworkUrl: String?
    let avgRating: Float
    let logCount: Int
}

struct UserProfileDto: Decodable {
    let id: String
    let handle: String
    let bio: String
    let logCount: Int
    let reviewCount: Int
    let listCount: Int
    let avgRating: Float
}

struct ActivityObjectDto: Decodable {
    let type: String
    let id: String
}

struct ActivityEventDto: Decodable {
    let id: String
    let actorId: String
    let type: String
    let activityObject: ActivityObjectDto
    let createdAt: String
    let reactions: Int
    let comments: Int

    enum CodingKeys: String, CodingKey {
        case id, actorId, type
        case activityObject = "object"
        case createdAt, reactions, comments
    }
}

struct WeeklyRecapDto: Decodable {
    let id: String
    let weekStart: String
    let weekEnd: String
    let totalLogs: Int
    let averageRating: Float
    let shareText: String
    let deepLink: String
}

struct NotificationPreferenceDto: Codable {
    let socialEnabled: Bool
    let recapEnabled: Bool
    let commentEnabled: Bool
    let reactionEnabled: Bool
    let quietHoursStart: Int
    let quietHoursEnd: Int
}

struct TrackDto: Decodable {
    let id: String
    let albumId: String
    let title: String
    let trackNumber: Int
    let durationMs: Int?
    let spotifyId: String?
}

struct TrackRatingDto: Decodable {
    let id: String
    let trackId: String
    let albumId: String
    let value: Float
}

struct ListDetailDto: Decodable {
    let id: String
    let title: String
    let note: String?
    let ownerId: String
    let items: [ListItemDto]
}

struct ListItemDto: Decodable {
    let id: String
    let albumId: String
    let position: Int
}

// MARK: - SoundScore API

struct SoundScoreAPI {
    private let client: APIClient
    private let encoder = JSONEncoder()

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: Catalog

    func searchAlbums(query: String) async throws -> CursorPage<AlbumDto> {
        try await client.get(
            "/v1/search",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
    }

    func getAlbum(id: String) async throws -> AlbumDto {
        try await client.get("/v1/albums/\(id)")
    }

    // MARK: Tracks

    func getAlbumTracks(albumId: String) async throws -> [TrackDto] {
        try await client.get("/v1/albums/\(albumId)/tracks")
    }

    func getAlbumTrackRatings(albumId: String) async throws -> [TrackRatingDto] {
        try await client.get("/v1/albums/\(albumId)/track-ratings")
    }

    func createTrackRating(
        trackId: String, albumId: String, value: Float, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let trackId: String; let albumId: String; let value: Float }
        let data = try encoder.encode(Body(trackId: trackId, albumId: albumId, value: value))
        try await client.postVoid(
            "/v1/track-ratings", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    // MARK: Ratings

    func createRating(
        albumId: String, value: Float, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let albumId: String; let value: Float }
        let data = try encoder.encode(Body(albumId: albumId, value: value))
        try await client.postVoid(
            "/v1/ratings", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    // MARK: Reviews

    func createReview(
        albumId: String, body reviewBody: String, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let albumId: String; let body: String }
        let data = try encoder.encode(Body(albumId: albumId, body: reviewBody))
        try await client.postVoid(
            "/v1/reviews", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    func updateReview(id: String, body reviewBody: String, revision: Int) async throws {
        struct Body: Encodable { let body: String; let expectedRevision: Int }
        let data = try encoder.encode(Body(body: reviewBody, expectedRevision: revision))
        try await client.putVoid("/v1/reviews/\(id)", body: data)
    }

    func deleteReview(id: String) async throws {
        try await client.deleteVoid("/v1/reviews/\(id)")
    }

    // MARK: Lists

    func createList(
        title: String, note: String? = nil, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let title: String; let note: String? }
        let data = try encoder.encode(Body(title: title, note: note))
        try await client.postVoid(
            "/v1/lists", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    func getList(id: String) async throws -> ListDetailDto {
        try await client.get("/v1/lists/\(id)")
    }

    func addListItem(
        listId: String, albumId: String, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let albumId: String }
        let data = try encoder.encode(Body(albumId: albumId))
        try await client.postVoid(
            "/v1/lists/\(listId)/items", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    func removeListItem(listId: String, itemId: String) async throws {
        try await client.deleteVoid("/v1/lists/\(listId)/items/\(itemId)")
    }

    // MARK: Feed

    func getFeed(cursor: String? = nil) async throws -> CursorPage<ActivityEventDto> {
        var queryItems: [URLQueryItem] = []
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try await client.get(
            "/v1/feed",
            queryItems: queryItems.isEmpty ? nil : queryItems
        )
    }

    func reactToActivity(
        id: String, reaction: String, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let reaction: String }
        let data = try encoder.encode(Body(reaction: reaction))
        try await client.postVoid(
            "/v1/activity/\(id)/react", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    func commentOnActivity(id: String, body commentBody: String) async throws {
        struct Body: Encodable { let body: String }
        let data = try encoder.encode(Body(body: commentBody))
        try await client.postVoid("/v1/activity/\(id)/comment", body: data)
    }

    // MARK: Social

    func follow(userId: String) async throws {
        try await client.postVoid("/v1/follow/\(userId)")
    }

    func unfollow(userId: String) async throws {
        try await client.deleteVoid("/v1/follow/\(userId)")
    }

    func getProfile(handle: String) async throws -> UserProfileDto {
        try await client.get("/v1/me")
    }

    // MARK: Recaps

    func getWeeklyRecap() async throws -> WeeklyRecapDto {
        try await client.get("/v1/recaps/weekly/latest")
    }

    // MARK: Push

    func registerDevice(
        platform: String, token: String, idempotencyKey: String
    ) async throws {
        struct Body: Encodable { let platform: String; let deviceToken: String }
        let data = try encoder.encode(Body(platform: platform, deviceToken: token))
        try await client.postVoid(
            "/v1/push/tokens", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    func getPreferences() async throws -> NotificationPreferenceDto {
        try await client.get("/v1/push/preferences")
    }

    func updatePreferences(
        _ prefs: NotificationPreferenceDto, idempotencyKey: String
    ) async throws {
        let data = try encoder.encode(prefs)
        try await client.putVoid(
            "/v1/push/preferences", body: data,
            headers: ["idempotency-key": idempotencyKey]
        )
    }

    // MARK: Trust

    func exportData() async throws -> Data {
        try await client.getRaw("/v1/account/export")
    }

    func deleteAccount() async throws {
        try await client.deleteVoid("/v1/account")
    }
}
