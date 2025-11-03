//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    ContinueWatchingView(items: continueWatchingItems)
                        .environment(\.refresh, refreshContinueWatching)
                    
                    RecentlyAddedView(items: latestMovies, header: "Recently Added Movies")
                    
                    RecentlyAddedView(items: latestShows, header: "Recently Added Shows")
                }
                .scenePadding(.bottom)
                .contentMargins(.horizontal, 15)
            }
            .refreshable {
                await loadAll()
            }
            .overlay {
                if isLoading {
                    UniversalProgressView()
                }
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                #if os(macOS)
                ToolbarItem {
                    Button {
                        Task {
                            await loadAll()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                }
                #else
                SettingsToolbar()
                #endif
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await loadAll()
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false}
        do {
            async let continueWatching = JFAPI.loadContinueWatchingSmart()
            async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 10)
            
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            latestMovies = Array(items.filter { $0.type == .movie })
            latestShows = Array(items.filter { $0.type == .series })
        } catch {
            print("Error loading Home items: \(error)")
        }
    }

    private func refreshContinueWatching() async {
        do {
            let items = try await JFAPI.loadContinueWatchingSmart()
            
            withAnimation {
                continueWatchingItems = items
            }
        } catch {
            print("Error loading Continue Watching: \(error.localizedDescription)")
        }
    }
}
