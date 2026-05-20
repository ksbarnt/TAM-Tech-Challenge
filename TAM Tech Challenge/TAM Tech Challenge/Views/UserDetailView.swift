//
//  UserDetailView.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct UserDetailView: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var parentID: UUID
    
    @Bindable var oktaUser: OktaUser
    @Bindable var authenticatedUser: OktaUser
    
    @State private var login: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var secondEmail: String = ""
    @State private var mobilePhone: String = ""
    @State private var userSaved: Bool = false
    @State private var updateFailed: Bool = false
    @State private var updateError: String = ""
    @State private var deactivating: Bool = false
    @State private var deactivated: Bool = false
    @State private var isMe: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section("First Name") {
                        TextField("First Name", text: $firstName)
                            .disabled(isMe)
                    }
                    Section("Last Name") {
                        TextField("Last Name", text: $lastName)
                            .disabled(isMe)
                    }
                    Section("Login") {
                        TextField("Login", text: $login)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disabled(isMe)
                    }
                    Section("Email") {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disabled(isMe)
                    }
                    Section("Second Email") {
                        TextField("Second Email", text: $secondEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .disabled(isMe)
                    }
                    Section("Mobile Phone") {
                        TextField("Mobile Phone", text: $mobilePhone)
                            .keyboardType(.phonePad)
                            .disabled(isMe)
                    }
                }
                Button(role: .confirm) {
                    Task {
                        await updateUser()
                    }
                } label: {
                    Label("Save Changes", systemImage: "icloud.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.black)
                }
                .buttonStyle(.glassProminent)
                .disabled(isMe)
            }
            .zIndex(1)
            VStack {
                Label("Changes Saved!", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }
            .background(.ultraThinMaterial)
            .zIndex(userSaved ? 2 : -2)
            VStack {
                Label("User Deactivated!", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            }
            .background(.ultraThinMaterial)
            .zIndex(deactivated ? 3 : -3)
        }
        .onAppear() {
            login = oktaUser.profile.login
            firstName = oktaUser.profile.firstName ?? ""
            lastName = oktaUser.profile.lastName ?? ""
            email = oktaUser.profile.email
            secondEmail = oktaUser.profile.secondEmail ?? ""
            mobilePhone = oktaUser.profile.mobilePhone ?? ""
            isMe = oktaUser.id == authenticatedUser.id
            parentID = UUID()
        }
        .toolbar {
            Button(role: .destructive, action: { deactivating = true }) {
                Label("Deactivate User", systemImage: "trash")
            }
            .disabled(isMe)
            .alert("Deactivate User", isPresented: $deactivating) {
                Button("Cancel", role: .cancel) { deactivating  = false }
                Button("Deactivate User", role: .destructive) { deactivateUser() }
            } message: {
                Text("Are you sure you want to deactivate \(oktaUser.profile.login)?")
            }
        }
        .alert(
            "There was an error updaing the user: \(updateError)",
            isPresented: $updateFailed
        ) {
            Button("OK") {
                updateFailed.toggle()
            }
        }
    }
    
    func updateUser() async {
        do {
            struct UpdateUserProfile: Encodable {
                let firstName: String
                let lastName: String
                let login: String
                let email: String
                let secondEmail: String
                let mobilePhone: String
            }
            
            struct UpdateUser: Encodable {
                let profile: UpdateUserProfile
            }
            
            let updateProfile = UpdateUserProfile(firstName: firstName, lastName: lastName, login: login, email: email, secondEmail: secondEmail, mobilePhone: mobilePhone)
            let updateUser = UpdateUser(profile: updateProfile)
            
            let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
            let userUpdate = try await client.post("/api/v1/users/\(oktaUser.id)", body: updateUser)
            if !userUpdate.isEmpty {
                userSaved = true
                try await Task.sleep(for: .seconds(3))
                userSaved = false
            }
        } catch {
            updateError = error.localizedDescription
            updateFailed = true
        }
    }
    
    func deactivateUser() {
        Task {
            do {
                let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
                let userDeactivate = try await client.delete("/api/v1/users/\(oktaUser.id)")
                dismiss()
            } catch {
                
            }
        }
    }
}
