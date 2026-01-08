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
    @State private var isTopShelfPlayerPresented = false
    @State private var topShelfPlayerItem: BaseItemDto?
    @State private var isTopShelfNavigationActive = false
    @State private var topShelfNavigationItem: BaseItemDto?
    @AppStorage("tvOSNavigationStyle") private var navigationStyle = TVNavigationStyle.tabBar

    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    @State private var trendingViewModel = TrendingInLibraryViewModel()

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
                            #if os(macOS)
                                .frame(minWidth: 800)
                            #endif
                                .navigationDestination(isPresented: $isTopShelfNavigationActive) {
                                    if let item = topShelfNavigationItem {
                                        MediaDestinationView(item: item)
                                    } else {
                                        ContentUnavailableView("Missing Item", systemImage: "questionmark.circle")
                                    }
                                }
                                .onChange(of: isTopShelfNavigationActive) { _, isPresented in
                                    if !isPresented {
                                        topShelfNavigationItem = nil
                                    }
                                }
                        }
                    }
                }
            }
            #if os(tvOS)
            .onOpenURL { url in
                handleTopShelfURL(url)
            }
            .onChange(of: selectedTab) { _, _ in
                isTopShelfNavigationActive = false
                topShelfNavigationItem = nil
            }
            .tvNavigationStyle(navigationStyle)
            .fullScreenCover(isPresented: $isTopShelfPlayerPresented) {
                if let item = topShelfPlayerItem {
                    AVMediaPlayerViewTVOS(item: item)
                        .ignoresSafeArea()
                }
            }
            .onChange(of: isTopShelfPlayerPresented) { _, isPresented in
                if !isPresented {
                    topShelfPlayerItem = nil
                }
            }
            #else
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSearchActivation(.searchTabSelection)
            #endif
            #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
            #endif
            .task(id: tmdbAPIKey) {
                await trendingViewModel.loadTrendingIfNeeded(apiKey: tmdbAPIKey)
            }
            .environment(trendingViewModel)
        }
    }
    #if os(tvOS)
    private func handleTopShelfURL(_ url: URL) {
        guard let deepLink = TopShelfDeepLink.parse(url) else { return }
        
        Task {
            do {
                let item = try await JFAPI.loadItem(by: deepLink.itemID)
                await MainActor.run {
                    switch deepLink.action {
                    case .play:
                        RefreshHandlerContainer.shared.refresh = nil
                        topShelfPlayerItem = item
                        isTopShelfPlayerPresented = true
                    case .open:
                        topShelfNavigationItem = item
                        isTopShelfNavigationActive = true
                    }
                }
            } catch {
                print("Error handling Top Shelf deep link: \(error)")
            }
        }
    }
    #endif
}
