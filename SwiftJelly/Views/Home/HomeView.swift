//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    
    @State private var continueWatchingItems: [BaseItemDto] = []
    @State private var favorites: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false
    @State var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !tmdbAPIKey.isEmpty {
                    TrendingInLibraryView()
                        .onScrollVisibilityChange { isVisible in
                            showScrollEffect = isVisible
                        }
                }
                
                ContinueWatchingView(items: continueWatchingItems)
                    .environment(\.refresh, refreshContinueWatching)

                MediaShelf(items: favorites, header: "Favorites")
                
                if !isLoading {
                    GenreCarouselView()
                }
                
                MediaShelf(items: latestMovies, header: "Recently Added Movies")

                MediaShelf(items: latestShows, header: "Recently Added Shows")
            }
            .scenePadding(.bottom)
        }
        .scrollEdgeEffectHidden(showScrollEffect, for: .top)
        .ignoresSafeArea(edges: tmdbAPIKey.isEmpty ? [] : .top)
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .task {
            if continueWatchingItems.isEmpty {
                isLoading = true
                await loadAll()
                isLoading = false
            }
        }
        .navigationTitle("Home")
        .refreshToolbar {
            await loadAll()
        }
        .platformNavigationToolbar()
    }

    private func loadAll() async {
        do {
            async let continueWatching = JFAPI.loadContinueWatchingSmart()
            async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 15)
            async let loadedFavorites = JFAPI.loadFavoriteItems(limit: 15)
            
            // TODO: Animate this
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            
            latestMovies = Array(items.filter { $0.type == .movie })
            latestShows = Array(items.filter { $0.type == .series })
            
            favorites = try await loadedFavorites
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
