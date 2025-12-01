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
    #if !os(tvOS)
    @Namespace private var transition
    #endif
    
    var body: some View {
        #if os(tvOS)
        tvOSServerList
        #else
        standardServerList
        #endif
    }
    
    #if os(tvOS)
    private var tvOSServerList: some View {
        List {
            ForEach(dataManager.servers) { server in
                Button {
                    dataManager.selectServer(server)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: server.id == dataManager.activeServerID ? "checkmark.circle.fill" : "server.rack")
                            .font(.title2)
                            .foregroundStyle(server.id == dataManager.activeServerID ? .green : .accent)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(.headline)
                            if let username = server.username {
                                Text(username)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(server.url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        if server.id == dataManager.activeServerID {
                            Text("Active")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { dataManager.deleteServer(dataManager.servers[$0]) }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Servers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    AddServerView()
                } label: {
                    Label("Add Server", systemImage: "plus")
                }
            }
        }
    }
    #endif
    
    private var standardServerList: some View {
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
                #if !os(tvOS)
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        dataManager.deleteServer(server)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                #endif
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
            #if !os(macOS) && !os(tvOS)
            .matchedTransitionSource(id: "add-server-button", in: transition)
            #endif
        }
        .sheet(isPresented: $showAddSheet) {
            AddServerView()
                #if !os(macOS) && !os(tvOS)
                .navigationTransition(.zoom(sourceID: "add-server-button", in: transition))
                #endif
                #if !os(tvOS)
                .presentationDetents([.medium])
                #endif
        }
    }
}

#Preview {
    ServerList()
}
