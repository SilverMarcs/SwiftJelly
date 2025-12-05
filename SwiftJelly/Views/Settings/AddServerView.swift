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
        #if os(tvOS)
        tvOSForm
        #else
        standardForm
        #endif
    }
    
    #if os(tvOS)
    private var tvOSForm: some View {
        Form {
            Section("Server Details") {
                TextField("Server Name", text: $serverName)
                TextField("Server URL", text: $serverURL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Section("Authentication") {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
            }
            
            Section {
                Button {
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
                }
                .disabled(serverName.isEmpty || serverURL.isEmpty || username.isEmpty || isAuthenticating)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Add Server")
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    #endif
    
    private var standardForm: some View {
        Group {
            Form {
                Section("Server Details") {
                    TextField("Server Name", text: $serverName)
                    TextField("Server URL", text: $serverURL)
                        .textContentType(.URL)
                }
                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
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
                    .disabled(serverName.isEmpty || serverURL.isEmpty || username.isEmpty || isAuthenticating)
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
