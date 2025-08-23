//
//  ContentView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ContentView: View {    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            
            Tab("Libraries", systemImage: "film") {
                LibraryView()
            }
            
            #if os(macOS)
            Tab("Local Media", systemImage: "folder") {
                LocalMediaView()
            }
            
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
            #endif
            
            Tab(role: .search) {
                SearchView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        #if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}