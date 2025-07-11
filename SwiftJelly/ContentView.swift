//
//  ContentView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tabs = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }
            
            Tab("Libraries", systemImage: "film", value: .media) {
                LibraryView()
            }
            
            #if os(macOS)
            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView()
            }
            #endif
            
            Tab(value: .search, role: .search) {
                SearchView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        #if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}

enum Tabs: Hashable {
    case home
    case media
    case settings
    case search
}
