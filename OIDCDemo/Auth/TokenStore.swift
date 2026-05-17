import Foundation
import Security

/// Persists tokens securely in the iOS Keychain.
final class TokenStore {

    private enum Key: String {
        case accessToken  = "oidc.access_token"
        case refreshToken = "oidc.refresh_token"
        case idToken      = "oidc.id_token"
    }

    static let shared = TokenStore()
    private init() {}

    // ── Public interface ──────────────────────────────────────────────────────

    var accessToken:  String? {
        get { read(.accessToken) }
        set { newValue == nil ? delete(.accessToken)  : write(newValue!, for: .accessToken) }
    }

    var refreshToken: String? {
        get { read(.refreshToken) }
        set { newValue == nil ? delete(.refreshToken) : write(newValue!, for: .refreshToken) }
    }

    var idToken: String? {
        get { read(.idToken) }
        set { newValue == nil ? delete(.idToken)      : write(newValue!, for: .idToken) }
    }

    var hasValidSession: Bool { accessToken != nil }

    func save(_ response: TokenResponse) {
        accessToken  = response.accessToken
        refreshToken = response.refreshToken
        idToken      = response.idToken
    }

    func clear() {
        accessToken  = nil
        refreshToken = nil
        idToken      = nil
    }

    // ── Keychain helpers ──────────────────────────────────────────────────────

    private func write(_ value: String, for key: Key) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(_ key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    private func delete(_ key: Key) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
