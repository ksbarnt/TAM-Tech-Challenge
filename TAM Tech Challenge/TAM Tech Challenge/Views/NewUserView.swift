//
//  NewUserView.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-18.
//

import SwiftUI

struct NewUserView: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding var parentID: UUID
    
    @State private var login: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var secondEmail: String = ""
    @State private var mobilePhone: String = ""
    @State private var createFailed: Bool = false
    @State private var createError: String = ""
    
    var body: some View {
        VStack {
            Form {
                Section("First Name") {
                    TextField("First Name", text: $firstName)
                }
                Section("Last Name") {
                    TextField("Last Name", text: $lastName)
                }
                Section("Login") {
                    TextField("Login", text: $login)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                Section("Email") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                Section("Second Email") {
                    TextField("Second Email", text: $secondEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                Section("Mobile Phone") {
                    TextField("Mobile Phone", text: $mobilePhone)
                        .keyboardType(.phonePad)
                }
            }
            Button(role: .confirm) {
                Task {
                    await createUser()
                }
            } label: {
                Label("Create user", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.black)
            }
            .buttonStyle(.glassProminent)
        }
        .alert(
            "There was an error creating the user: \(createError)",
            isPresented: $createFailed
        ) {
            Button("OK") {
                createFailed.toggle()
            }
        }
    }
    
    func createUser() async {
        do {
            struct CreateUserProfile: Encodable {
                let firstName: String
                let lastName: String
                let login: String
                let email: String
                let secondEmail: String
                let mobilePhone: String
            }
            
            struct CreateUser: Encodable {
                let profile: CreateUserProfile
            }
            
            let createProfile = CreateUserProfile(firstName: firstName, lastName: lastName, login: login, email: email, secondEmail: secondEmail, mobilePhone: mobilePhone)
            let createUser = CreateUser(profile: createProfile)
            
            let client = AuthenticatedAPIClient(authManager: authManager, baseURL: OIDCConfig.apiBaseURL)
            
            let queryItems: [URLQueryItem] = [URLQueryItem(name: "activate", value: "true")]
            let userUpdate = try await client.post("/api/v1/users", body: createUser, queryItems: queryItems)
            if !userUpdate.isEmpty {
                parentID = UUID()
                dismiss()
            }
        } catch {
            createError = error.localizedDescription
            createFailed = true
        }
    }
}
