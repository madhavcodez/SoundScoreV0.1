import Foundation

actor SpotifyService {
    static let shared = SpotifyService()

    private let clientId = Secrets.spotifyClientId
    private let clientSecret = Secrets.spotifyClientSecret
    private let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
    private let searchURL = URL(string: "https://api.spotify.com/v1/search")!

    private var accessToken: String?
    private var tokenExpiry: Date = .distantPast
    private var artworkCache: [String: String] = [:]

    // MARK: - Public API

    /// Search Spotify for albums, returns array of (title, artist, artworkUrl, spotifyId)
    func searchAlbums(query: String, limit: Int = 5) async -> [SpotifyAlbumResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        do {
            let token = try await ensureToken()

            var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "type", value: "album"),
                URLQueryItem(name: "limit", value: String(min(limit, 10)))
            ]
            guard let url = components.url else { return [] }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }

            let decoded = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            return decoded.albums.items.compactMap { album in
                guard let imageUrl = album.images.first?.url else { return nil }
                return SpotifyAlbumResult(
                    title: album.name,
                    artist: album.artists.first?.name ?? "Unknown",
                    artworkUrl: imageUrl,
                    spotifyId: album.id,
                    year: parseYear(album.releaseDate)
                )
            }
        } catch {
            #if DEBUG
            print("[Spotify] Search error: \(error)")
            #endif
            return []
        }
    }

    /// Look up artwork URL for a specific album by title + artist
    func artworkUrl(title: String, artist: String) async -> String? {
        let cacheKey = "\(title)|\(artist)".lowercased()
        if let cached = artworkCache[cacheKey] { return cached }

        let results = await searchAlbums(query: "\(title) \(artist)", limit: 1)
        guard let first = results.first else { return nil }
        artworkCache[cacheKey] = first.artworkUrl
        return first.artworkUrl
    }

    /// Fetch tracks for a Spotify album
    func fetchAlbumTracks(spotifyAlbumId: String) async -> [SpotifyTrackResult] {
        do {
            let token = try await ensureToken()

            guard let url = URL(string: "https://api.spotify.com/v1/albums/\(spotifyAlbumId)/tracks?limit=50") else { return [] }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }

            let decoded = try JSONDecoder().decode(SpotifyTracksResponse.self, from: data)
            return decoded.items.enumerated().map { index, item in
                SpotifyTrackResult(
                    title: item.name,
                    trackNumber: item.trackNumber ?? (index + 1),
                    durationMs: item.durationMs,
                    spotifyId: item.id
                )
            }
        } catch {
            #if DEBUG
            print("[Spotify] Tracks error: \(error)")
            #endif
            return []
        }
    }

    // MARK: - Auth (Client Credentials)

    private func ensureToken() async throws -> String {
        if let token = accessToken, Date() < tokenExpiry {
            return token
        }

        let credentials = Data("\(clientId):\(clientSecret)".utf8).base64EncodedString()

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw SpotifyError.authFailed
        }

        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))
        return tokenResponse.accessToken
    }

    private func parseYear(_ releaseDate: String) -> Int {
        Int(releaseDate.prefix(4)) ?? 0
    }
}

// MARK: - Models

struct SpotifyAlbumResult {
    let title: String
    let artist: String
    let artworkUrl: String
    let spotifyId: String
    let year: Int
}

struct SpotifyTrackResult {
    let title: String
    let trackNumber: Int
    let durationMs: Int
    let spotifyId: String
}

enum SpotifyError: Error {
    case authFailed
}

// MARK: - Spotify API Response Types

private struct SpotifyTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

private struct SpotifySearchResponse: Decodable {
    let albums: SpotifyAlbumsPage
}

private struct SpotifyAlbumsPage: Decodable {
    let items: [SpotifyAlbum]
}

private struct SpotifyAlbum: Decodable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let images: [SpotifyImage]
    let releaseDate: String

    enum CodingKeys: String, CodingKey {
        case id, name, artists, images
        case releaseDate = "release_date"
    }
}

private struct SpotifyArtist: Decodable {
    let name: String
}

private struct SpotifyImage: Decodable {
    let url: String
    let height: Int?
    let width: Int?
}

// MARK: - Spotify Tracks Response Types

private struct SpotifyTracksResponse: Decodable {
    let items: [SpotifyTrackItem]
}

private struct SpotifyTrackItem: Decodable {
    let id: String
    let name: String
    let trackNumber: Int?
    let durationMs: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case trackNumber = "track_number"
        case durationMs = "duration_ms"
    }
}
