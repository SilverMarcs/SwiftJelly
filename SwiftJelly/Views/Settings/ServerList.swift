//
//  ServerList.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

struct ServerList: View {
    private var dataManager = DataManager.shared
    @State private var showAddSheet = false
    
    var body: some View {
        List {
            ForEach(dataManager.servers) { server in
                Button {
                    dataManager.selectServer(server)
                } label: {
                    Label {
                        Text("\(server.name) (\(server.username ?? ""))")
                        Text(server.url.absoluteString)
                    } icon: {
                        Image(systemName: server.id == dataManager.activeServerID ? "checkmark.circle.fill" : "server.rack")
                            .foregroundStyle(server.id == dataManager.activeServerID ? .green : .accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let server = dataManager.servers[index]
                    dataManager.deleteServer(server)
                }
            }
        }
        .scrollDisabled(true)
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddServerView()
        }
    }
}

#Preview {
    ServerList()
}
