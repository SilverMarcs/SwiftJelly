//
//  TMDBAPI.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 14/12/2025.
//

import Foundation

/// Service for fetching trending content from TMDB
enum TMDBAPI {
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
    
    private struct Response: Decodable {
        let results: [TrendingItem]
    }
    
    static func fetchTrending(apiKey: String) async throws -> [TrendingItem] {
        var request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/trending/all/day?language=en-US")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Response.self, from: data).results
            .filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
    }
}
