//
//  SeerrSettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 07/04/2026.
//

import SwiftUI

struct SeerrSettingsView: View {
    @Bindable private var auth = SeerrAuth.shared
    @State private var connectionStatus: SeerrConnectionStatus = .idle
    #if os(macOS)
    @State private var showingLogin = false
    #endif

    private var serverURLBinding: Binding<String> {
        Binding(
            get: { auth.serverURL },
            set: { auth.setServerURL($0) }
        )
    }

    var body: some View {
        Section {
            if auth.isAuthenticated {
                connectedView
            } else {
                loginSection
            }
        } header: {
            Text("Seerr")
        } footer: {
            Text("Connect to a Seerr (Jellyseer) server to discover trending content")
        }
        .task(id: auth.isAuthenticated) {
            if auth.isAuthenticated, let url = URL(string: auth.serverURL) {
                do {
                    let user = try await SeerrAPI.validateConnection(serverURL: url)
                    connectionStatus = .connected(user)
                } catch {
                    connectionStatus = .failed
                    auth.setAuthenticated(false)
                }
            }
        }
        #if os(macOS)
        .sheet(isPresented: $showingLogin) {
            if let url = URL(string: auth.serverURL) {
                NavigationStack {
                    SeerrLoginWebView(serverURL: url)
                }
                .frame(minWidth: 500, minHeight: 600)
            }
        }
        #endif
    }

    // MARK: - Login Section

    @ViewBuilder
    private var loginSection: some View {
        TextField("Server URL", text: serverURLBinding)
            .textContentType(.URL)
            .autocorrectionDisabled()
            #if !os(macOS)
            .textInputAutocapitalization(.never)
            #endif

        #if os(macOS)
        Button {
            showingLogin = true
        } label: {
            Label("Sign In", systemImage: "person.crop.circle.badge.plus")
                .labelStyle(.titleOnly)
        }
        .disabled(auth.serverURL.isEmpty)
        #else
        if let url = URL(string: auth.serverURL), !auth.serverURL.isEmpty {
            NavigationLink {
                SeerrLoginWebView(serverURL: url)
            } label: {
                Label("Sign In", systemImage: "person.crop.circle.badge.plus")
            }
        }
        #endif
    }

    // MARK: - Connected View

    @ViewBuilder
    private var connectedView: some View {
        Label {
            if case .connected(let user) = connectionStatus {
                Text(user.displayName ?? "Connected")
            } else {
                Text("Loading account")
            }
            Text(auth.serverURL)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }

        Button("Sign Out", role: .destructive) {
            signOut()
        }
    }

    private func signOut() {
        if let url = URL(string: auth.serverURL) {
            Task {
                await SeerrAPI.logout(serverURL: url)
            }
        }
        connectionStatus = .idle
        auth.setServerURL("")
    }
}

enum SeerrConnectionStatus {
    case idle
    case checking
    case connected(SeerrUser)
    case failed
}
