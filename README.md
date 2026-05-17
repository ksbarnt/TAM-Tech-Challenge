# OIDCDemo — SwiftUI OIDC PKCE iOS App

A SwiftUI iOS application that authenticates with any OIDC-compliant provider
using the **Authorization Code + PKCE** flow (RFC 7636), then demonstrates
all five REST verbs (GET, POST, PUT, PATCH, DELETE) with automatic token
refresh on 401.

## Architecture

```
OIDCDemo/
├── Auth/
│   ├── OIDCConfig.swift          # All provider configuration
│   ├── PKCEHelper.swift          # Code verifier / challenge generation
│   ├── OIDCAuthManager.swift     # Full PKCE login flow (ASWebAuthenticationSession)
│   └── TokenStore.swift          # Keychain-backed token persistence
├── API/
│   └── AuthenticatedAPIClient.swift  # GET POST PUT PATCH DELETE + auto-refresh
├── Models/
│   └── AuthModels.swift          # TokenResponse, OIDCDiscovery, AuthError
├── ViewModels/
│   └── APIViewModel.swift        # Drives the API console screen
├── Views/
│   ├── LoginView.swift           # Unauthenticated screen
│   └── APIConsoleView.swift      # Authenticated API console
├── OIDCDemoApp.swift             # @main entry point
└── Info.plist                    # URL scheme registration
```

## Setup

### 1. Configure your OIDC provider — `OIDCConfig.swift`

| Property | Description |
|---|---|
| `issuer` | Your provider's base URL, e.g. `https://dev-xxx.okta.com` |
| `clientID` | Client ID from your provider (must be a **public** client — no secret) |
| `redirectURI` | Must match the scheme in Info.plist |
| `apiBaseURL` | Your REST API's base URL |

### 2. Register the redirect URI

In your OIDC provider's dashboard, add the redirect URI:

```
com.example.oidcdemo://callback
```

If you change the scheme, update both `OIDCConfig.redirectURI` **and**
`Info.plist → CFBundleURLSchemes`.

### 3. Xcode setup

1. Open `OIDCDemo.xcodeproj` (or create a new SwiftUI project and add these files).
2. Set your **Bundle Identifier** (e.g. `com.example.oidcdemo`).
3. Under **Signing & Capabilities**, add your team.
4. Build & run on a real device or simulator (iOS 16+).

## How the PKCE Flow Works

```
App                    ASWebAuthenticationSession        OIDC Provider
 |                             |                              |
 |-- generate verifier ------->|                              |
 |-- SHA256(verifier)=challenge|                              |
 |-- open browser with challenge --------------------------->|
 |                             |<-- user logs in ------------>|
 |                             |<-- redirect with code -------|
 |<-- callback(code) ----------|                              |
 |-- POST code + verifier ---------------------------------->|
 |<-- access_token, refresh_token, id_token -----------------|
 |                                                            |
 |-- GET/POST/PUT/PATCH/DELETE /api/... (Bearer token) ------>
```

## Token Storage

Tokens are stored in the **iOS Keychain** via `TokenStore`:

| Keychain key | Value |
|---|---|
| `oidc.access_token` | Short-lived bearer token |
| `oidc.refresh_token` | Long-lived refresh token |
| `oidc.id_token` | JWT identity token |

## AuthenticatedAPIClient Usage

```swift
let client = AuthenticatedAPIClient(authManager: authManager)

// GET with query params
let users: [User] = try await client.get("/users",
    queryItems: [URLQueryItem(name: "role", value: "admin")],
    as: [User].self)

// POST
let created: Item = try await client.post("/items",
    body: NewItem(name: "Widget", quantity: 3),
    as: Item.self)

// PUT — full replacement
let updated: Item = try await client.put("/items/42",
    body: Item(id: 42, name: "Widget", quantity: 10),
    as: Item.self)

// PATCH — partial update
let patched: Item = try await client.patch("/items/42",
    body: ["quantity": 7],
    as: Item.self)

// DELETE
_ = try await client.delete("/items/42")  // returns empty Data on 204
```

## Dependencies

None — uses only Apple frameworks:
- `AuthenticationServices` (ASWebAuthenticationSession)
- `CryptoKit` (SHA-256 for PKCE challenge)
- `Security` (Keychain)
- `Foundation` / `SwiftUI`

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9+
