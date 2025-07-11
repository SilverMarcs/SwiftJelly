//
//  JellyfinClient+Extensions.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import Get
import JellyfinAPI

extension JellyfinClient {

    func fullURL<T>(with request: Request<T>, queryAPIKey: Bool = false) -> URL? {

        guard let path = request.url?.path else { return configuration.url }
        guard let fullPath = fullURL(with: path) else { return nil }
        guard var components = URLComponents(string: fullPath.absoluteString) else { return nil }

        components.queryItems = request.query?.map { URLQueryItem(name: $0.0, value: $0.1) } ?? []

        if queryAPIKey, let accessToken {
            components.queryItems?.append(.init(name: "api_key", value: accessToken))
        }

        return components.url ?? fullPath
    }

    /// Appends the path to the current configuration `URL`, assuming that the path begins with a leading `/`.
    /// Returns `nil` if the new `URL` is malformed.
    func fullURL(with path: String) -> URL? {
        let fullPath = configuration.url.absoluteString.trimmingCharacters(in: ["/"]) + path
        return URL(string: fullPath)
    }
}
