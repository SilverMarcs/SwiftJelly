//
//  ServerDetailView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 29.07.26.
//

import SwiftUI

/// The accounts (profiles) signed in on a single server. Profiles can be
/// switched to, removed, or a new account added — all scoped to this server.
struct ServerDetailView: View {
    private var dataManager = DataManager.shared

    let serverURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var editingGroup: ServerGroup?

    /// Recomputed from the live server list so adding/removing accounts updates
    /// the view immediately.
    private var group: ServerGroup? {
        dataManager.serverGroups.first { $0.url == serverURL }
    }

    var body: some View {
        Form {
            if let group {
                Section("Accounts") {
                    ForEach(group.profiles) { profile in
                        accountRow(profile)
                    }

                    NavigationLink(value: ServerListRoute.addAccount(serverName: group.name, url: group.url)) {
                        Label("Add Account", systemImage: "person.badge.plus")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        for profile in group.profiles {
                            dataManager.deleteServer(profile)
                        }
                        dismiss()
                    } label: {
                        Label("Remove Server", systemImage: "trash")
                    }
                } footer: {
                    Text(group.url.absoluteString)
                }
            } else {
                ContentUnavailableView("Server Removed", systemImage: "server.rack")
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.top, 10)
        #endif
        .navigationTitle(group?.name ?? "Server")
        .platformNavigationToolbar(titleDisplayMode: .inline)
        .toolbar {
            if let group {
                Button {
                    editingGroup = group
                } label: {
                    Label("Edit Server", systemImage: "pencil")
                }
            }
        }
        .sheet(item: $editingGroup) { group in
            EditServerView(group: group)
        }
    }

    private func accountRow(_ server: Server) -> some View {
        let selected = server.id == dataManager.activeServerID

        return Button {
            dataManager.selectServer(server)
        } label: {
            HStack(spacing: 12) {
                UserAvatarView(server: server, size: 36, isSelected: selected)

                VStack(alignment: .leading, spacing: 2) {
                    Text(server.username ?? "User")
                    if selected {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .tint(.primary)
        #if os(iOS)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                dataManager.deleteServer(server)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        #endif
        .contextMenu {
            Button(role: .destructive) {
                dataManager.deleteServer(server)
            } label: {
                Label("Remove Account", systemImage: "trash")
            }
        }
    }
}
