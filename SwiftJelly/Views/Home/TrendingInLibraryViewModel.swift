//
//  TrendingInLibraryViewModel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI

@Observable
final class TrendingInLibraryViewModel {
    var items: [BaseItemDto] = []
    var scrolledID: String?
    private var isLoading = false
    
    var currentIndex: Int {
        guard let scrolledID else { return 0 }
        return items.firstIndex { $0.id == scrolledID } ?? 0
    }

    func scrollToPrevious() {
        guard currentIndex > 0 else { return }
        scrolledID = items[currentIndex - 1].id
    }

    func scrollToNext() {
        guard currentIndex < items.count - 1 else { return }
        scrolledID = items[currentIndex + 1].id
    }

    func loadTrendingIfNeeded(apiKey: String) async {
        guard !apiKey.isEmpty else { return }
        guard items.isEmpty else { return }
        await loadTrending(apiKey: apiKey)
    }

    func loadTrending(apiKey: String) async {
        guard !apiKey.isEmpty else { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let trendingItems = try await TMDBAPI.fetchTrending(apiKey: apiKey)

            var matched: [(Int, BaseItemDto)] = []

            await withTaskGroup(of: (Int, BaseItemDto?).self) { group in
                for (index, item) in trendingItems.prefix(20).enumerated() {
                    group.addTask { (index, await Self.findMatch(for: item)) }
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

            let shuffled = unique.shuffled()

            withAnimation {
                items = shuffled
            }
        } catch {
            print("Error loading trending items: \(error)")
        }
    }

    private static func findMatch(for trending: TrendingItem) async -> BaseItemDto? {
        guard let results = try? await JFAPI.searchMedia(query: trending.displayTitle, includeProviderId: true) else { return nil }
        let expectedType: BaseItemKind = trending.isMovie ? .movie : .series
        let tmdbID = String(trending.id)

        return results.first { item in
            guard item.type == expectedType else { return false }
            if let providers = item.providerIDs, providers["Tmdb"] == tmdbID { return true }
            return item.name?.lowercased() == trending.displayTitle.lowercased()
        }
    }
}
