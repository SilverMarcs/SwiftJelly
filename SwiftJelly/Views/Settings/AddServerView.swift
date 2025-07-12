import SwiftUI
import JellyfinAPI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    private var dataManager = DataManager.shared
    @State private var serverName = ""
    @State private var serverURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isAuthenticating = false
    @State private var alertMessage = ""
    @State private var showingAlert = false

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
            }
            .formStyle(.grouped)
            .navigationTitle("Add Server")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        saveAndAuthenticate()
                    } label: {
                        if isAuthenticating {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(serverName.isEmpty || serverURL.isEmpty || username.isEmpty || password.isEmpty || isAuthenticating)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
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
                var authenticatedServer = server
                authenticatedServer.username = authResult.username
                authenticatedServer.accessToken = authResult.accessToken
                authenticatedServer.jellyfinUserID = authResult.jellyfinUserID
                dataManager.addServer(authenticatedServer)
                dataManager.selectServer(authenticatedServer)
                isAuthenticating = false
                dismiss()
            } catch {
                isAuthenticating = false
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}
