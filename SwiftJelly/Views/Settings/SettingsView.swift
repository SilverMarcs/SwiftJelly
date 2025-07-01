//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showingServerSettings = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ServerSettingsView()
                    } label: {
                        HStack {
                            Label {
                                if let server = dataManager.server {
                                    Text("\(server.name)")
                                    Text(server.url.absoluteString)
                                } else {
                                    Text("Configure Server")
                                }
                                
                            } icon: {
                                Image(systemName: "server.rack")
                            }
                            
                            Spacer()
                            
                            if dataManager.isAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section("App Settings") {
                    // Future app settings can go here
                    Text("More settings coming soon...")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}
