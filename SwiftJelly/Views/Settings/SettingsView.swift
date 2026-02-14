//
//  SettingsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import SwiftMediaViewer

enum Route: Hashable {
    case serverList
    case addServer
}

struct SettingsView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true
    
    var body: some View {
        SettingsSplitView {
            NavigationStack {
                form
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .serverList:
                            ServerList()
                        case .addServer:
                            AddServerView()
                        }
                    }
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
            NavigationLink(value: Route.serverList){
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
        #if os(tvOS)
        .safeAreaPadding(.leading)
        #endif
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .platformNavigationToolbar()
    }
}


#Preview {
    SettingsView()
}
