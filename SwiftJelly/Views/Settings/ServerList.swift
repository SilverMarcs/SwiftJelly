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
    @Namespace private var transition
    
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
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            #if !os(macOS)
            .matchedTransitionSource(id: "add-server-button", in: transition)
            #endif
        }
        .sheet(isPresented: $showAddSheet) {
            AddServerView()
                #if !os(macOS)
                .navigationTransition(.zoom(sourceID: "add-server-button", in: transition))
                #endif
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    ServerList()
}
