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
    @State private var libraryNavigationPath = NavigationPath()
    @State private var isTopShelfPlayerPresented = false
    @State private var topShelfPlayerItem: BaseItemDto?
    @AppStorage("tvOSNavigationStyle") private var navigationStyle = TVNavigationStyle.tabBar

    var body: some View {
        Group {
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
                            if tab == .libraries {
                                NavigationStack(path: $libraryNavigationPath) {
                                    tab.tabView
                                        .navigationDestinations()
                                        .settingsSheet()
                                    #if os(macOS)
                                        .frame(minWidth: 800)
                                    #endif
                                }
                            } else {
                                NavigationStack {
                                    tab.tabView
                                        .navigationDestinations()
                                        .settingsSheet()
                                    #if os(macOS)
                                        .frame(minWidth: 800)
                                    #endif
                                }
                            }
                        }
                    }
                }
                #if os(tvOS)
                .tvNavigationStyle(navigationStyle)
                #else
                .tabViewStyle(.sidebarAdaptable)
                .tabViewSearchActivation(.searchTabSelection)
                #endif
                #if os(iOS)
                .tabBarMinimizeBehavior(.onScrollDown)
                #endif
            }
        }
        .onOpenURL { url in
            handleTopShelfURL(url)
        }
        #if os(tvOS)
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
        #endif
    }

    private func handleTopShelfURL(_ url: URL) {
        #if os(tvOS)
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
                        selectedTab = .libraries
                        libraryNavigationPath = NavigationPath()
                        libraryNavigationPath.append(item)
                    }
                }
            } catch {
                print("Error handling Top Shelf deep link: \(error)")
            }
        }
        #endif
    }
}
