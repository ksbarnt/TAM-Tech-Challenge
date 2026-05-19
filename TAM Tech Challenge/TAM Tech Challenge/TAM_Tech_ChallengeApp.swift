//
//  TAM_Tech_ChallengeApp.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

@main
struct TAM_Tech_ChallengeApp: App {
    
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
