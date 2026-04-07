//
//  SeerrAPI.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

enum SeerrAPI {
    /// Dedicated URLSession with persistent cookie storage for Seerr session auth
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpCookieAcceptPolicy = .always
        return URLSession(configuration: config)
    }()

    static func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func endpointURL(serverURL: URL, path: String, queryItems: [URLQueryItem] = []) -> URL {
        var url = serverURL.appending(path: "/api/v1/\(path)")
        if !queryItems.isEmpty {
            url.append(queryItems: queryItems)
        }
        return url
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    static var isConfigured: Bool {
        let url = UserDefaults.standard.string(forKey: "seerrServerURL") ?? ""
        let authenticated = UserDefaults.standard.bool(forKey: "seerrAuthenticated")
        return !url.isEmpty && authenticated
    }
}
