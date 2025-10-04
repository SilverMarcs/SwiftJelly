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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(TabSelection.home.title,
                systemImage: TabSelection.home.systemImage,
                value: TabSelection.home) {
                HomeView()
            }
            
            Tab(TabSelection.favorites.title,
                systemImage: TabSelection.favorites.systemImage,
                value: TabSelection.favorites) {
                FavoritesView()
            }
            
            Tab(TabSelection.libraries.title,
                systemImage: TabSelection.libraries.systemImage,
                value: TabSelection.libraries) {
                LibraryView()
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
        #endif
    }
}
