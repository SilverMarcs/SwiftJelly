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
    private(set) var isLoading = false
    private(set) var hasLoaded = false

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

    func loadTrendingIfNeeded() async {
        guard SeerrAPI.isConfigured else { return }
        guard items.isEmpty else { return }
        await loadTrending()
    }

    func loadTrending() async {
        guard SeerrAPI.isConfigured else { return }
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        guard let serverURL = URL(string: UserDefaults.standard.string(forKey: "seerrServerURL") ?? "") else { return }

        do {
            let response = try await SeerrAPI.fetchTrending(serverURL: serverURL)
            let trendingItems = response.results.filter { $0.isMovie || $0.isTV }

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

            withAnimation {
                items = unique
            }

            // Delay so the ScrollView has time to lay out the new items
            if items.count > 1 {
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation {
                    scrolledID = items[1].id
                }
            }

            if !items.isEmpty {
                TopShelfCache.save(items: items)
            }

            startAutoScroll()
        } catch {
            print("Error loading trending items: \(error)")
        }
    }

    private var autoScrollTask: Task<Void, Never>?

    func startAutoScroll() {
        autoScrollTask?.cancel()
        guard items.count > 1 else { return }
        autoScrollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled, let self else { return }
                let nextIndex = (self.currentIndex + 1) % self.items.count
                withAnimation {
                    self.scrolledID = self.items[nextIndex].id
                }
            }
        }
    }

    func stopAutoScroll() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    private static func findMatch(for trending: SeerrSearchResult) async -> BaseItemDto? {
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
