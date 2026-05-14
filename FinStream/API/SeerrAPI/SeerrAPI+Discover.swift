//
//  SeerrAPI+Discover.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

extension SeerrAPI {
    /// Fetch trending movies and TV shows
    static func fetchTrending(serverURL: URL, page: Int = 1) async throws -> SeerrPaginatedResponse<SeerrSearchResult> {
        let url = endpointURL(serverURL: serverURL, path: "discover/trending", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
        ])
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrPaginatedResponse<SeerrSearchResult>.self, from: data)
    }

    /// Discover popular movies
    static func discoverMovies(serverURL: URL, page: Int = 1, filters: DiscoverFilters = DiscoverFilters()) async throws -> SeerrPaginatedResponse<SeerrSearchResult> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        queryItems.append(contentsOf: filters.queryItems)
        let url = endpointURL(serverURL: serverURL, path: "discover/movies", queryItems: queryItems)
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrPaginatedResponse<SeerrSearchResult>.self, from: data)
    }

    /// Discover popular TV shows
    static func discoverTV(serverURL: URL, page: Int = 1, filters: DiscoverFilters = DiscoverFilters()) async throws -> SeerrPaginatedResponse<SeerrSearchResult> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        queryItems.append(contentsOf: filters.queryItems)
        let url = endpointURL(serverURL: serverURL, path: "discover/tv", queryItems: queryItems)
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrPaginatedResponse<SeerrSearchResult>.self, from: data)
    }

    /// Discover upcoming movies
    static func discoverUpcomingMovies(serverURL: URL, page: Int = 1) async throws -> SeerrPaginatedResponse<SeerrSearchResult> {
        let url = endpointURL(serverURL: serverURL, path: "discover/movies/upcoming", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
        ])
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrPaginatedResponse<SeerrSearchResult>.self, from: data)
    }
}
