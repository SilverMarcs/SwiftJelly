//
//  ServerList.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 10/07/2025.
//

import SwiftUI

struct ServerList: View {
    private var dataManager = DataManager.shared
    
    var body: some View {
        SettingsSplitView {
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
                                .foregroundStyle(server.id == dataManager.activeServerID ? .green : .primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .tint(.primary)
                    .buttonSizing(.flexible) // not doing anything yet so need to kee maxwidth above
                    .contextMenu {
                        Button(role: .destructive) {
                            dataManager.deleteServer(server)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                #if os(tvOS)
                NavigationLink {
                    AddServerView()
                } label: {
                    Label("Add Server", systemImage: "plus")
                }
                #endif
            }
            .formStyle(.grouped)
            #if os(tvOS)
            .safeAreaPadding(.leading, 40)
            #endif
            #if os(iOS)
            .contentMargins(.top, 10)
            #endif

        } infoPanel: {
            VStack(spacing: 20) {
                Image(systemName: "server.rack")
                    .font(.system(size: 200))
                    .foregroundStyle(.secondary)
                
                Text("Servers")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Servers")
        .platformNavigationToolbar(titleDisplayMode: .inline)
        .toolbar {
            NavigationLink {
                AddServerView()
            } label: {
                Label("Add Server", systemImage: "plus")
            }
        }
    }
}

#Preview {
    ServerList()
}
