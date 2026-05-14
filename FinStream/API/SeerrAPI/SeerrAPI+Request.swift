//
//  SeerrAPI+Request.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

extension SeerrAPI {
    /// Create a media request
    static func createRequest(
        serverURL: URL,
        mediaType: String,
        mediaId: Int,
        seasons: [Int]? = nil
    ) async throws -> SeerrMediaRequest {
        let url = endpointURL(serverURL: serverURL, path: "request")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "mediaType": mediaType,
            "mediaId": mediaId
        ]
        if let seasons {
            body["seasons"] = seasons
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrMediaRequest.self, from: data)
    }

    /// Fetch paginated requests
    static func fetchRequests(
        serverURL: URL,
        take: Int = 20,
        skip: Int = 0,
        filter: String = "all",
        sort: String = "added"
    ) async throws -> SeerrRequestListResponse {
        let url = endpointURL(serverURL: serverURL, path: "request", queryItems: [
            URLQueryItem(name: "take", value: String(take)),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "filter", value: filter),
            URLQueryItem(name: "sort", value: sort),
        ])
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrRequestListResponse.self, from: data)
    }

    /// Fetch request counts by status
    static func fetchRequestCount(serverURL: URL) async throws -> SeerrRequestCount {
        let url = endpointURL(serverURL: serverURL, path: "request/count")
        let request = makeRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try makeDecoder().decode(SeerrRequestCount.self, from: data)
    }
}
