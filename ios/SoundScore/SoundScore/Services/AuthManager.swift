import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    /// Set to `true` to bypass login while backend is offline.
    @Published var isAuthenticated: Bool = true
    @Published var currentHandle: String?

    private(set) var accessToken: String?
    private var refreshTokenValue: String?

    private let baseURL: String
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    private let encoder = JSONEncoder()

    private init(baseURL: String = "http://localhost:8080") {
        self.baseURL = baseURL
        self.accessToken = UserDefaults.standard.string(forKey: "ss_accessToken")
        self.refreshTokenValue = UserDefaults.standard.string(forKey: "ss_refreshToken")
        self.currentHandle = UserDefaults.standard.string(forKey: "ss_handle")
        self.isAuthenticated = (accessToken != nil)
    }

    // MARK: - Public API

    func login(email: String, password: String) async throws {
        let body = AuthRequestBody(email: email, password: password, handle: nil)
        let response: AuthResponseBody = try await authRequest(
            path: "/v1/auth/login", body: body
        )
        await applyAuth(response)
    }

    func signup(email: String, password: String, handle: String) async throws {
        let body = AuthRequestBody(email: email, password: password, handle: handle)
        let response: AuthResponseBody = try await authRequest(
            path: "/v1/auth/signup", body: body
        )
        await applyAuth(response)
    }

    func refresh() async throws {
        guard let token = refreshTokenValue else { throw ApiError.unauthorized }
        let body = RefreshRequestBody(refreshToken: token)
        let response: AuthResponseBody = try await authRequest(
            path: "/v1/auth/refresh", body: body
        )
        await applyAuth(response)
    }

    @MainActor
    func logout() {
        accessToken = nil
        refreshTokenValue = nil
        currentHandle = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "ss_accessToken")
        UserDefaults.standard.removeObject(forKey: "ss_refreshToken")
        UserDefaults.standard.removeObject(forKey: "ss_handle")
    }

    // MARK: - Private

    @MainActor
    private func applyAuth(_ response: AuthResponseBody) {
        accessToken = response.accessToken
        refreshTokenValue = response.refreshToken
        currentHandle = response.handle
        isAuthenticated = true
        UserDefaults.standard.set(response.accessToken, forKey: "ss_accessToken")
        UserDefaults.standard.set(response.refreshToken, forKey: "ss_refreshToken")
        UserDefaults.standard.set(response.handle, forKey: "ss_handle")
    }

    private func authRequest<B: Encodable, T: Decodable>(
        path: String, body: B
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw ApiError.networkError(URLError(.badURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ApiError.networkError(URLError(.badServerResponse))
        }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 { throw ApiError.unauthorized }
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ApiError.serverError(http.statusCode, message)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Auth DTOs

private struct AuthRequestBody: Encodable {
    let email: String
    let password: String
    let handle: String?
}

private struct RefreshRequestBody: Encodable {
    let refreshToken: String
}

private struct AuthResponseBody: Decodable {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let handle: String
}
