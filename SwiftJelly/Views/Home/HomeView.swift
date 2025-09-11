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
                VStack(spacing: 24) {
                    ContinueWatchingView(items: continueWatchingItems)
                        .environment(\.refresh, refreshContinueWatching)
                    
                    RecentlyAddedView(items: latestMovies, header: "Movies")
                    
                    RecentlyAddedView(items: latestShows, header: "Shows")
                }
                .scenePadding(.bottom)
                .contentMargins(.horizontal, 15)
            }
            .overlay {
                if isLoading {
                    UniversalProgressView()
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
        async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 30)
        do {
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            latestMovies = Array(items.filter { $0.type == .movie })
            latestShows = Array(items.filter { $0.type == .series })
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
