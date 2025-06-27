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
                Button(action: login) {
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
                let client = createJellyfinClient()
                
                let authRequest = Paths.authenticateUserByName(
                    AuthenticateUserByName(
                        pw: password.isEmpty ? nil : password, username: username
                    )
                )
                
                let response = try await client.send(authRequest)
                let authResult = response.value
                
                if let accessToken = authResult.accessToken,
                   let userData = authResult.user {
                    let user = User(
                        id: userData.id ?? UUID().uuidString,
                        serverID: server.id,
                        username: username,
                        accessToken: accessToken
                    )
                    
                    dataManager.addUser(user)
                    dataManager.signIn(user: user)
                    
                    // Navigate to logged in view
                    // This will be handled by the ContentView based on currentUser state
                } else {
                    alertMessage = "Login failed - no access token received"
                    showingAlert = true
                }
                isLoggingIn = false
                
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
                isLoggingIn = false
            }
        }
    }
    
    private func createJellyfinClient() -> JellyfinClient {
        let configuration = JellyfinClient.Configuration(url: server.url,
                                                         client: "client",
                                                         deviceName: "deviceName",
                                                         deviceID: "deviceID",
                                                         version: "version")
        
        return JellyfinClient(configuration: configuration)
    }
}
