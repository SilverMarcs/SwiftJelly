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
    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false

    private let apiService = JellyfinAPIService.shared
    private let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(items, id: \.id) { item in
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
                await loadItems()
            }
            .refreshable {
                await loadItems()
            }
        }
    }

    private func loadItems() async {
        isLoading = true

        do {
            items = try await apiService.loadLibraryItems(for: library)
        } catch {
            print("Error loading library items: \(error.localizedDescription)")
        }

        isLoading = false
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
