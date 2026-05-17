import Foundation

/// All provider-specific values live here.
/// Replace these with your actual OIDC provider details.
struct OIDCConfig {

    // ── Provider ─────────────────────────────────────────────────────────────
    /// Issuer URL (no trailing slash).
    static let issuer = "https://your-provider.example.com"

    /// When true, authorization/token endpoints are fetched from
    /// <issuer>/.well-known/openid-configuration at runtime.
    static let useDiscovery = true

    /// Used only when useDiscovery == false.
    static let authorizationEndpoint = "https://your-provider.example.com/oauth2/authorize"
    static let tokenEndpoint         = "https://your-provider.example.com/oauth2/token"

    // ── Client ────────────────────────────────────────────────────────────────
    /// Must be registered as a public (no secret) native/mobile client.
    static let clientID = "your-client-id"

    /// Must be registered in your provider.
    /// Add this to your app's Info.plist URL Schemes so iOS can intercept it.
    static let redirectURI = "com.example.oidcdemo://callback"

    static let scopes = "openid profile email offline_access"

    // ── API ───────────────────────────────────────────────────────────────────
    static let apiBaseURL = URL(string: "https://api.example.com")!
}
