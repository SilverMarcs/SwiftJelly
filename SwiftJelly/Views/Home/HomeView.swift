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
    @AppStorage("showTrendingOnTop") private var showTrendingOnTop = true
    @AppStorage("continueWatchingStyle") private var continueWatchingStyle: ContinueWatchingStyle = .combined

    @State private var showScrollEffect = false    

#if os(tvOS)
    @State private var belowFold = false
#endif

    @FocusState private var focusState: FocusField?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: spacing) {
                FeaturedView {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 10, itemTypes: [.movie, .tvProgram]).shuffled()
                }
                .onScrollVisibilityChange { isVisible in
                    showScrollEffect = isVisible
                }
                #if os(tvOS)
                
                .ignoresSafeArea()
                .onScrollVisibilityChange { isVisible in
                    belowFold = !isVisible
                }
                #endif
                
                if continueWatchingStyle == .combined {
                    ContinueWatchingView(header: "Continue Watching") {
                        try await JFAPI.loadContinueWatchingSmart()
                    }
                } else {
                    ContinueWatchingView(header: "Continue Watching") {
                        try await JFAPI.loadResumeItems(limit: 20)
                    }
                    
                    ContinueWatchingView(header: "Next Up") {
                        try await JFAPI.loadNextUpItems(limit: 20)
                    }
                }

                MediaShelf(header: "Favorites") {
                    try await JFAPI.loadFavoriteItems(limit: 30)
                }
                
                GenreCarouselView()
                
                MediaShelf(header: "Recently Added Movies") {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 40, itemTypes: [.movie])
                }
                
                LibrariesView()

                MediaShelf(header: "Recently Added Shows") {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 40, itemTypes: [.series])
                }
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
        .settingsSheet()
    }
    
    private var spacing: CGFloat {
        #if os(tvOS)
        80
        #else
        25
        #endif
    }
}
