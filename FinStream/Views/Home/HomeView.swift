//
//  HomeView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

enum FocusField {
    case featured, content
}

struct HomeView: View {
    @State private var showScrollEffect = false
#if os(tvOS)
    @State private var belowFold = false
#endif

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: spacing) {
                #if os(tvOS)
                HomeHeroView(showScrollEffect: $showScrollEffect, belowFold: $belowFold)
                #else
                HomeHeroView(showScrollEffect: $showScrollEffect)
                #endif
                
                ContinueWatchingView()

                MediaShelf(
                    header: "Favorites",
                    loadItemsAction: { try await JFAPI.loadFavoriteItems(limit: 15) },
                    destination: .favorites
                )

                GenreCarouselView()

                MediaShelf(
                    header: "Recently Added Movies",
                    loadItemsAction: {
                        try await JFAPI.loadLatestMediaInLibrary(limit: 15, itemTypes: [.movie])
                    },
                    destination: .recentlyAdded(.movie)
                )

                LibrariesView()

                MediaShelf(
                    header: "Recently Added Shows",
                    loadItemsAction: {
                        try await JFAPI.loadLatestMediaInLibrary(limit: 15, itemTypes: [.series])
                    },
                    destination: .recentlyAdded(.series)
                )
            }
            .scenePadding(.bottom)
        }
        #if os(tvOS)
        .background(.background.secondary)
        .scrollTargetBehavior(FoldSnappingScrollTargetBehavior(aboveFold: !belowFold, showcaseHeight: 800))
        #endif
        .scrollEdgeEffectHidden(showScrollEffect, for: .top)
        .ignoresSafeArea(edges: .top)
        .scrollClipDisabled()
        .navigationTitle(showScrollEffect ? "" : "Home")
        .platformNavigationToolbar()
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        80
        #else
        25
        #endif
    }
}
