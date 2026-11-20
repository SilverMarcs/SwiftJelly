//
//  NoServerView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 12/12/2025.
//

import SwiftUI

struct NoServerView: View {
    var body: some View {
        NavigationStack {
            #if os(tvOS)
            ServerList()
            #else
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
            #endif
        }
    }
}

enum NoServerRoute: Hashable {
    case addServer
}
