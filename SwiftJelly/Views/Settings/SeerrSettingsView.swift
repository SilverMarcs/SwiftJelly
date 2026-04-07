//
//  SeerrSettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 07/04/2026.
//

import SwiftUI

struct SeerrSettingsView: View {
    @AppStorage("seerrServerURL") private var seerrServerURL = ""
    @AppStorage("seerrAuthenticated") private var seerrAuthenticated = false
    @State private var connectionStatus: SeerrConnectionStatus = .idle
    @State private var showingLogin = false

    var body: some View {
        Section {
            if seerrAuthenticated {
                connectedView
            } else {
                loginSection
            }
        } header: {
            Text("Seerr")
        } footer: {
            Text("Connect to a Seerr (Jellyseer) server to discover trending content and request media.")
        }
        .task {
            if seerrAuthenticated, let url = URL(string: seerrServerURL) {
                do {
                    let user = try await SeerrAPI.validateConnection(serverURL: url)
                    connectionStatus = .connected(user)
                } catch {
                    connectionStatus = .failed
                    seerrAuthenticated = false
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            if let url = URL(string: seerrServerURL) {
                SeerrLoginWebView(serverURL: url) { user in
                    connectionStatus = .connected(user)
                }
                #if os(macOS)
                .frame(minWidth: 500, minHeight: 600)
                #endif
            }
        }
    }

    // MARK: - Login Section

    @ViewBuilder
    private var loginSection: some View {
        TextField("Server URL", text: $seerrServerURL)
            .textContentType(.URL)
            .autocorrectionDisabled()
            #if !os(macOS)
            .textInputAutocapitalization(.never)
            #endif

        Button {
            showingLogin = true
        } label: {
             Text("Sign In")
        }
        #if !os(macOS)
        .buttonSizing(.flexible)
        #else
        .buttonStyle(.plain)
        #endif
        .disabled(seerrServerURL.isEmpty)
    }

    // MARK: - Connected View

    @ViewBuilder
    private var connectedView: some View {
        HStack {
            VStack(alignment: .leading) {
                if case .connected(let user) = connectionStatus {
                    Text(user.displayName ?? "Connected")
                        .fontWeight(.medium)
                }
                Text(seerrServerURL)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }

        Button("Sign Out", role: .destructive) {
            signOut()
        }
    }

    private func signOut() {
        if let url = URL(string: seerrServerURL) {
            Task {
                await SeerrAPI.logout(serverURL: url)
            }
        }
        connectionStatus = .idle
        seerrServerURL = ""
    }
}

enum SeerrConnectionStatus {
    case idle
    case checking
    case connected(SeerrUser)
    case failed
}
