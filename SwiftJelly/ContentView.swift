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
    @State private var playbackManager = PlaybackManager.shared
    
    #if os(tvOS)
    @State private var isTopShelfNavigationActive = false
    @State private var topShelfNavigationItem: BaseItemDto?
    @AppStorage("tvOSNavigationStyle") private var navigationStyle = TVNavigationStyle.tabBar
    #endif


    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompactSize: Bool {
        horizontalSizeClass == .compact
    }
    #else
    private var isCompactSize: Bool { false }
    #endif

    var body: some View {
        if dataManager.servers.isEmpty {
            NoServerView()
        } else {
            TabView(selection: $selectedTab) {
                ForEach(primaryTabs, id: \.self) { tab in
                    Tab(tab.title,
                        systemImage: tab.systemImage,
                        value: tab,
                        role: tab == .search ? .search : .none
                    ) {
                        NavigationStack {
                            tabWithNavigationDestinations(tab: tab)
                        }
                    }
                }

                if !isCompactSize {
                    libraryTabs()
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
            #else
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSearchActivation(.searchTabSelection)
            #endif
            #if os(iOS)
            .tabBarMinimizeBehavior(.onScrollDown)
            #endif
            #if !os(macOS)
            .fullScreenCover(isPresented: $playbackManager.isPlayerPresented) {
                #if os(tvOS)
                AVMediaPlayerViewTVOS()
                    .ignoresSafeArea()
                #else
                AVMediaPlayerViewIOS()
                    .ignoresSafeArea()
                #endif
            }
            #endif
        }
    }
    
    private func tabWithNavigationDestinations(tab: TabSelection) -> some View {
        tab.tabView
            .navigationDestinations()
        #if os(macOS)
            .frame(minWidth: 800)
        #endif
        #if os(tvOS)
            .navigationDestination(isPresented: $isTopShelfNavigationActive) {
                if let item = topShelfNavigationItem {
                    MediaDestinationView(item: item)
                } else {
                    ContentUnavailableView("Missing Item", systemImage: "questionmark.circle")
                        .focusable(true)
                }
            }
            .onChange(of: isTopShelfNavigationActive) { _, isPresented in
                if !isPresented {
                    topShelfNavigationItem = nil
                }
            }
        #endif
    }
    
    @TabContentBuilder<TabSelection>
    private func libraryTabs() -> some TabContent<TabSelection> {
        TabSection {
            ForEach(TabSelection.extendedlibraryTabs, id: \.self) { libraryTab in
                Tab(libraryTab.title,
                    systemImage: libraryTab.systemImage,
                    value: libraryTab
                ) {
                    NavigationStack {
                        tabWithNavigationDestinations(tab: libraryTab)
                    }
                }
            }
        } header: {
            Text("Media")
        }
    }

    private var primaryTabs: [TabSelection] {
        if isCompactSize {
            return TabSelection.compactTabs
        } else {
            return TabSelection.extendedTabs
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
                        PlaybackManager.shared.startPlayback(for: item, refresh: nil)
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
