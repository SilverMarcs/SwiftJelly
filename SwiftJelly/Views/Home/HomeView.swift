//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    UniversalProgressView()
                } else {
                    VStack(spacing: 24) {
                        ContinueWatchingView(items: continueWatchingItems)
                            .environment(\.refresh, refreshContinueWatching)
                        
                        LatestMediaView(items: latestMovies, header: "Movies")
                        
                        LatestMediaView(items: latestShows, header: "Shows")
                            .scenePadding(.bottom)
                    }
                    .contentMargins(.horizontal, 15)
                }
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                if continueWatchingItems.isEmpty && latestMovies.isEmpty && latestShows.isEmpty {
                    await loadAll()
                }
            }
            .refreshable {
                await loadAll()
            }
            .toolbar {
                #if !os(macOS)
                SettingsToolbar()
                #else
                Button {
                    Task { await loadAll() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                #endif
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        async let continueWatching = JFAPI.loadContinueWatchingSmart()
        async let allItems = JFAPI.loadRecentlyAddedItems(limit: 10)
        do {
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            latestMovies = Array(items.filter { $0.type == .movie }.prefix(5))
            latestShows = Array(items.filter { $0.type == .series }.prefix(5))
        } catch {
            print(error.localizedDescription)
        }
        isLoading = false
    }

    private func refreshContinueWatching() async {
        do {
            let items = try await JFAPI.loadContinueWatchingSmart()
            
            withAnimation {
                continueWatchingItems = items
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
