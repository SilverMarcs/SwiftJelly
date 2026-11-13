//
//  HomeHeroView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 27/06/2025.
//

import SwiftUI
import JellyfinAPI

struct HomeHeroView: View {
    @State private var viewModel = HomeHeroViewModel()
    @AppStorage("heroCarouselSource") private var heroCarouselSource: HeroCarouselSource = .jellyfinPopular
    @AppStorage("continueWatchingStyle") private var continueWatchingStyle: ContinueWatchingStyle = .combined

    @Binding var showScrollEffect: Bool

    #if os(tvOS)
    @Binding var belowFold: Bool
    @Binding var backdropItem: BaseItemDto?
    #endif

    private var effectiveSource: HeroCarouselSource {
        heroCarouselSource.effective(isSeerConfigured: DataManager.shared.server?.seer?.isAuthenticated == true)
    }

    var body: some View {
        Group {
            if !viewModel.items.isEmpty {
                #if os(tvOS)
                HeroCarouselView(items: $viewModel.items, belowFold: $belowFold, backdropItem: $backdropItem)
                #else
                HeroCarouselView(items: $viewModel.items)
                #endif
            } else if !viewModel.hasLoaded {
                HeroBackdropView(item: BaseItemDto()) {
                    MovieHeroActions(movie: .constant(BaseItemDto()))
                }
                #if os(tvOS)
                .padding(.horizontal, 40)
                .onAppear { backdropItem = nil }
                #endif
            }
        }
        .task(id: effectiveSource) {
            await viewModel.load(source: effectiveSource, continueWatchingStyle: continueWatchingStyle)
        }
        .onScrollVisibilityChange { isVisible in
            showScrollEffect = isVisible
            #if os(tvOS)
            belowFold = !isVisible
            #endif
        }
        #if os(tvOS)
        .frame(height: HeroLayoutMetrics.height())
        .ignoresSafeArea(edges: .horizontal)
        #endif
    }
}
