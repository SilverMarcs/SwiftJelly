//
//  ServerListView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ServerListView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingAddServer = false
    
    var body: some View {
        List {
            ForEach(dataManager.servers) { server in
                NavigationLink(destination: UserLoginView(server: server)) {
                    Label {
                        Text(server.name)
                        Text(server.url.absoluteString)
                    } icon: {
                        Image(systemName: "server.rack")
                    }
                }
            }
            .onDelete(perform: deleteServers)
        }
        .navigationTitle("Servers")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Server") {
                    showingAddServer = true
                }
            }
        }
        .sheet(isPresented: $showingAddServer) {
            AddServerView()
        }
    }
    
    private func deleteServers(offsets: IndexSet) {
        for offset in offsets {
            dataManager.removeServer(dataManager.servers[offset])
        }
    }
}
