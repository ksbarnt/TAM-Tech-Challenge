import AuthenticationServices
import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authManager: OIDCAuthManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon + title
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)

                Text("OIDC PKCE Demo")
                    .font(.largeTitle.bold())

                Text("Sign in with your identity provider using the\nAuthorization Code + PKCE flow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Provider badge
            VStack(spacing: 4) {
                Label(OIDCConfig.issuer, systemImage: "server.rack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(OIDCConfig.clientID, systemImage: "person.badge.key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Error banner
            if let error = authManager.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding()
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
            }

            // Login button
            SignInButton(isLoading: authManager.isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }
}

// ── Sign-in button with ASWebAuthenticationSession anchor ────────────────────

private struct SignInButton: View {

    let isLoading: Bool
    @EnvironmentObject var authManager: OIDCAuthManager

    var body: some View {
        Button {
            // No-op — action is in the representable below
        } label: {
            Label(isLoading ? "Signing in…" : "Sign In", systemImage: "arrow.right.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
        .overlay {
            // Invisible button overlay to capture the window for ASWebAuthenticationSession
            WebAuthButton()
                .environmentObject(authManager)
        }
    }
}

/// UIViewRepresentable gives us access to the UIWindow so we can pass it to
/// ASWebAuthenticationSession as the presentation anchor.
private struct WebAuthButton: UIViewRepresentable {

    @EnvironmentObject var authManager: OIDCAuthManager

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(context.coordinator,
                         action: #selector(Coordinator.tapped(_:)),
                         for: .touchUpInside)
        button.backgroundColor = .clear
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(authManager: authManager) }

    final class Coordinator: NSObject {
        let authManager: OIDCAuthManager
        init(authManager: OIDCAuthManager) { self.authManager = authManager }

        @objc func tapped(_ sender: UIButton) {
            guard let window = sender.window else { return }
            Task { await authManager.login(presentationAnchor: window) }
        }
    }
}
