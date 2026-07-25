//
//  ServerSwitcherView.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI

/// The list of servers used to switch the active server (and thereby the
/// signed-in user). Reused as a sheet (`ServerSwitcherView`) on macOS/iPadOS
/// and as a sidebar page on tvOS.
struct ServerSwitcherList: View {
    private var dataManager = DataManager.shared

    /// Called after a server is selected, e.g. to dismiss a presenting sheet.
    var onSelect: (() -> Void)?

    var body: some View {
        Form {
            Section("Servers") {
                ForEach(dataManager.servers) { server in
                    Button {
                        dataManager.selectServer(server)
                        onSelect?()
                    } label: {
                        serverRow(server)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                NavigationLink {
                    AddServerView()
                } label: {
                    Label("Add Server", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
    }

    private func serverRow(_ server: Server) -> some View {
        HStack(spacing: 12) {
            UserAvatarView(server: server, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.username ?? server.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(server.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if server.id == dataManager.activeServerID {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}

/// Sheet presentation of the server switcher for macOS and iPadOS.
struct ServerSwitcherView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ServerSwitcherList(onSelect: { dismiss() })
                .navigationTitle("Switch Server")
                .platformNavigationToolbar(titleDisplayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ServerSwitcherView()
}
