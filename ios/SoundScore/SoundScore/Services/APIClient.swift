import Foundation

// MARK: - Error Types

enum ApiError: Error, LocalizedError {
    case networkError(Error)
    case unauthorized
    case serverError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Client

final class APIClient {
    static let shared = APIClient()

    let baseURL: String
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder = JSONEncoder()

    init(baseURL: String = AppConfig.apiBaseURL) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    // MARK: - Typed Returns

    func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await raw(
            method: "GET", path: path,
            queryItems: queryItems, authenticated: authenticated
        )
        return try decode(data)
    }

    func post<T: Decodable>(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:],
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await raw(
            method: "POST", path: path, body: body,
            extraHeaders: headers, authenticated: authenticated
        )
        return try decode(data)
    }

    func put<T: Decodable>(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:],
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await raw(
            method: "PUT", path: path, body: body,
            extraHeaders: headers, authenticated: authenticated
        )
        return try decode(data)
    }

    func delete<T: Decodable>(
        _ path: String,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await raw(
            method: "DELETE", path: path, authenticated: authenticated
        )
        return try decode(data)
    }

    // MARK: - Void Returns

    func postVoid(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:],
        authenticated: Bool = true
    ) async throws {
        _ = try await raw(
            method: "POST", path: path, body: body,
            extraHeaders: headers, authenticated: authenticated
        )
    }

    func putVoid(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:],
        authenticated: Bool = true
    ) async throws {
        _ = try await raw(
            method: "PUT", path: path, body: body,
            extraHeaders: headers, authenticated: authenticated
        )
    }

    func deleteVoid(
        _ path: String,
        authenticated: Bool = true
    ) async throws {
        _ = try await raw(
            method: "DELETE", path: path, authenticated: authenticated
        )
    }

    func getRaw(
        _ path: String,
        authenticated: Bool = true
    ) async throws -> Data {
        try await raw(method: "GET", path: path, authenticated: authenticated)
    }

    func postRaw(
        _ path: String,
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Data {
        try await raw(method: "POST", path: path, body: body, authenticated: authenticated)
    }

    // MARK: - Core

    private func raw(
        method: String,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil,
        extraHeaders: [String: String] = [:],
        authenticated: Bool,
        isRetry: Bool = false
    ) async throws -> Data {
        let request = buildURLRequest(
            method: method, path: path, body: body,
            queryItems: queryItems, extraHeaders: extraHeaders,
            authenticated: authenticated
        )

        #if DEBUG
        print("[API] \(method) \(path)")
        #endif

        let responseData: Data
        let httpResponse: HTTPURLResponse

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw ApiError.networkError(URLError(.badServerResponse))
            }
            responseData = data
            httpResponse = http
        } catch let error as ApiError {
            throw error
        } catch {
            throw ApiError.networkError(error)
        }

        #if DEBUG
        print("[API] \(httpResponse.statusCode) \(path) (\(responseData.count) bytes)")
        #endif

        if httpResponse.statusCode == 401 && authenticated && !isRetry {
            do {
                try await AuthManager.shared.refresh()
                return try await raw(
                    method: method, path: path, body: body,
                    queryItems: queryItems, extraHeaders: extraHeaders,
                    authenticated: authenticated, isRetry: true
                )
            } catch {
                throw ApiError.unauthorized
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw ApiError.unauthorized
            }
            let message = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw ApiError.serverError(httpResponse.statusCode, message)
        }

        return responseData
    }

    private func buildURLRequest(
        method: String,
        path: String,
        body: Data?,
        queryItems: [URLQueryItem]?,
        extraHeaders: [String: String],
        authenticated: Bool
    ) -> URLRequest {
        var components = URLComponents(string: baseURL + path)
        if let queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            fatalError("[APIClient] Invalid URL: \(baseURL + path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if authenticated, let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        return request
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            if let json = String(data: data, encoding: .utf8) {
                print("[API] Decode error for \(T.self): \(error)\nJSON: \(json.prefix(500))")
            }
            #endif
            throw ApiError.decodingError(error)
        }
    }
}
