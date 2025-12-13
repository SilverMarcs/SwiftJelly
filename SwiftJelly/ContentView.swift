//
//  ContentView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct ContentView: View {
    @Binding var selectedTab: TabSelection
    
    @State private var dataManager = DataManager.shared

    var body: some View {
        if dataManager.servers.isEmpty {
            NoServerView()
        } else {
            TabView(selection: $selectedTab) {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    Tab(tab.title,
                        systemImage: tab.systemImage,
                        value: tab,
                        role: tab == .search ? .search : .none
                    ) {
                        NavigationStack {
                            tab.tabView
                                .navigationDestinations()
                                #if os(iOS)
                                .toolbar {
                                    SettingsToolbar()
                                }
                                #endif
                        }
                    }
                }
            }
            #if os(tvOS)
            .tabViewStyle(.tabBarOnly)
            #else
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSearchActivation(.searchTabSelection)
            #endif
            #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
            #endif
        }
    }
}
