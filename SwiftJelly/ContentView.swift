//
//  ContentView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI

struct ContentView: View {
    @Binding var selectedTab: TabSelection
    @State private var searchText: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                Tab(tab.title,
                    systemImage: tab.systemImage,
                    value: tab,
                    role: tab == .search ? .search : .none
                ) {
                    switch tab {
                    case .search:
                        SearchView(searchText: $searchText)
                    default:
                        tab.tabView
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewSearchActivation(.searchTabSelection)
        #if os(macOS)
        .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search movies or shows")
        #else
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }
}
