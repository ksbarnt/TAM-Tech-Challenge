//
//  UserActions.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct UserActions: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    
    @Bindable var authenticatedUser: OktaUser
    
    @State private var oktaUsers: [OktaUser] = []
    @State private var apiFailed: Bool = false
    @State private var apiError: String = ""
    @State private var viewID = UUID()
    
    var body: some View {
        ZStack {
            Text("Loading active users...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(oktaUsers.isEmpty && !apiFailed ? 5 : -5)
            Text("There was an API error loading active users: \(apiError)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(apiFailed && oktaUsers.isEmpty ? 10 : -10)
            List {
                ForEach(oktaUsers) { user in
                    NavigationLink(value: user) {
                        VStack(alignment: .leading){
                            Text("\(user.profile.firstName ?? "<no first name>") \(user.profile.lastName ?? "<no last name>")")
                                .font(.headline)
                            Text("\(user.profile.login)")
                        }
                    }
                }
            }
        }
        .task {
            oktaUsers = []
            await loadActiveUsers()
        }
        .alert(
            "API Error",
            isPresented: $apiFailed
        ) {
            Button("OK") {
                apiFailed = false
                apiError = ""
            }
        } message: {
            Text(apiError)
        }
        .toolbar {
            NavigationLink(destination: NewUserView(parentID: $viewID)) {
                Button(action: { }) {
                    Label("New User", systemImage: "person.badge.plus")
                }
            }
        }
        .id(viewID)
    }
    
    func loadActiveUsers() async {
        do {
            let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
            let queryItems: [URLQueryItem] = [URLQueryItem(name: "search", value: "status eq \"ACTIVE\" or status eq \"PROVISIONED\"")]
            let usersData = try await client.get("/api/v1/users", queryItems: queryItems)
            let users: [OktaUser] = try JSONDecoder.okta.decode([OktaUser].self, from: usersData)
            oktaUsers = users
        } catch {
            if error.localizedDescription != "cancelled" {
                apiFailed = true
                apiError = error.localizedDescription
            } else {
                await loadActiveUsers()
            }
        }
    }
}

