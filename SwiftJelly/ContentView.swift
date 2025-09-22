//
//  ContentView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ContentView: View {
//    @SceneStorage("selectedTab") private var selectedTab: TabSelection = .home
    @Binding var selectedTab: TabSelection
    
    @Environment(LocalMediaManager.self) var localMediaManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(TabSelection.home.title,
                systemImage: TabSelection.home.systemImage,
                value: TabSelection.home) {
                HomeView()
            }
            
            Tab(TabSelection.libraries.title,
                systemImage: TabSelection.libraries.systemImage,
                value: TabSelection.libraries) {
                LibraryView()
            }
            
            Tab(TabSelection.local.title,
                systemImage: TabSelection.local.systemImage,
                value: TabSelection.local) {
                LocalMediaView()
            }
            
            #if os(macOS)
            Tab(TabSelection.settings.title,
                systemImage: TabSelection.settings.systemImage,
                value: TabSelection.settings) {
                SettingsView()
            }
            #endif
            
            Tab(value: TabSelection.search, role: .search) {
                SearchView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        #if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #else
        .onOpenURL { url in
            if url.isFileURL {
                Task {
                    let canAccess = url.startAccessingSecurityScopedResource()
                    if canAccess {
                        let enhancedFile = await localMediaManager.getEnhancedMetadata(for: LocalMediaFile(url: url))
                        localMediaManager.addRecentFile(enhancedFile)
                        
                        let mediaItem = MediaItem.local(enhancedFile)
                        dismissWindow(id: "media-player")
                        openWindow(id: "media-player", value: mediaItem)
                    } else {
                        print("Failed to access security-scoped resource")
                    }
                }
            }
        }
        #endif
    }
}
