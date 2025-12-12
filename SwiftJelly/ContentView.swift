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
                    NavigationLink {
                        AddServerView()
                    } label: {
                        Text("Add Server")
                    }
                    .buttonStyle(.borderedProminent)
                }
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
                                    SearchView()
                                default:
                                    tab.tabView
                                }
                            }
                            .addNavigationDestionationsForDetailView(animation: animation)
                        }
                        .environment(\.zoomNamespace, animation)
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
