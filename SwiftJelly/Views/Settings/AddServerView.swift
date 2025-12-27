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
                        .autocorrectionDisabled()
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(role: .confirm) {
                        saveAndAuthenticate()
                    } label: {
                        HStack {
                            Spacer()
                            if isAuthenticating {
                                ProgressView()
                            } else {
                                Text("Connect")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .contentShape(.rect)
                    }
                    .buttonSizing(.flexible)
                    .buttonStyle(.plain)
                    .disabled(serverName.isEmpty || serverURL.isEmpty || username.isEmpty || isAuthenticating)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Server")
            .toolbarTitleDisplayMode(.inline)
            #if os(iOS)
            .toolbar {
                Button(role: .close) { dismiss() }
            }
            #endif
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
                let authResult = try await JFAPI.authenticateUser(
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
