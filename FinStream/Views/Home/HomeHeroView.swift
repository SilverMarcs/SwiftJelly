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

    @State private var fallbackItems: [BaseItemDto] = []
    @State private var hasStartedFallbackLoad = false
    @State private var hasFinishedFallbackLoad = false

    @Binding var showScrollEffect: Bool

    #if os(tvOS)
    @Binding var belowFold: Bool
    #endif

    var body: some View {
        @Bindable var trendingViewModel = trendingViewModel
        Group {
            if !trendingViewModel.items.isEmpty {
                HeroCarouselView(items: $trendingViewModel.items)
            } else if !fallbackItems.isEmpty {
                HeroCarouselView(items: $fallbackItems)
            } else if trendingViewModel.hasLoaded && hasFinishedFallbackLoad {
                EmptyView()
            } else {
                HeroBackdropView(item: BaseItemDto()) {
                    MovieHeroActions(movie: .constant(BaseItemDto()))
                }
            }
        }
        .onScrollVisibilityChange { isVisible in
            showScrollEffect = isVisible
            #if os(tvOS)
            belowFold = !isVisible
            #endif
        }
        .task(id: trendingViewModel.hasLoaded) {
            guard trendingViewModel.hasLoaded,
                  trendingViewModel.items.isEmpty,
                  !hasStartedFallbackLoad else { return }
            hasStartedFallbackLoad = true
            await loadFallback()
        }
        #if os(tvOS)
        .frame(height: 800)
        .ignoresSafeArea(edges: .horizontal)
        #endif
    }

    private func loadFallback() async {
        do {
            let loaded = try await JFAPI.loadLatestMediaInLibrary(
                limit: 10,
                itemTypes: [.movie, .tvProgram]
            ).shuffled()
            let filtered = loaded.filter { $0.type == .movie || $0.type == .series }
            await MainActor.run {
                withAnimation {
                    fallbackItems = filtered
                    hasFinishedFallbackLoad = true
                }
            }
        } catch {
            print("Error loading featured items: \(error)")
            await MainActor.run { hasFinishedFallbackLoad = true }
        }
    }
}
