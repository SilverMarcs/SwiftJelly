//
//  TrendingInLibraryView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI

struct TrendingInLibraryView: View {
    @Environment(TrendingInLibraryViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        HeroCarouselView(items: $viewModel.items)
    }
}
