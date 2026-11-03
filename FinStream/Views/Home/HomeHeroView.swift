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
    #endif

    var body: some View {
        Group {
            if !viewModel.items.isEmpty {
                HeroCarouselView(items: $viewModel.items)
            } else if !viewModel.hasLoaded {
                HeroBackdropView(item: BaseItemDto(), tvOSBottomPadding: 10) {
                    MovieHeroActions(movie: .constant(BaseItemDto()))
                }
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
