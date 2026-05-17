import Foundation

// ── Token response ────────────────────────────────────────────────────────────

struct TokenResponse: Decodable {
    let accessToken:  String
    let refreshToken: String?
    let idToken:      String?
    let expiresIn:    Int?
    let tokenType:    String

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case idToken      = "id_token"
        case expiresIn    = "expires_in"
        case tokenType    = "token_type"
    }
}

// ── OIDC Discovery document ───────────────────────────────────────────────────

struct OIDCDiscovery: Decodable {
    let authorizationEndpoint: String
    let tokenEndpoint:         String

    enum CodingKeys: String, CodingKey {
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint         = "token_endpoint"
    }
}

// ── Auth error ────────────────────────────────────────────────────────────────

enum AuthError: LocalizedError {
    case discoveryFailed(String)
    case callbackMissing
    case stateMismatch
    case tokenExchangeFailed(String)
    case refreshFailed(String)
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .discoveryFailed(let m):    return "Discovery failed: \(m)"
        case .callbackMissing:           return "No authorization code in callback URL."
        case .stateMismatch:             return "State mismatch — possible CSRF attack."
        case .tokenExchangeFailed(let m): return "Token exchange failed: \(m)"
        case .refreshFailed(let m):      return "Token refresh failed: \(m)"
        case .noRefreshToken:            return "No refresh token — please log in again."
        }
    }
}
