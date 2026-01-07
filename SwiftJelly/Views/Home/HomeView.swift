//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeView: View {
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true
    
    @State private var showScrollEffect = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                if showTrendingOnTop {
                    TrendingInLibraryView()
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
        .ignoresSafeArea(edges: showTrendingOnTop ? .top : [])
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
}
