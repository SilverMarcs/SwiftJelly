//
//  FilteredMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

struct FilteredMediaView: View {
    let filter: MediaFilter
    let largeTitle: Bool
    @State private var viewModel: FilteredMediaViewModel

    init(filter: MediaFilter, largeTitle: Bool = false) {
        self.filter = filter
        self.largeTitle = largeTitle
        self._viewModel = State(initialValue: FilteredMediaViewModel(filter: filter))
    }

    var body: some View {
        MediaGrid(items: viewModel.items, isLoading: viewModel.isLoading) {
            Task {
                await viewModel.loadNextPage()
            }
        }
        #if os(tvOS)
        .focusSection()
        .navigationTitle(filter.navigationTitle)
        .platformNavigationToolbar()
        #else
        .navigationTitle(filter.navigationTitle)
        .platformNavigationToolbar(titleDisplayMode: largeTitle ? .inlineLarge : .inline)
        #endif
        .task {
            if viewModel.items.isEmpty {
                await viewModel.loadInitialItems()
            }
        }
        .toolbar {
            MediaSortToolbar(viewModel: viewModel)
        }
        .refreshToolbar {
            await viewModel.loadInitialItems()
        }
    }
}
