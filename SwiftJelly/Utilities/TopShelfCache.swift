//
//  TopShelfCache.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 07/01/2026.
//

import Foundation
import JellyfinAPI
#if canImport(TVServices)
import TVServices
#endif

struct TopShelfItemSnapshot: Codable, Hashable {
    let id: String
    let title: String
    let imageURL: URL
    let summary: String?
    let genre: String?
    let communityRating: Double?
    let criticRating: Double?
    let creationDate: Date?
    let durationSeconds: Double?
}

enum TopShelfCache {
    private static let appGroupID = "group.com.mush.SwiftJelly"
    private static let itemsKey = "TopShelfContinueWatchingItems"
    private static let maxItems = 10

    static func save(items: [BaseItemDto]) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        
        let snapshots = items.compactMap { item -> TopShelfItemSnapshot? in
            guard let id = item.id else { return nil }
            guard let imageURL = makeImageURL(for: item) else { return nil }
            let title = item.name ?? item.seriesName ?? "Continue Watching"
            let summary = item.overview
            let genre = item.genres?.first
            let creationDate = item.premiereDate ?? item.dateCreated
            let durationSeconds: Double? = {
                guard let ticks = item.runTimeTicks, ticks > 0 else { return nil }
                return Double(ticks) / 10_000_000
            }()
            return TopShelfItemSnapshot(
                id: id,
                title: title,
                imageURL: imageURL,
                summary: summary,
                genre: genre,
                communityRating: item.communityRating.map(Double.init),
                criticRating: item.criticRating.map(Double.init),
                creationDate: creationDate,
                durationSeconds: durationSeconds
            )
        }
        let limited = Array(snapshots.prefix(maxItems))
        
        do {
            let data = try JSONEncoder().encode(limited)
            defaults.set(data, forKey: itemsKey)
            #if os(tvOS)
            TVTopShelfContentProvider.topShelfContentDidChange()
            #endif
        } catch {
            print("Error caching Top Shelf items: \(error)")
        }
    }

    private static func makeImageURL(for item: BaseItemDto) -> URL? {
        ImageURLProvider.seriesImageURL(for: item)
        ?? ImageURLProvider.imageURL(for: item, type: .thumb)
    }
}
