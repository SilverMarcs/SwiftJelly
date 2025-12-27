//
//  TMDBAPI+Reviews.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 17/12/2025.
//

import Foundation

extension TMDBAPI {
    static func fetchMovieReviews(apiKey: String, movieID: Int, language: String = "en-US", page: Int = 1) async throws -> [Review] {
        var url = URL(string: "https://api.themoviedb.org/3/movie/\(movieID)/reviews")!
        url.append(queryItems: [
            .init(name: "language", value: language),
            .init(name: "page", value: String(page))
        ])

        let request = makeRequest(url: url, apiKey: apiKey)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try makeDecoder().decode(ReviewsResponse.self, from: data).results
    }

    static func fetchTVReviews(apiKey: String, seriesID: Int, language: String = "en-US", page: Int = 1) async throws -> [Review] {
        var url = URL(string: "https://api.themoviedb.org/3/tv/\(seriesID)/reviews")!
        url.append(queryItems: [
            .init(name: "language", value: language),
            .init(name: "page", value: String(page))
        ])

        let request = makeRequest(url: url, apiKey: apiKey)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try makeDecoder().decode(ReviewsResponse.self, from: data).results
    }
}

struct Review: Decodable, Identifiable, Hashable {
    struct AuthorDetails: Decodable, Hashable {
        let avatarPath: String?
        let rating: Double?

        enum CodingKeys: String, CodingKey {
            case avatarPath = "avatar_path"
            case rating
        }
    }

    let id: String
    let author: String
    let content: String
    let createdAt: Date?
    let url: URL?
    let authorDetails: AuthorDetails?

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case content
        case createdAt = "created_at"
        case url
        case authorDetails = "author_details"
    }
}

struct ReviewsResponse: Decodable {
    let results: [Review]
}
