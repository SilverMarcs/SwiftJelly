//
//  SeerLibraryResolver.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

enum SeerLibraryResolver {
    static func libraryItems(for jellyfinIDs: [String]) async -> [String: BaseItemDto] {
        let ids = Array(Set(jellyfinIDs.filter { !$0.isEmpty }))
        guard !ids.isEmpty, let items = try? await JFAPI.loadItems(ids: ids) else { return [:] }

        return items.reduce(into: [:]) { result, item in
            if let id = item.id {
                result[id] = item
            }
        }
    }

    static func libraryItem(for mediaInfo: SeerMediaInfo?) async -> BaseItemDto? {
        guard let jellyfinMediaID = mediaInfo?.jellyfinMediaID else { return nil }
        return await libraryItems(for: [jellyfinMediaID])[jellyfinMediaID]
    }

    static func tmdbID(for item: BaseItemDto) async -> Int? {
        guard let id = item.id,
              let detailed = try? await JFAPI.loadItem(by: id, fields: [.providerIDs]),
              let value = detailed.providerIDs?.first(where: { $0.key.lowercased() == "tmdb" })?.value else {
            return nil
        }
        return Int(value)
    }
}
