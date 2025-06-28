//
//  LibraryItemsView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import SwiftUI
import JellyfinAPI

struct LibraryItemsView: View {
    let library: BaseItemDto
    @StateObject private var viewModel: LibraryItemsViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]
    
    init(library: BaseItemDto) {
        self.library = library
        self._viewModel = StateObject(wrappedValue: LibraryItemsViewModel(library: library))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.items, id: \.id) { item in
                            Button {
                                // TODO: Navigate to item detail view
                                // For now, no action on tap as requested
                            } label: {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(library.name ?? "Library")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                await viewModel.loadItems()
            }
            .refreshable {
                await viewModel.loadItems()
            }
        }
    }
}

//#Preview {
//    let sampleLibrary = BaseItemDto(
//        name: "Movies",
//        id: "movies-library",
//        collectionType: .movies
//    )
//    
//    LibraryItemsView(library: sampleLibrary)
//        .environmentObject(DataManager.shared)
//}
