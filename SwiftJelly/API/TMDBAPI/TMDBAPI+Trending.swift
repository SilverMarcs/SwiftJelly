//
//  TMDBAPI+Trending.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 17/12/2025.
//

import Foundation

extension TMDBAPI {
    static func fetchTrending(apiKey: String) async throws -> [TrendingItem] {
        let request = makeRequest(url: URL(string: "https://api.themoviedb.org/3/trending/all/day?language=en-US")!, apiKey: apiKey)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try makeDecoder().decode(TrendingResponse.self, from: data).results
            .filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
    }
}


struct TrendingItem: Decodable {
    let id: Int
    let title: String?  // Movies
    let name: String?   // TV shows
    let mediaType: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, name
        case mediaType = "media_type"
    }
    
    var displayTitle: String { title ?? name ?? "" }
    var isMovie: Bool { mediaType == "movie" }
}

struct TrendingResponse: Decodable {
    let results: [TrendingItem]
}
