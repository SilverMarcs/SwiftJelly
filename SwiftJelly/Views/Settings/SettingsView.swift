//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true

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
                Toggle("Show trending on top", isOn: $showTrendingOnTop)
                
                ViewOptions()
            }
            .foregroundStyle(.primary)
            
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
        #if os(iOS)
        .toolbar {
            Button("Close", systemImage: "xmark", role: .close) {
                dismiss()
            }
        }
        #endif
    }
}
