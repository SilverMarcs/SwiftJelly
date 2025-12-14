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
    var viewModel: FilteredMediaViewModel
    
    init(filter: MediaFilter) {
        self.filter = filter
        self.viewModel = FilteredMediaViewModel(filter: filter)
    }
    
    var body: some View {
        MediaGrid(items: viewModel.items, isLoading: viewModel.isLoading) {
            Task {
                await viewModel.loadNextPage()
            }
        }
        .navigationTitle(filter.navigationTitle)
        .toolbarTitleDisplayMode(.inline)
        .task {
            if viewModel.items.isEmpty {
                await viewModel.loadInitialItems()
            }
        }
        .refreshToolbar {
            await viewModel.loadInitialItems()
        }
        .toolbar {
            MediaSortToolbar(viewModel: viewModel)
        }
    }
}
