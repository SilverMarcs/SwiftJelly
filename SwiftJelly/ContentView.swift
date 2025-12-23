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
    @State private var searchText: String = ""
    @Namespace private var animation
    @State private var dataManager = DataManager.shared
    
    var body: some View {
        if dataManager.servers.isEmpty {
            NavigationStack {
                ContentUnavailableView {
                    Label("No Server Found", systemImage: "server.rack")
                } description: {
                    Text("Please connect to a Jellyfin server to continue.")
                } actions: {
                    NavigationLink(value: ServerListNavigationItem()) {
                        Text("Add Server")
                    }
                    #if os(tvOS)
                    .buttonStyle(.borderedProminent)
                    #else
                    .buttonStyle(.borderedProminent)
                    #endif
                }
                .addNavigationTargets(animation: animation)
            }
        } else {
            TabView(selection: $selectedTab) {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    Tab(tab.title,
                        systemImage: tab.systemImage,
                        value: tab,
                        role: tab == .search ? .search : .none
                    ) {
                        NavigationStack {
                            Group {
                                switch tab {
                                case .search:
                                    SearchView(searchText: $searchText)
                                default:
                                    tab.tabView
                                }
                            }
                            .addNavigationTargets(animation: animation)
                        }
                        .environment(\.zoomNamespace, animation)
                    }
                }
            }
            #if os(tvOS)
            .tabViewStyle(.sidebarAdaptable)
            #else
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSearchActivation(.searchTabSelection)
            #endif
            #if os(macOS)
            .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search movies or shows")
            #elseif !os(tvOS)
            .tabBarMinimizeBehavior(.onScrollDown)
            #endif
        }
    }
}
