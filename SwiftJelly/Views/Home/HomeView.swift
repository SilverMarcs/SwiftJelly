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

    @State private var favorites: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false
    @State var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                if !tmdbAPIKey.isEmpty {
                    TrendingInLibraryView()
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
        .ignoresSafeArea(edges: tmdbAPIKey.isEmpty ? [] : .top) // TODO: ideally this should instead check if trendign items is empty or not and adjust safe area accoridngly
        .overlay {
            if isLoading {
                UniversalProgressView()
            }
        }
        .task(id: dataManager.servers.count) {
            if latestMovies.isEmpty {
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
            async let loadedFavorites = JFAPI.loadFavoriteItems(limit: 15)
            
            async let movies = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.movie])
            async let shows = JFAPI.loadLatestMediaInLibrary(limit: 20, itemTypes: [.series])
            
            let loadedMovies = try await movies
            let loadedShows = try await shows
            let loadedFavs = try await loadedFavorites

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
        20
        #endif
    }
}
