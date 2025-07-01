//
//  ServerFormView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 01/07/2025.
//

import SwiftUI
import JellyfinAPI

struct ServerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = DataManager.shared
    
    var serverToEdit: Server?
    var onSave: ((Server) -> Void)?
    
    @State private var serverName: String = ""
    @State private var serverURL: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        Form {
            Section("Server Details") {
                TextField("Server Name", text: $serverName)
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
            }

            Section("Authentication") {
                TextField("Username", text: $username)
                    .disableAutocorrection(true)
                SecureField("Password", text: $password)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(serverToEdit == nil ? "Add Server" : "Edit Server")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(serverToEdit == nil ? "Add" : "Save") {
                    saveServer()
                }
                .disabled(serverName.isEmpty || serverURL.isEmpty || (serverToEdit == nil && (username.isEmpty || isAuthenticating)))
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if let server = serverToEdit {
                serverName = server.name
                serverURL = server.url.absoluteString
                username = server.username ?? ""
                // Don't populate password for security
            }
        }
    }
    
    private func saveServer() {
        guard let url = URL(string: serverURL) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }

        if var editing = serverToEdit {
            // For editing existing server
            editing.name = serverName
            editing.url = url

            // If username/password provided, authenticate
            if !username.isEmpty && !password.isEmpty {
                authenticateAndSave(server: editing)
            } else {
                // Just update server details without authentication
                editing.username = username.isEmpty ? editing.username : username
                dataManager.updateServer(editing)
                onSave?(editing)
                dismiss()
            }
        } else {
            // For new server, authentication is required
            let server = Server(name: serverName, url: url)
            authenticateAndSave(server: server)
        }
    }

    private func authenticateAndSave(server: Server) {
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

                    if serverToEdit != nil {
                        dataManager.updateServer(authenticatedServer)
                    } else {
                        dataManager.addServer(authenticatedServer)
                        dataManager.signIn(server: authenticatedServer)
                    }

                    onSave?(authenticatedServer)
                    isAuthenticating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isAuthenticating = false
                }
            }
        }
    }
}
