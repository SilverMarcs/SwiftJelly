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
                    Task { await viewModel.setSortOption(.random) }
                } label: {
                    Label("Random", systemImage: "shuffle")
                    if viewModel.sortOption == .random {
                        Image(systemName: "checkmark")
                    }
                }
                
                Divider()
                
                Menu("Name") {
                    Button {
                        Task { await viewModel.setSortOption(.nameAscending) }
                    } label: {
                        Text("A → Z")
                        if viewModel.sortOption == .nameAscending {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button {
                        Task { await viewModel.setSortOption(.nameDescending) }
                    } label: {
                        Text("Z → A")
                        if viewModel.sortOption == .nameDescending {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Menu("Community Rating") {
                    Button {
                        Task { await viewModel.setSortOption(.ratingDescending) }
                    } label: {
                        Text("Highest First")
                        if viewModel.sortOption == .ratingDescending {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button {
                        Task { await viewModel.setSortOption(.ratingAscending) }
                    } label: {
                        Text("Lowest First")
                        if viewModel.sortOption == .ratingAscending {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Menu("Critic Rating") {
                    Button {
                        Task { await viewModel.setSortOption(.criticRatingDescending) }
                    } label: {
                        Text("Highest First")
                        if viewModel.sortOption == .criticRatingDescending {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button {
                        Task { await viewModel.setSortOption(.criticRatingAscending) }
                    } label: {
                        Text("Lowest First")
                        if viewModel.sortOption == .criticRatingAscending {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Menu("Year") {
                    Button {
                        Task { await viewModel.setSortOption(.yearDescending) }
                    } label: {
                        Text("Newest First")
                        if viewModel.sortOption == .yearDescending {
                            Image(systemName: "checkmark")
                        }
                    }
                    Button {
                        Task { await viewModel.setSortOption(.yearAscending) }
                    } label: {
                        Text("Oldest First")
                        if viewModel.sortOption == .yearAscending {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: viewModel.sortOption.systemImage)
            }
            .disabled(viewModel.isLoading || viewModel.isSorting)
        }
    }
}
