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
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true
    
    @State private var dataManager = DataManager.shared
    @State private var trendingViewModel = TrendingInLibraryViewModel()
    @State private var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                if shouldShowTrending {
                    TrendingInLibraryView(viewModel: trendingViewModel)
                        .onScrollVisibilityChange { isVisible in
                            showScrollEffect = isVisible
                        }
                }
                
                ContinueWatchingView()

                MediaShelf(header: "Favorites") {
                    try await JFAPI.loadFavoriteItems(limit: 15)
                }
                
                GenreCarouselView()
                
                MediaShelf(header: "Recently Added Movies") {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 10, itemTypes: [.movie])
                }

                MediaShelf(header: "Recently Added Shows") {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 10, itemTypes: [.series])
                }
            }
            .scenePadding(.bottom)
        }
        .scrollEdgeEffectHidden(showScrollEffect, for: .top)
        .ignoresSafeArea(edges: shouldShowTrending ? .top : [])
        .task(id: dataManager.servers.count) {
            if showTrendingOnTop {
                await trendingViewModel.loadTrendingIfNeeded(apiKey: tmdbAPIKey)
            }
        }
        .navigationTitle("Home")
        .platformNavigationToolbar()
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        40
        #else
        25
        #endif
    }

    private var shouldShowTrending: Bool {
        showTrendingOnTop && !trendingViewModel.items.isEmpty
    }
}
