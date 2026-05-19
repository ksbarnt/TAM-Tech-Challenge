//
//  AuthenticatedHome.swift
//  TAM Tech Challenge
//
//  Created by Kenny Barnt on 2026-05-17.
//

import SwiftUI

struct AuthenticatedHome: View {
    
    @EnvironmentObject var authManager: OIDCAuthManager
    @Bindable var oktaUser: OktaUser
    
    var body: some View {
        VStack {
            Spacer()
            Text("Hello, \(oktaUser.profile.firstName ?? "<no first name>")!")
                .font(.largeTitle.bold())
            Spacer()
            Button(role: .destructive) {
                authManager.logout()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
//                    .frame(maxWidth: .infinity)
                    .padding(5)
            }
            .buttonStyle(.glassProminent)
        }
    }
}

//#Preview {
//    AuthenticatedHome()
//}
