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
            ForEach(TabSelection.tabs, id: \.self) { tab in
                Tab(tab.title,
                    systemImage: tab.systemImage,
                    value: tab,
                    role: tab == .search ? .search : .none
                ) {
                    tab.tabView
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSearchActivation(.searchTabSelection)
        #if !os(macOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}
