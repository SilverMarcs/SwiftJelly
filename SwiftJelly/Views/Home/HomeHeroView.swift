//
//  HomeHeroView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeHeroView: View {
    @Environment(TrendingInLibraryViewModel.self) private var trendingViewModel

    @Binding var showScrollEffect: Bool

    #if os(tvOS)
    @Binding var belowFold: Bool
    #endif

    var body: some View {
        Group {
            if !trendingViewModel.items.isEmpty {
                TrendingInLibraryView()
                    .onScrollVisibilityChange { isVisible in
                        showScrollEffect = isVisible
                    }
            } else if trendingViewModel.hasLoaded {
                FeaturedView {
                    try await JFAPI.loadLatestMediaInLibrary(limit: 10, itemTypes: [.movie, .tvProgram]).shuffled()
                }
                .onScrollVisibilityChange { isVisible in
                    showScrollEffect = isVisible
                }
            } else {
                HeroBackdropView(item: BaseItemDto()) {}
                    .onScrollVisibilityChange { isVisible in
                        showScrollEffect = isVisible
                    }
            }
        }
        #if os(tvOS)
        .onScrollVisibilityChange { isVisible in
            belowFold = !isVisible
        }
        #endif
    }
}
