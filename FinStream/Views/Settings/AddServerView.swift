import SwiftUI
import JellyfinAPI

struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss

    private var dataManager = DataManager.shared

    /// When adding an account to an existing server, its name and URL are fixed
    /// and only credentials are requested.
    private let isAddingAccount: Bool

    @State private var serverName: String
    @State private var serverURL: String
    @State private var username = ""
    @State private var password = ""

    @State private var isAuthenticating = false

    @State private var alertMessage = ""
    @State private var showingAlert = false

    /// The server being connected via Quick Connect, if any. Non-nil presents the Quick Connect sheet.
    @State private var quickConnectServer: Server?

    /// Adds a brand-new server, or — when `existingServerURL` is supplied — a new
    /// account (profile) to an already-saved server, reusing its name and URL.
    init(existingServerName: String? = nil, existingServerURL: URL? = nil) {
        _serverName = State(initialValue: existingServerName ?? "")
        _serverURL = State(initialValue: existingServerURL?.absoluteString ?? "")
        isAddingAccount = existingServerURL != nil
    }

    private var title: LocalizedStringKey {
        isAddingAccount ? "Add Account" : "Add Server"
    }

    private var canSubmit: Bool {
        !serverName.isEmpty && !serverURL.isEmpty
    }

    var body: some View {
        SettingsSplitView {
            formContent
                .navigationTitle(title)
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
                .sheet(item: $quickConnectServer) { server in
                    QuickConnectView(server: server) { authenticatedServer in
                        dataManager.addServer(authenticatedServer)
                        dataManager.selectServer(authenticatedServer)
                        quickConnectServer = nil
                        dismiss()
                    }
                }
        } infoPanel: {
            VStack(spacing: 20) {
                Image(systemName: isAddingAccount ? "person.badge.plus" : "plus")
                    .font(.system(size: 200))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .platformNavigationToolbar(titleDisplayMode: .inline)
    }

    #if os(tvOS)
    /// A clean, consistently-styled vertical layout for tvOS, where the grouped `Form`
    /// renders inconsistent inline fields.
    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                if isAddingAccount {
                    fieldSection("Server") {
                        serverSummary
                    }
                } else {
                    fieldSection("Server Details") {
                        TextField("Server Name", text: $serverName)
                        TextField("Server URL", text: $serverURL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                fieldSection("Sign In") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    SecureField("Password", text: $password)
                        .textContentType(.password)

                    Button {
                        saveAndAuthenticate()
                    } label: {
                        connectLabel
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit || username.isEmpty || isAuthenticating)
                }

                fieldSection("Or") {
                    Button {
                        startQuickConnect()
                    } label: {
                        Label("Use Quick Connect", systemImage: "bolt.horizontal.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSubmit || isAuthenticating)
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    /// A clean, left-aligned summary of the fixed server when adding an account,
    /// instead of sparse right-aligned `LabeledContent` rows.
    private var serverSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(serverName)
                .font(.headline)
            Text(serverURL)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldSection<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
    }
    #else
    private var formContent: some View {
        Form {
            if isAddingAccount {
                Section("Server") {
                    LabeledContent("Name", value: serverName)
                    LabeledContent("Address", value: serverURL)
                }
            } else {
                Section("Server Details") {
                    TextField("Server Name", text: $serverName)
                    TextField("Server URL", text: $serverURL)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if !os(macOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
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
                    connectLabel
                        .contentShape(.rect)
                }
                .buttonSizing(.flexible)
                .buttonStyle(.plain)
                .disabled(!canSubmit || username.isEmpty || isAuthenticating)
            }
        }
        .formStyle(.grouped)
    }
    #endif

    private var connectLabel: some View {
        HStack {
            Spacer()
            if isAuthenticating {
                ProgressView()
                #if os(macOS)
                .controlSize(.small)
                #endif
            } else {
                Text("Connect")
                    .fontWeight(.semibold)
            }
            Spacer()
        }
    }

    private func startQuickConnect() {
        guard let server = makeServer() else { return }
        quickConnectServer = server
    }

    /// Builds a `Server` from the entered name and URL, surfacing an alert on an invalid URL.
    private func makeServer() -> Server? {
        guard let url = URL(string: serverURL) else {
            alertMessage = "Invalid URL"
            showingAlert = true
            return nil
        }
        return Server(name: serverName, url: url)
    }

    private func saveAndAuthenticate() {
        guard let server = makeServer() else { return }
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
