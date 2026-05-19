import Foundation

/// All provider-specific values live here.
/// Replace these with your actual OIDC provider details.
struct OIDCConfig {

    // ── Provider ─────────────────────────────────────────────────────────────
    /// Issuer URL (no trailing slash).
    static let issuer = "https://auth.ksbarnt.com"

    /// When true, authorization/token endpoints are fetched from
    /// <issuer>/.well-known/openid-configuration at runtime.
    static let useDiscovery = true

    /// Used only when useDiscovery == false.
    static let authorizationEndpoint = "https://auth.ksbarnt.com/oauth2/authorize"
    static let tokenEndpoint         = "https://auth.ksbarnt.com/oauth2/token"

    // ── Client ────────────────────────────────────────────────────────────────
    /// Must be registered as a public (no secret) native/mobile client.
    static let clientID = "0oa133b41hyjQGFuU698"

    /// Must be registered in your provider.
    /// Add this to your app's Info.plist URL Schemes so iOS can intercept it.
    static let redirectURI = "com.ksbarnt.tam-tech-challenge://callback"

    static let scopes = "openid profile email offline_access okta.users.manage okta.groups.read okta.groups.manage okta.users.read okta.users.read.self"

    // ── API ───────────────────────────────────────────────────────────────────
    static let apiBaseURL = URL(string: "https://auth.ksbarnt.com")!
}
