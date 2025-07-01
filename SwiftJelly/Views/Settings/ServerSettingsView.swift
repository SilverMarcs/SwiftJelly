//
//  ServerSettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI
import JellyfinAPI

struct ServerSettingsView: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    @State private var serverName: String = ""
    @State private var serverURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Server Name", text: $serverName)
                    TextField("Server URL", text: $serverURL)
                        .textContentType(.URL)
                }
                
                Section("Authentication") {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
                .sectionActions {
                    Button("Clear Server", role: .destructive) {
                        dataManager.clearServer()
                        clearForm()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Server Settings")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: toolbarPlacemen) {
                    if let server = dataManager.server, server.isAuthenticated {
                        Label("Authenticated", systemImage: "checkmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .foregroundColor(.green)
                    } else {
                        Label("Not Authenticated", systemImage: "xmark.circle.fill")
                            .labelStyle(.titleAndIcon) 
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveAndAuthenticate()
                    } label: {
                        if isAuthenticating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(serverName.isEmpty || serverURL.isEmpty || username.isEmpty || password.isEmpty || isAuthenticating)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentServerData()
            }
        }
    }
    
    var toolbarPlacemen: ToolbarItemPlacement {
        #if os(iOS)
        return .title
        #else
        return .principal
        #endif
    }
    
    private func loadCurrentServerData() {
        if let server = dataManager.server {
            serverName = server.name
            serverURL = server.url.absoluteString
            username = server.username ?? ""
            // Don't load password for security
        }
    }
    
    private func clearForm() {
        serverName = ""
        serverURL = ""
        username = ""
        password = ""
    }
    
    private func saveAndAuthenticate() {
        guard let url = URL(string: serverURL) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }
        
        let server = Server(name: serverName, url: url)
        
        isAuthenticating = true
        Task {
            do {
                let authResult = try await JFAPI.shared.authenticateUser(
                    username: username,
                    password: password,
                    server: server
                )
                
                await MainActor.run {
                    var authenticatedServer = server
                    authenticatedServer.username = authResult.username
                    authenticatedServer.accessToken = authResult.accessToken
                    authenticatedServer.jellyfinUserID = authResult.jellyfinUserID
                    
                    dataManager.setServer(authenticatedServer)
                    
                    isAuthenticating = false
                    password = "" // Clear password for security
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    ServerSettingsView()
}
