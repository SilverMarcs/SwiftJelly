//
//  ServerList.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

/// Top level of the "Profiles & Servers" settings: one row per server. Tapping
/// a server opens its accounts, where profiles can be switched, added or removed.
struct ServerList: View {
    private var dataManager = DataManager.shared

    var body: some View {
        SettingsSplitView {
            content
        } infoPanel: {
            infoPanel
        }
        .navigationTitle("Profiles & Servers")
        .platformNavigationToolbar(titleDisplayMode: .inline)
        .toolbar {
            NavigationLink(value: ServerListRoute.addServer) {
                Label("Add Server", systemImage: "plus")
            }
        }
        .navigationDestination(for: ServerListRoute.self) { route in
            switch route {
            case .addServer:
                AddServerView()
            case .serverDetail(let url):
                ServerDetailView(serverURL: url)
            case .addAccount(let name, let url):
                AddServerView(existingServerName: name, existingServerURL: url)
            }
        }
    }

    private var infoPanel: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 200))
                .foregroundStyle(.secondary)

            Text("Profiles & Servers")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - tvOS

    #if os(tvOS)
    /// A vertically-centered column of full-width server cards that fills the
    /// content side of the split view, rather than the cramped grouped `Form`
    /// tvOS renders. Selecting a server opens its accounts; "Add Server" pushes a
    /// separate page.
    private var content: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(dataManager.serverGroups) { group in
                    NavigationLink(value: ServerListRoute.serverDetail(url: group.url)) {
                        serverCard(group)
                    }
                    .buttonStyle(.card)
                }

                NavigationLink(value: ServerListRoute.addServer) {
                    addServerCard
                }
                .buttonStyle(.card)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    private func serverCard(_ group: ServerGroup) -> some View {
        let containsActive = group.profiles.contains { $0.id == dataManager.activeServerID }

        return HStack(spacing: 24) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(containsActive ? .green : .secondary)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text(group.url.host() ?? group.url.absoluteString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Text(accountCountText(group.profiles.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private var addServerCard: some View {
        HStack(spacing: 24) {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 44)

            Text("Add Server")
                .font(.headline)

            Spacer(minLength: 16)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
    #else

    // MARK: - iOS / macOS

    private var content: some View {
        Form {
            Section("Servers") {
                ForEach(dataManager.serverGroups) { group in
                    NavigationLink(value: ServerListRoute.serverDetail(url: group.url)) {
                        serverRow(group)
                    }
                }
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
    }

    private func serverRow(_ group: ServerGroup) -> some View {
        let containsActive = group.profiles.contains { $0.id == dataManager.activeServerID }

        return HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.title3)
                .foregroundStyle(containsActive ? .green : .secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                Text(group.url.host() ?? group.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(accountCountText(group.profiles.count))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private func accountCountText(_ count: Int) -> String {
        count == 1 ? "1 account" : "\(count) accounts"
    }
}

/// Navigation values for the "Profiles & Servers" settings stack.
enum ServerListRoute: Hashable {
    case addServer
    case serverDetail(url: URL)
    case addAccount(serverName: String, url: URL)
}

#Preview {
    ServerList()
}
