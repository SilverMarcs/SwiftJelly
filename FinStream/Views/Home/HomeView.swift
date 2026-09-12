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
    @State private var scrollOffset: CGFloat = 0
    @State private var heroBackdropItem: BaseItemDto?

    /// Height of the hero showcase. Kept in sync with `HomeHeroView`'s frame and
    /// the fold-snapping behavior so the first shelf peeks below the hero.
    private let showcaseHeight: CGFloat = 800
#endif

    var body: some View {
#if os(tvOS)
        ZStack(alignment: .top) {
            HeroParallaxBackground(
                item: heroBackdropItem,
                scrollOffset: scrollOffset,
                showcaseHeight: showcaseHeight
            )

            scrollContent
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newValue in
                    scrollOffset = newValue
                }
        }
        .ignoresSafeArea(edges: .top)
#else
        scrollContent
#endif
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: spacing) {
                #if os(tvOS)
                HomeHeroView(
                    showScrollEffect: $showScrollEffect,
                    belowFold: $belowFold,
                    backdropItem: $heroBackdropItem
                )
                #else
                HomeHeroView(showScrollEffect: $showScrollEffect)
                #endif

                ContinueWatchingView()

                MediaShelf(header: "Favorites", filter: .favorites) {
                    try await JFAPI.loadFavoriteItems(limit: 15)
                }

                GenreCarouselView()

                MediaShelf(header: "Recently Added Movies", filter: .recentlyAdded(.movie)) {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 15, itemTypes: [.movie])
                }

                LibrariesView()

                MediaShelf(header: "Recently Added Shows", filter: .recentlyAdded(.series)) {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 15, itemTypes: [.series])
                }
            }
            .scenePadding(.bottom)
        }
        #if os(tvOS)
        .scrollTargetBehavior(FoldSnappingScrollTargetBehavior(aboveFold: !belowFold, showcaseHeight: showcaseHeight))
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
