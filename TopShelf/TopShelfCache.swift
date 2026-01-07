//
//  TopShelfCache.swift
//  TopShelf
//
//  Created by Zabir Raihan on 07/01/2026.
//

import Foundation

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

    static func load() -> [TopShelfItemSnapshot] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        guard let data = defaults.data(forKey: itemsKey) else { return [] }
        return (try? JSONDecoder().decode([TopShelfItemSnapshot].self, from: data)) ?? []
    }
}
