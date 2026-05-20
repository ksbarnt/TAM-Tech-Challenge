import Foundation

/// A URL-session wrapper that injects Bearer tokens and handles 401 → refresh → retry.
/// Mirrors the Python `AuthenticatedAPIClient` class with GET, POST, PUT, PATCH, DELETE.
actor AuthenticatedAPIClient {

    private let store      = TokenStore.shared
    private let authManager: OIDCAuthManager
    private let session    = URLSession.shared
    private let baseURL    : URL
    private let decoder    = JSONDecoder()

    init(authManager: OIDCAuthManager, baseURL: URL = OIDCConfig.apiBaseURL) {
        self.authManager = authManager
        self.baseURL     = baseURL
    }

    // ── Public HTTP methods ───────────────────────────────────────────────────

    func get(_ path: String,
             queryItems: [URLQueryItem] = []) async throws -> Data {
        try await request(method: "GET", path: path, queryItems: queryItems, body: nil)
    }

    func post(_ path: String,
              body: Encodable? = nil,
              queryItems: [URLQueryItem] = []) async throws -> Data {
        try await request(method: "POST", path: path, queryItems: queryItems, body: body)
    }

    func put(_ path: String,
             body: Encodable? = nil,
             queryItems: [URLQueryItem] = []) async throws -> Data {
        try await request(method: "PUT", path: path, queryItems: queryItems, body: body)
    }

    func patch(_ path: String,
               body: Encodable? = nil,
               queryItems: [URLQueryItem] = []) async throws -> Data {
        try await request(method: "PATCH", path: path, queryItems: queryItems, body: body)
    }

    /// DELETE — many APIs return 204 No Content; the returned Data will be empty in that case.
    func delete(_ path: String) async throws -> Data {
        try await request(method: "DELETE", path: path, body: nil as EmptyBody?)
    }

    // ── Typed convenience overloads ───────────────────────────────────────────

    func get<T: Decodable>(_ path: String,
                           queryItems: [URLQueryItem] = [],
                           as type: T.Type = T.self) async throws -> T {
        let data = try await get(path, queryItems: queryItems)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable>(_ path: String,
                            body: Encodable? = nil,
                            as type: T.Type = T.self) async throws -> T {
        let data = try await post(path, body: body)
        return try decoder.decode(T.self, from: data)
    }

    func put<T: Decodable>(_ path: String,
                           body: Encodable? = nil,
                           as type: T.Type = T.self) async throws -> T {
        let data = try await put(path, body: body)
        return try decoder.decode(T.self, from: data)
    }

    func patch<T: Decodable>(_ path: String,
                             body: Encodable? = nil,
                             as type: T.Type = T.self) async throws -> T {
        let data = try await patch(path, body: body)
        return try decoder.decode(T.self, from: data)
    }

    // ── Core dispatcher ───────────────────────────────────────────────────────

    private func request(method: String,
                         path: String,
                         queryItems: [URLQueryItem] = [],
                         body: Encodable?) async throws -> Data {
//        try await authManager.refreshAccessToken()
        var req = try buildRequest(method: method, path: path,
                                   queryItems: queryItems, body: body)
        injectToken(&req)

        let (data, response) = try await session.data(for: req)

        // On 401, refresh once and retry
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await authManager.refreshAccessToken()
            injectToken(&req)
            let (retryData, retryResponse) = try await session.data(for: req)
            try validate(retryResponse, data: retryData)
            return retryData
        }

        try validate(response, data: data)
        return data
    }

    // ── Builder helpers ───────────────────────────────────────────────────────

    private func buildRequest(method: String,
                              path: String,
                              queryItems: [URLQueryItem],
                              body: Encodable?) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        var req        = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return req
    }

    private func injectToken(_ request: inout URLRequest) {
        if let token = store.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(empty)"
            throw APIError.httpError(statusCode: http.statusCode, body: body)
        }
    }
}

// ── Supporting types ──────────────────────────────────────────────────────────

enum APIError: LocalizedError {
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        }
    }
}

/// Type-erased Encodable so we can pass any Encodable into a generic JSONEncoder call.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { _encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

/// Sentinel for body-less requests (DELETE).
private struct EmptyBody: Encodable {}

