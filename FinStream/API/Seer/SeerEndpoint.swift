//
//  SeerEndpoint.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

struct SeerEndpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }

    let path: String
    var method: Method = .get
    var query: [String: String] = [:]
    var body: Data? = nil

    private static let queryAllowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))

    init(path: String, method: Method = .get, query: [String: String] = [:]) {
        self.path = path
        self.method = method
        self.query = query
    }

    init(path: String, method: Method = .post, body: some Encodable) throws {
        self.path = path
        self.method = method
        self.body = try JSONEncoder().encode(body)
    }

    func urlRequest(baseURL: URL, cookie: String?) throws -> URLRequest {
        let url = baseURL.appending(path: "api/v1").appending(path: path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw SeerAPIError.invalidURL
        }
        if !query.isEmpty {
            components.percentEncodedQuery = query
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: Self.queryAllowedCharacters) ?? $0.value)" }
                .joined(separator: "&")
        }
        guard let resolvedURL = components.url else {
            throw SeerAPIError.invalidURL
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let cookie {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }
        return request
    }
}
