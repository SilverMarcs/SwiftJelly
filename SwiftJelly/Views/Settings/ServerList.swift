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
                    .buttonSizing(.flexible) // not doign anything yet so need to kee maxwidth above
                    .contextMenu {
                        Button(role: .destructive) {
                            dataManager.deleteServer(server)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                #if os(tvOS)
                Button(action: { showAddSheet.toggle() } ) {
                    Label("Add Server", systemImage: "plus")
                }
                .tint(.primary)
                #endif
            }
            .formStyle(.grouped)
            #if os(tvOS)
            .safeAreaPadding(.leading, 40)
            #endif

        } infoPanel: {
            VStack(spacing: 20) {
                Image(systemName: "server.rack")
                    .font(.system(size: 200))
                    .opacity(0.4)
                
                Text("Servers")
                    .font(.largeTitle)
                    .bold()
                    .opacity(0.5)
            }
        }
        .navigationTitle("Servers")
        .toolbar {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .platformNavigationToolbar()
        #if os(tvOS)
        .fullScreenCover(isPresented: $showAddSheet) {
            AddServerView()
        }
        #else
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddServerView()
            }
        }
        #endif
    }
}

#Preview {
    ServerList()
}
