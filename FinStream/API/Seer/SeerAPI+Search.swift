//
//  SeerAPI+Search.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

extension SeerAPI {
    static func search(query: String) async throws -> [SeerSearchResult] {
        let page: SeerPage<SeerSearchResult> = try await send(
            SeerEndpoint(path: "search", query: ["query": query, "page": "1"])
        )
        return page.results.filter { $0.reference != nil }
    }
}
