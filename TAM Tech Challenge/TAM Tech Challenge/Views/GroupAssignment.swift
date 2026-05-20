//
//  GroupAssignment.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct GroupAssignment: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    
    @Bindable var authenticatedUser: OktaUser
    
    @State var oktaUsers: [OktaUser] = []
    @State var apiFailed: Bool = false
    @State var apiError: String = ""
    @State var selectedUserID: String = ""
    @State var selectedGroupID: String = ""
    @State var assignmentSuccessful: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Form {
                    Picker("Select User", selection: $selectedUserID) {
                        Text("Select a User").tag("")
                        ForEach(oktaUsers) { user in
                            if user.id != authenticatedUser.id {
                                Text("\(user.profile.firstName ?? "") \(user.profile.lastName ?? "")").tag(user.id)
                            }
                        }
                    }
                    Picker("Select Group", selection: $selectedGroupID) {
                        Text("Select a Group").tag("")
                        Text("Mobile IAM Admins").tag("00g133fhpc2Ke6XOG698")
                        Text("Salesforce Users").tag("00g1337nat2H4yX3C698")
                    }
                }
                Button(role: .confirm, action: { assignUserToGroup() }) {
                    Label("Assign User to Group", systemImage: "person.2.badge.plus")
                        .padding(5)
                        .foregroundStyle(.black)
                }
                .disabled(selectedUserID.isEmpty || selectedGroupID.isEmpty)
                .buttonStyle(.glassProminent)
                Spacer()
            }
            .zIndex(1.0)
            VStack {
                Label("Assignment Successful!", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }
            .background(.ultraThinMaterial)
            .zIndex(assignmentSuccessful ? 2.0 : -2.0)
        }
        .task {
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
    }
    
    func loadActiveUsers() async {
        do {
            selectedUserID = ""
            selectedGroupID = ""
            let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
            let queryItems: [URLQueryItem] = [URLQueryItem(name: "search", value: "status eq \"ACTIVE\" or status eq \"PROVISIONED\"")]
            let usersData = try await client.get("/api/v1/users", queryItems: queryItems)
            let users: [OktaUser] = try JSONDecoder.okta.decode([OktaUser].self, from: usersData)
            oktaUsers = users
        } catch {
            apiFailed = true
            apiError = error.localizedDescription
        }
    }
    
    func assignUserToGroup() {
        Task {
            do {
                let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
                let response = try await client.put("/api/v1/groups/\(selectedGroupID)/users/\(selectedUserID)")
                selectedUserID = ""
                selectedGroupID = ""
                assignmentSuccessful = true
                try await Task.sleep(for: .seconds(3))
                assignmentSuccessful = false
            } catch {
                apiFailed = true
                apiError = error.localizedDescription
            }
        }
    }
}

//#Preview {
//    GroupAssignment()
//}
