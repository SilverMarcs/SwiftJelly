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

    @Binding var showScrollEffect: Bool

    #if os(tvOS)
    @Binding var belowFold: Bool
    @Binding var backdropItem: BaseItemDto?
    #endif

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
        .task {
            await viewModel.load()
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
