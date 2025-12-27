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
        Form {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .buttonSizing(.flexible) // not doign anything yet so need to kee maxwidth above
                .contextMenu {
                    Button(role: .destructive) {
                        dataManager.deleteServer(server)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Servers")
        .toolbar {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
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
