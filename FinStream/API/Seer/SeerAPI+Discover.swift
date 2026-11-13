//
//  SeerAPI+Discover.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation
import JellyfinAPI

extension SeerAPI {
    static func popularMovies(limit: Int = 10) async throws -> [BaseItemDto] {
        let page: SeerPage<SeerSearchResult> = try await send(
            SeerEndpoint(path: "discover/movies", query: ["page": "1"])
        )
        let results = Array(page.results.prefix(limit))
        let libraryItems = await SeerLibraryResolver.libraryItems(for: results.compactMap { $0.mediaInfo?.jellyfinMediaID })

        return await withTaskGroup(of: (Int, BaseItemDto?).self) { group in
            for result in results {
                if let libraryItem = result.mediaInfo?.jellyfinMediaID.flatMap({ libraryItems[$0] }) {
                    group.addTask { (result.id, libraryItem) }
                } else {
                    group.addTask { (result.id, (try? await movie(id: result.id)).map(BaseItemDto.init(seerMovie:))) }
                }
            }

            var items: [Int: BaseItemDto] = [:]
            for await (id, item) in group {
                items[id] = item
            }
            return results.compactMap { items[$0.id] }
        }
    }
}
