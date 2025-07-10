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
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    VStack(spacing: 24) {
                        ContinueWatchingView(items: continueWatchingItems)
                        
                        LatestMediaView(items: latestMovies, header: "Movies")
                        
                        LatestMediaView(items: latestShows, header: "Shows")
                            .scenePadding(.bottom)
                    }
                    .contentMargins(.horizontal, 15)
                }
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
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
            .refreshable {
                await loadAll()
            }
            .task {
                if continueWatchingItems.isEmpty && latestMovies.isEmpty && latestShows.isEmpty {
                    await loadAll()
                }
            }
        }
    }

    private func loadAll() async {
        isLoading = true
        async let continueWatching = JFAPI.shared.loadContinueWatchingSmart()
        async let allItems = JFAPI.shared.loadRecentlyAddedItems(limit: 10)
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
}
