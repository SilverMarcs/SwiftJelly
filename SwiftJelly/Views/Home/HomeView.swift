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
    
    @State private var favorites: [BaseItemDto] = []
    @State private var latestMovies: [BaseItemDto] = []
    @State private var latestShows: [BaseItemDto] = []
    @State private var isLoading = false
    @State var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
        .task {
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
            async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 15)
            async let loadedFavorites = JFAPI.loadFavoriteItems(limit: 15)
            
            let items = try await allItems
            let loadedFavs = try await loadedFavorites

            withAnimation {
                latestMovies = Array(items.filter { $0.type == .movie })
                latestShows = Array(items.filter { $0.type == .series })
                favorites = loadedFavs
            }
        } catch {
            print("Error loading Home items: \(error)")
        }
    }
    
    private var spacing: CGFloat {
        #if os(macOS)
        20
        #else
        30
        #endif
    }
}
