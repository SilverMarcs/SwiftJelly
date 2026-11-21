//
//  ProfileSidebarButton.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 25.07.26.
//

import SwiftUI

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
        #if os(tvOS)
        .buttonStyle(SidebarHeaderButtonStyle())
        .fullScreenCover(isPresented: $showingSwitcher) {
            ServerSwitcherView()
        }
        #else
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSwitcher) {
            ServerSwitcherView()
        }
        #endif
    }

    private var avatarSize: CGFloat {
        #if os(tvOS)
        60
        #else
        30
        #endif
    }
}

#if os(tvOS)
/// Matches the system sidebar rows: an in-bounds highlight on focus instead of
/// the plain style's lift, which scaled the full-width row past the sidebar edges.
private struct SidebarHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SidebarHeaderButtonBody(configuration: configuration)
    }
}

private struct SidebarHeaderButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundStyle(isFocused ? Color.black : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
                    .opacity(isFocused ? 1 : 0)
            }
            // Same small lift as the system rows (320pt → 328pt), which keeps it inside the sidebar.
            .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.025 : 1))
            .animation(.easeOut(duration: 0.15), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
#endif
