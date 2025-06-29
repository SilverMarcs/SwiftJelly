//
//  UserLoginView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI
import Get

struct UserLoginView: View {
    let server: Server
    
    @StateObject private var dataManager = DataManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Login to \(server.name)") {
                TextField("Username", text: $username)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
            }
            
            Section {
                Button(role: .confirm) {
                    login()
                } label: {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isLoggingIn ? "Logging in..." : "Login")
                    }
                }
                .disabled(username.isEmpty || isLoggingIn)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Login")
        .toolbarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func login() {
        isLoggingIn = true
        Task {
            do {
                let user = try await JellyfinAPIService.shared.authenticateUser(
                    username: username,
                    password: password,
                    server: server
                )
                dataManager.addUser(user)
                dataManager.signIn(user: user)
                // Navigation handled by ContentView
                isLoggingIn = false
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
                isLoggingIn = false
            }
        }
    }
}
