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
    
    var navigationTitle: String {
        switch filter {
        case .library(let library):
            return library.name ?? "Library"
        case .genre(let genre):
            return genre.capitalized
        case .studio(let studio):
            return studio.name ?? "Studio"
        }
    }
    
    var body: some View {
        MediaGrid(items: viewModel.items, isLoading: viewModel.isLoading) {
            Task {
                await viewModel.loadNextPage()
            }
        }
        .navigationTitle(navigationTitle)
        .toolbarTitleDisplayMode(.inline)
        .task {
            if viewModel.items.isEmpty {
                await viewModel.loadInitialItems()
            }
        }
        .refreshToolbar {
            await viewModel.loadInitialItems()
        }
    }
}
