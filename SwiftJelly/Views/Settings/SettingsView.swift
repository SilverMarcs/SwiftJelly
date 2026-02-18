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
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        SettingsSplitView {
            NavigationStack {
                form
            }
        } infoPanel: {
            Image("AppLogo")
                .resizable()
                .frame(width: 450, height: 450)
                .shadow(radius: 12)
        }
    }
    
    var form: some View {
        Form {
            NavigationLink {
                ServerList()
            } label: {
                Label("Servers", systemImage: "server.rack")
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
        .platformNavigationToolbar(titleDisplayMode: .inline)
        #if os(iOS)
        .toolbar {
            if horizontalSizeClass == .compact {
                Button(role: .close) { dismiss() }
            }
        }
        .contentMargins(.top, 10)
        #endif
    }
}


#Preview {
    SettingsView()
}
