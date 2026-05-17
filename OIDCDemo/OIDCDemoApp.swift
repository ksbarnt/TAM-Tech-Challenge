import SwiftUI

// ── Root view: switches between Login and API Console ─────────────────────────

struct ContentView: View {

    @EnvironmentObject var authManager: OIDCAuthManager

    var body: some View {
        if authManager.isAuthenticated {
            APIConsoleView(authManager: authManager)
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            LoginView()
                .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
}

// ── App entry point ───────────────────────────────────────────────────────────

@main
struct OIDCDemoApp: App {

    @StateObject private var authManager = OIDCAuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
                // Handle the redirect URI coming back from the browser
                .onOpenURL { url in
                    // ASWebAuthenticationSession intercepts the callback internally,
                    // but if you use a universal link redirect this is where you'd
                    // forward it: authManager.handleCallback(url)
                    _ = url
                }
        }
    }
}
