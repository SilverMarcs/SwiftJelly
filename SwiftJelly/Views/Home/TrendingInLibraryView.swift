//
//  TrendingInLibraryView.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI

/// Displays trending movies/shows from TMDB that exist in the user's Jellyfin library
struct TrendingInLibraryView: View {
    @AppStorage("tmdbAPIKey") private var tmdbAPIKey = ""
    @State private var matchedItems: [BaseItemDto] = []
    
    var body: some View {
        if !tmdbAPIKey.isEmpty {
            MediaShelf(items: matchedItems, header: "Trending in Your Library")
                .task(id: tmdbAPIKey) {
                    if matchedItems.isEmpty {
                        await loadTrendingInLibrary()
                    }
                }
        }
    }
    
    private func loadTrendingInLibrary() async {
        guard let trendingItems = try? await TMDBAPI.fetchTrending(apiKey: tmdbAPIKey) else { return }
        
        var matched: [(Int, BaseItemDto)] = []
        
        await withTaskGroup(of: (Int, BaseItemDto?).self) { group in
            for (index, item) in trendingItems.prefix(20).enumerated() {
                group.addTask { (index, await findMatch(for: item)) }
            }
            for await (index, result) in group {
                if let item = result { matched.append((index, item)) }
            }
        }
        
        // Sort by trending order and deduplicate
        let sorted = matched.sorted { $0.0 < $1.0 }.map { $0.1 }
        let unique = sorted.reduce(into: [BaseItemDto]()) { result, item in
            if !result.contains(where: { $0.id == item.id }) { result.append(item) }
        }
        
        withAnimation {
            matchedItems = unique.shuffled()
        }
    }
    
    private func findMatch(for trending: TMDBAPI.TrendingItem) async -> BaseItemDto? {
        guard let results = try? await JFAPI.searchMedia(query: trending.displayTitle) else { return nil }
        let expectedType: BaseItemKind = trending.isMovie ? .movie : .series
        let tmdbID = String(trending.id)
        
        return results.first { item in
            guard item.type == expectedType else { return false }
            if let providers = item.providerIDs, providers["Tmdb"] == tmdbID { return true }
            return item.name?.lowercased() == trending.displayTitle.lowercased()
        }
    }
}
