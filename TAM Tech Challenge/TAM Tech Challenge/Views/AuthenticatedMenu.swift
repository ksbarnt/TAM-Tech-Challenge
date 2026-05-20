//
//  AuthenticatedMenu.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct AuthenticatedMenu: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    @State private var isAdmin: Bool = false
    @State private var apiFailed: Bool = false
    @State private var apiError: String = ""
    @State private var authenticatedUser: OktaUser?
    
    var body: some View {
        TabView {
            if let authenticatedUser {
                AuthenticatedHome(oktaUser: authenticatedUser)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
            } else {
                VStack {
                    Spacer()
                    Text("Loading User Information...")
                    Spacer()
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
//                            .frame(maxWidth: .infinity)
                            .padding(5)
                    }
                    .buttonStyle(.glassProminent)
                }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
            }
            
            if isAdmin {
                if let authenticatedUser {
                    NavigationStack {
                        UserActions(authenticatedUser: authenticatedUser)
                            .navigationTitle("User Actions")
                    }
                        .tabItem {
                            Label("User Actions", systemImage: "person.crop.circle.fill")
                        }
                    GroupAssignment(authenticatedUser: authenticatedUser)
                        .tabItem {
                            Label("Group Assignment", systemImage: "person.2.badge.plus.fill")
                        }
                }
            }
        }
        .task {
            await getUserInfo()
        }
    }
    
    func getUserInfo() async {
        do {
            let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
            let userData = try await client.get("/api/v1/users/me")
            if !userData.isEmpty {
                let oktaUser = try JSONDecoder.okta.decode(OktaUser.self, from: userData)
                authenticatedUser = oktaUser
                let groupData = try await client.get("/api/v1/users/\(oktaUser.id)/groups")
                if !groupData.isEmpty {
                    let groups = try JSONDecoder.okta.decode([OktaGroup].self, from: groupData)
                    isAdmin = groups.contains { $0.id == "00g133fhpc2Ke6XOG698" }
                }
            }
        } catch {
            apiFailed = true
            apiError = error.localizedDescription
        }
    }
}

#Preview {
    AuthenticatedMenu()
}
