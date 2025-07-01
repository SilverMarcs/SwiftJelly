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
    @State private var editingServer: Server? = nil

    var body: some View {
        List {
            ForEach(dataManager.servers) { server in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "server.rack")
                            Text(server.name)
                                .font(.headline)

                            if server.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }

                        Text(server.url.absoluteString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let username = server.username {
                            Text("User: \(username)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if server.isAuthenticated {
                        Button("Sign In") {
                            dataManager.signIn(server: server)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    Button {
                        editingServer = server
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteServers)
        }
        .listStyle(.inset)
        .navigationTitle("Servers")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Server") {
                    showingAddServer = true
                }
            }
        }
        .sheet(isPresented: $showingAddServer) {
            ServerFormView()
        }
        .sheet(item: $editingServer) { server in
            ServerFormView(serverToEdit: server)
        }
    }

    private func deleteServers(offsets: IndexSet) {
        for offset in offsets {
            dataManager.removeServer(dataManager.servers[offset])
        }
    }
}
