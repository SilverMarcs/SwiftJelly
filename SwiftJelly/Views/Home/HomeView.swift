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
    
    @State private var dataManager = DataManager.shared
    @State private var trendingViewModel = TrendingInLibraryViewModel()

    @State private var favorites: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false
    @State var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                if !trendingViewModel.items.isEmpty {
                    TrendingInLibraryView(viewModel: trendingViewModel)
                        .onScrollVisibilityChange { isVisible in
                            showScrollEffect = isVisible
                        }
                }
                
                ContinueWatchingView()

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
        .ignoresSafeArea(edges: trendingViewModel.items.isEmpty ? [] : .top)
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .task(id: dataManager.servers.count) {
            Task {
                if latestMovies.isEmpty {
                    isLoading = true
                    await loadAll()
                    isLoading = false
                }
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
            async let trendingLoad: () = trendingViewModel.loadTrendingIfNeeded(apiKey: tmdbAPIKey)
            async let loadedFavorites = JFAPI.loadFavoriteItems(limit: 15)
            
            async let movies = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.movie])
            async let shows = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.series])
            
            let loadedMovies = try await movies
            let loadedShows = try await shows
            let loadedFavs = try await loadedFavorites
            await trendingLoad

            withAnimation {
                latestMovies = loadedMovies
                latestShows = loadedShows
                favorites = loadedFavs
            }
        } catch {
            print("Error loading Home items: \(error)")
        }
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        25
        #endif
    }
}
