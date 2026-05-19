//
//  ContentView.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: OIDCAuthManager

    var body: some View {
        if authManager.isAuthenticated {
            AuthenticatedMenu()
                .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            LoginView()
                .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
}

#Preview {
    ContentView()
}
