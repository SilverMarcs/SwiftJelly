//
//  FilteredMediaView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 21/09/2025.
//

import SwiftUI
import JellyfinAPI

enum MediaFilter {
    case library(BaseItemDto)
    case genre(String)
    case studio(NameGuidPair)
}

struct FilteredMediaView: View {
    let filter: MediaFilter
    @State private var items: [BaseItemDto] = []
    @State private var isLoading = false
    
    var navigationTitle: String {
        switch filter {
        case .library(let library):
            return library.name ?? "Library"
        case .genre(let genre):
            return genre
        case .studio(let studio):
            return studio.name ?? "Studio"
        }
    }
    
    var body: some View {
        MediaGrid(items: items, isLoading: isLoading)
            .navigationTitle(navigationTitle)
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
        defer { isLoading = false }

        do {
            switch filter {
            case .library(let library):
                items = try await JFAPI.loadLibraryItems(for: library)
            case .genre(let genre):
                items = try await JFAPI.loadMediaByGenre(genre)
            case .studio(let studio):
                items = try await JFAPI.loadMediaByStudio(studio)
            }
        } catch {
            print("Error loading filtered items: \(error.localizedDescription)")
            items = []
        }
    }
}
