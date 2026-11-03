//
//  HomeHeroViewModel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import SwiftUI
import JellyfinAPI

/// Supplies the Home hero carousel and the tvOS Top Shelf.
///
/// Trending and recently added items load in parallel. Whichever arrives first
/// is shown, but trending always wins: once it returns items, they replace
/// recently added and nothing replaces them.
@MainActor
@Observable
final class HomeHeroViewModel {
    var items: [BaseItemDto] = []
    private(set) var hasLoaded = false

    private enum Source {
        case trending, latest
    }

    func load() async {
        guard !hasLoaded else { return }

        await withTaskGroup(of: (Source, [BaseItemDto]).self) { group in
            group.addTask {
                (.trending, (try? await JFAPI.loadTrending()) ?? [])
            }
            group.addTask {
                let latest = try? await JFAPI.loadLatestMediaInLibrary(limit: 10, itemTypes: [.movie, .series])
                return (.latest, latest?.shuffled() ?? [])
            }

            for await (source, result) in group where !result.isEmpty {
                withAnimation { items = result }
                TopShelfCache.save(items: result)
                if source == .trending {
                    group.cancelAll()
                    break
                }
            }
        }

        guard !Task.isCancelled else { return }
        hasLoaded = true
    }
}
