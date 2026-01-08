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
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true
    
    var body: some View {
        #if os(tvOS)
        HStack(spacing: 0) {
            VStack {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 450, height: 450)
                    .shadow(radius: 12)
            }
            .frame(width: UIScreen.main.bounds.width * 0.5)
            
            form
        }
        #else
        form
        #endif
    }
    
    var form: some View {
        Form {
            Section("Server") {
                NavigationLink {
                    ServerList()
                } label: {
                    Label("Servers", systemImage: "server.rack")
                }
            }
            
            Section("View Options") {                
                ViewOptions()
                    .foregroundStyle(.primary)
            }
            
            Section {
                SecureField("Bearer Token", text: $tmdbAPIKey, prompt: Text("ey..."))
                    .onChange(of: tmdbAPIKey) { _, newValue in
                        if newValue.isEmpty {
                            showTrendingOnTop = false
                        }
                    }
                if !tmdbAPIKey.isEmpty {
                    Toggle("Show trending on top", isOn: $showTrendingOnTop)
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("TMDB API")
            } footer: {
                Text("Enter your TMDB API Bearer token to show trending content from your library.")
            }
            
            Section("Images") {
                CacheManagerView()
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .platformNavigationToolbar()
    }
}
