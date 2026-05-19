import AuthenticationServices
import Foundation
import Combine

/// Drives the full OIDC Authorization Code + PKCE flow using
/// ASWebAuthenticationSession (no custom URL scheme server needed on iOS).
@MainActor
final class OIDCAuthManager: NSObject, ObservableObject {

    // ── Published state ───────────────────────────────────────────────────────
    @Published var isAuthenticated = false
    @Published var isLoading       = false
    @Published var errorMessage:   String?

    // ── Private ───────────────────────────────────────────────────────────────
    private var codeVerifier   = ""
    private var pendingState   = ""
    private var authEndpoint   = OIDCConfig.authorizationEndpoint
    private var tokenEndpoint  = OIDCConfig.tokenEndpoint
    private var authSession:   ASWebAuthenticationSession?

    private let store = TokenStore.shared

    // ── Init ──────────────────────────────────────────────────────────────────
    override init() {
        super.init()
        isAuthenticated = store.hasValidSession
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /// Initiates the PKCE login flow.
    func login(presentationAnchor: ASPresentationAnchor) async {
        isLoading     = true
        errorMessage  = nil

        do {
            // 1. Discovery
            if OIDCConfig.useDiscovery {
                let meta = try await discoverEndpoints()
                authEndpoint  = meta.authorizationEndpoint
                tokenEndpoint = meta.tokenEndpoint
            }

            // 2. PKCE
            codeVerifier  = PKCEHelper.generateCodeVerifier()
            let challenge = PKCEHelper.generateCodeChallenge(from: codeVerifier)
            pendingState  = randomState()

            // 3. Build URL
            guard let authURL = buildAuthURL(challenge: challenge, state: pendingState) else {
                throw AuthError.discoveryFailed("Could not build authorization URL")
            }

            // 4. Open browser via ASWebAuthenticationSession
            let callbackURL = try await openBrowser(url: authURL,
                                                    anchor: presentationAnchor)

            // 5. Parse callback
            let (code, returnedState) = try parseCallback(callbackURL)
            guard returnedState == pendingState else { throw AuthError.stateMismatch }

            // 6. Exchange code for tokens
            let tokens = try await exchangeCode(code)
            store.save(tokens)
            isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refreshes the access token using the stored refresh token.
    func refreshAccessToken() async throws {
        guard let refreshToken = store.refreshToken else { throw AuthError.noRefreshToken }

        var components = URLComponents(string: tokenEndpoint)!
        var request    = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncode([
            "grant_type":    "refresh_token",
            "client_id":     OIDCConfig.clientID,
            "refresh_token": refreshToken,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AuthError.refreshFailed(body)
        }
        let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)
        store.save(tokens)
    }

    /// Clears all tokens and marks the session as unauthenticated.
    func logout() {
        store.clear()
        isAuthenticated = false
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private func discoverEndpoints() async throws -> OIDCDiscovery {
        let url = URL(string: "\(OIDCConfig.issuer)/.well-known/openid-configuration")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(OIDCDiscovery.self, from: data)
    }

    private func buildAuthURL(challenge: String, state: String) -> URL? {
        var components = URLComponents(string: authEndpoint)
        components?.queryItems = [
            URLQueryItem(name: "response_type",           value: "code"),
            URLQueryItem(name: "client_id",               value: OIDCConfig.clientID),
            URLQueryItem(name: "redirect_uri",            value: OIDCConfig.redirectURI),
            URLQueryItem(name: "scope",                   value: OIDCConfig.scopes),
            URLQueryItem(name: "state",                   value: state),
            URLQueryItem(name: "code_challenge",          value: challenge),
            URLQueryItem(name: "code_challenge_method",   value: "S256"),
        ]
        return components?.url
    }

    private func openBrowser(url: URL,
                             anchor: ASPresentationAnchor) async throws -> URL {
        guard let scheme = URL(string: OIDCConfig.redirectURI)?.scheme else {
            throw AuthError.callbackMissing
        }
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = callbackURL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AuthError.callbackMissing)
                }
            }
            let my_anchor = PresentationContextProvider(anchor: anchor)
            session.presentationContextProvider = my_anchor
            session.prefersEphemeralWebBrowserSession = false // allows SSO cookie reuse
            self.authSession = session
            session.start()
        }
    }

    private func parseCallback(_ url: URL) throws -> (code: String, state: String) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        guard let code = items.first(where: { $0.name == "code" })?.value else {
            let errorVal = items.first(where: { $0.name == "error" })?.value ?? "unknown"
            throw AuthError.tokenExchangeFailed(errorVal)
        }
        let state = items.first(where: { $0.name == "state" })?.value ?? ""
        return (code, state)
    }

    private func exchangeCode(_ code: String) async throws -> TokenResponse {
        guard let url = URL(string: tokenEndpoint) else {
            throw AuthError.tokenExchangeFailed("Invalid token endpoint")
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncode([
            "grant_type":    "authorization_code",
            "client_id":     OIDCConfig.clientID,
            "redirect_uri":  OIDCConfig.redirectURI,
            "code":          code,
            "code_verifier": codeVerifier,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AuthError.tokenExchangeFailed(body)
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func randomState() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func formEncode(_ dict: [String: String]) -> Data {
        dict.map { k, v in
            let ek = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k
            let ev = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
            return "\(ek)=\(ev)"
        }
        .joined(separator: "&")
        .data(using: .utf8)!
    }
}

// ── ASWebAuthenticationSession anchor helper ──────────────────────────────────

private final class PresentationContextProvider: NSObject,
                                                  ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) { self.anchor = anchor }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return anchor
    }
}
