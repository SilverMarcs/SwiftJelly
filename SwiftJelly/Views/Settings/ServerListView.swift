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
                    NavigationLink(destination: UserLoginView(server: server)) {
                        Label {
                            Text(server.name)
                            Text(server.url.absoluteString)
                        } icon: {
                            Image(systemName: "server.rack")
                        }
                    }
                    Spacer()
                    Button {
                        editingServer = server
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete(perform: deleteServers)
        }
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
