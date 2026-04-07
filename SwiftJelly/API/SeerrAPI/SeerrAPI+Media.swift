//
//  SeerrAPI+Media.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

extension SeerrAPI {
    /// Fetch movie details including availability/request status
    static func fetchMovieDetails(serverURL: URL, tmdbId: Int) async throws -> SeerrMovieDetails {
        let url = endpointURL(serverURL: serverURL, path: "movie/\(tmdbId)")
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrMovieDetails.self, from: data)
    }

    /// Fetch TV details including availability/request status
    static func fetchTVDetails(serverURL: URL, tmdbId: Int) async throws -> SeerrTVDetails {
        let url = endpointURL(serverURL: serverURL, path: "tv/\(tmdbId)")
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrTVDetails.self, from: data)
    }
}
