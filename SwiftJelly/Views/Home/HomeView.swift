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
    @State private var genres: [BaseItemDto] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView([.vertical]) {
            VStack(alignment: .leading, spacing: 26) {
                TrendingInLibraryView()
                
                ContinueWatchingView(items: continueWatchingItems)
                    .environment(\.refresh, refreshContinueWatching)

                GenreCarouselView(genres: genres)
                
                MediaShelf(items: latestMovies, header: "Recently Added Movies")

                MediaShelf(items: latestShows, header: "Recently Added Shows")
            }
            .scenePadding(.bottom)
        }
        .overlay {
            if isLoading && continueWatchingItems.isEmpty {
                UniversalProgressView()
            }
        }
        .task {
            if  continueWatchingItems.isEmpty {
                await loadAll()
            }
        }
        .navigationTitle("Home")
        .refreshToolbar {
            await loadAll()
        }
        .platformNavigationToolbar()
    }

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let continueWatching = JFAPI.loadContinueWatchingSmart()
            async let allItems = JFAPI.loadLatestMediaInLibrary(limit: 10)
            async let loadedGenres = JFAPI.loadGenres(limit: 20)
            // TODO: Animate this
            continueWatchingItems = try await continueWatching
            let items = try await allItems
            
            latestMovies = Array(items.filter { $0.type == .movie })
            latestShows = Array(items.filter { $0.type == .series })
            
            genres = try await loadedGenres
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
