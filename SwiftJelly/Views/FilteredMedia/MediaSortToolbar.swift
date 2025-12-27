//
//  MediaSortToolbar.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI

struct MediaSortToolbar: ToolbarContent {
    let viewModel: FilteredMediaViewModel
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Menu {
                Button {
                    Task { await viewModel.setSortOption(.none) }
                } label: {
                    Label("Default", systemImage: "line.3.horizontal.decrease")
                }
                
                Divider()
                
                Button {
                    Task { await viewModel.setSortOption(.random) }
                } label: {
                    Label("Random", systemImage: "shuffle")
                }
                
                Divider()
                
                Menu("Name") {
                    Button {
                        Task { await viewModel.setSortOption(.nameAscending) }
                    } label: {
                        Text("A → Z")
                    }
                    Button {
                        Task { await viewModel.setSortOption(.nameDescending) }
                    } label: {
                        Text("Z → A")
                    }
                }
                
                Menu("Community Rating") {
                    Button {
                        Task { await viewModel.setSortOption(.ratingDescending) }
                    } label: {
                        Text("Highest First")
                    }
                    Button {
                        Task { await viewModel.setSortOption(.ratingAscending) }
                    } label: {
                        Text("Lowest First")
                    }
                }
                
                Menu("Critic Rating") {
                    Button {
                        Task { await viewModel.setSortOption(.criticRatingDescending) }
                    } label: {
                        Text("Highest First")
                    }
                    Button {
                        Task { await viewModel.setSortOption(.criticRatingAscending) }
                    } label: {
                        Text("Lowest First")
                    }
                }
                
                Menu("Year") {
                    Button {
                        Task { await viewModel.setSortOption(.yearDescending) }
                    } label: {
                        Text("Newest First")
                    }
                    Button {
                        Task { await viewModel.setSortOption(.yearAscending) }
                    } label: {
                        Text("Oldest First")
                    }
                }
            } label: {
                Label("Sort", systemImage: viewModel.sortOption.systemImage)
            }
            .disabled(viewModel.isLoading || viewModel.isSorting)
        }
    }
}
