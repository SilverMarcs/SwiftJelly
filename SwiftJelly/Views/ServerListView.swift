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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(.headline)
                            Text(server.url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteServers)
            }
            .navigationTitle("Servers")
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
            .overlay {
                if dataManager.servers.isEmpty {
                    VStack(spacing: 16) {
                        Text("No Servers")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Button("Add Your First Server") {
                            showingAddServer = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
    }
    
    private func deleteServers(offsets: IndexSet) {
        for offset in offsets {
            dataManager.removeServer(dataManager.servers[offset])
        }
    }
}
