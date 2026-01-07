//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

struct SettingsView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    
    var body: some View {
        Form {
            Section("Server") {
                NavigationLink {
                    ServerList()
                } label: {
                    Label("Servers", systemImage: "server.rack")
                }
            }

            Section("Images") {
                CacheManagerView()
            }
            
            Section("View Options") {                
                ViewOptions()
                    .foregroundStyle(.primary)
            }
            
            Section {
                SecureField("Bearer Token", text: $tmdbAPIKey, prompt: Text("ey..."))
            } header: {
                Text("TMDB API")
            } footer: {
                Text("Enter your TMDB API Bearer token to show trending content from your library.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        #if os(tvOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}
