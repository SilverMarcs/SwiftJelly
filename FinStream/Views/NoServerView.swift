//
//  NoServerView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 12/12/2025.
//

import SwiftUI

struct NoServerView: View {
    var body: some View {
        #if os(tvOS)
        // Route the empty state into the same "Profiles & Servers" picker used in
        // settings, so login and management look consistent on tvOS. With no
        // servers saved yet, `ServerList` shows just the "Add Server" card.
        NavigationStack {
            ServerList()
        }
        #else
        NavigationStack {
            ContentUnavailableView {
                Label("No Server Found", systemImage: "server.rack")
            } description: {
                Text("Please connect to a Jellyfin server to continue.")
            } actions: {
                NavigationLink(value: NoServerRoute.addServer) {
                    Text("Add Server")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .navigationDestination(for: NoServerRoute.self) { _ in
                AddServerView()
            }
        }
        #endif
    }
}

/// Navigation value for pushing the add-server screen from the empty state.
enum NoServerRoute: Hashable {
    case addServer
}
