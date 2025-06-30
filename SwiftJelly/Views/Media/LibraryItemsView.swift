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

    private static var defaultSize: CGFloat {
        #if os(macOS)
        140
        #else
        105
        #endif
    }

    private let columns = [
        GridItem(.adaptive(minimum: defaultSize), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink {
                            switch item.type {
                            case .movie:
                                MovieDetailView(movie: item)
                            case .series:
                                ShowDetailView(show: item)
                            default:
                                Text("Unsupported item type")
                            }
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
        .toolbarTitleDisplayMode(.inline)
        .task {
            await loadItems()
        }
        .refreshable {
            await loadItems()
        }
    }

    private func loadItems() async {
        isLoading = true

        do {
            items = try await JFAPI.shared.loadLibraryItems(for: library)
        } catch {
            print("Error loading library items: \(error.localizedDescription)")
        }

        isLoading = false
    }
}
