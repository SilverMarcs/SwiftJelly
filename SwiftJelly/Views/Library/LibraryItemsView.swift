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
    
    var body: some View {
        MediaGrid(items: items, isLoading: isLoading)
            .navigationTitle(library.name ?? "Library")
            .toolbarTitleDisplayMode(.inline)
            .task {
                if items.isEmpty {
                    await loadItems()
                }
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
