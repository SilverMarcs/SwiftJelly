//
//  ProfileToolbarMenu.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI

/// Toolbar profile control shown on every page in compact (iOS) layouts.
/// Tapping the avatar opens a menu to switch servers or open Settings.
struct ProfileToolbarMenu: View {
    @Binding var showingSettings: Bool

    private var dataManager = DataManager.shared

    init(showingSettings: Binding<Bool>) {
        _showingSettings = showingSettings
    }

    var body: some View {
        Menu {
            Section("Switch Server") {
                ForEach(dataManager.servers) { server in
                    Button {
                        dataManager.selectServer(server)
                    } label: {
                        Label(server.username ?? "User", systemImage: isSelectedServer(server: server) ? "checkmark.circle" : "person.crop.circle")
                        Text(server.name)
                    }
                    .tint(isSelectedServer(server: server) ? .green : nil)
                }
            }

            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            if let server = dataManager.server {
                UserAvatarView(server: server, size: 28)
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
    }
    
    
    private func isSelectedServer(server: Server) -> Bool {
        return server.id == dataManager.activeServerID
    }
}
