//
//  ProfileSidebarButton.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI

/// Header button shown at the top of the tab view sidebar on macOS, iPadOS and
/// tvOS. Displays the current user and server, and opens the server switcher.
struct ProfileSidebarButton: View {
    private var dataManager = DataManager.shared

    @State private var showingSwitcher = false

    var body: some View {
        Button {
            showingSwitcher = true
        } label: {
            HStack(spacing: 12) {
                if let server = dataManager.server {
                    UserAvatarView(server: server, size: avatarSize)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.username ?? server.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(server.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                    Text("Profile")
                        .font(.headline)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSwitcher) {
            ServerSwitcherView()
        }
    }

    private var avatarSize: CGFloat {
        #if os(tvOS)
        60
        #else
        36
        #endif
    }
}
