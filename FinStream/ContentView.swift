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

    #if os(iOS)
    @Namespace private var detailZoomNamespace
    @Namespace private var playerZoomNamespace
    #endif

    #if os(iOS)
    @State private var showingSettings = false
    #endif
    
    #if os(tvOS)
    @State private var isTopShelfNavigationActive = false
    @State private var topShelfNavigationItem: BaseItemDto?
    #endif


    @State private var trendingViewModel = TrendingInLibraryViewModel()

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
                    defaultTab(tab)
                }

                if !isCompactSize {
                    libraryTabs()
                }
            }
            .profileSidebarHeader()
            #if os(iOS)
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button(role: .close) { showingSettings = false }
                            }
                        }
                }
            }
            #endif
            #if os(tvOS)
            .onOpenURL { url in
                handleTopShelfURL(url)
            }
            .onChange(of: selectedTab) { _, _ in
                isTopShelfNavigationActive = false
                topShelfNavigationItem = nil
            }
            #endif
            .tabViewStyle(.sidebarAdaptable)
            #if !os(tvOS)
            .tabViewSearchActivation(.automatic)
            #endif
            #if os(iOS)
            .tabBarMinimizeBehavior(.never)
            #endif
            #if !os(macOS)
            .fullScreenCover(isPresented: $playbackManager.isPlayerPresented) {
                #if os(tvOS)
                AVMediaPlayerViewTVOS()
                    .ignoresSafeArea()
                #else
                AVMediaPlayerViewIOS()
                    .ignoresSafeArea()
                    .zoomTransitionDestination(sourceID: playbackManager.zoomSourceID, in: playerZoomNamespace)
                #endif
            }
            #endif
            .task {
                await trendingViewModel.loadTrendingIfNeeded()
            }
            .environment(trendingViewModel)
            #if os(iOS)
            .environment(\.detailZoomNamespace, detailZoomNamespace)
            .environment(\.playerZoomNamespace, playerZoomNamespace)
            #endif
        }
    }

    private func tabWithNavigationDestinations(tab: TabSelection) -> some View {
        tab.tabView
            .navigationDestinations()
        #if os(iOS)
            .toolbar {
                if isCompactSize {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProfileToolbarMenu(showingSettings: $showingSettings)
                    }
                }
            }
        #endif
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
    private func defaultTab(_ tab: TabSelection) -> some TabContent<TabSelection> {
        Tab(tab.title,
            systemImage: tab.systemImage,
            value: tab,
            role: tab == .search ? .search : .none
        ) {
            NavigationStack {
                tabWithNavigationDestinations(tab: tab)
            }
            .id(dataManager.activeServerID)
        }
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
                    .id(dataManager.activeServerID)
                }
            }
        } header: {
            Text("Media")
        }
    }

    private var primaryTabs: [TabSelection] {
        var tabs = isCompactSize ? TabSelection.compactTabs : TabSelection.extendedTabs
        if !SeerrAPI.isConfigured {
            tabs.removeAll { $0 == .discover }
        }
        #if os(tvOS)
        // `tabViewSidebarHeader` is tvOS 27+. On older versions the profile can't
        // live in the header, so fall back to it being the first sidebar tab.
        if #unavailable(tvOS 27.0) {
            tabs.insert(.profile, at: 0)
        }
        #endif
        return tabs
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

private extension View {
    /// Places the profile button at the top of the tab view sidebar. The tvOS
    /// header API requires tvOS 27; on older versions the profile is shown as
    /// the first sidebar tab instead (see `ContentView.primaryTabs`).
    @ViewBuilder
    func profileSidebarHeader() -> some View {
        #if os(tvOS)
        if #available(tvOS 27.0, *) {
            tabViewSidebarHeader {
                ProfileSidebarButton()
                    .padding()
            }
        } else {
            self
        }
        #else
        tabViewSidebarHeader {
            ProfileSidebarButton()
            Spacer()
        }
        #endif
    }
}
