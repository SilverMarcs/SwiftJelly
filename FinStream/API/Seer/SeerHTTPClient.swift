//
//  SeerHTTPClient.swift
//  SwiftJelly
//
//  Created by Julian Baumann on 12.11.26.
//

import Foundation

enum SeerHTTPClient {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration)
    }()

    static func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerAPIError.requestFailed(statusCode: 0, message: nil)
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return (data, httpResponse)
        case 401:
            throw SeerAPIError.unauthorized
        case 403:
            throw SeerAPIError.forbidden(message: errorMessage(from: data))
        default:
            throw SeerAPIError.requestFailed(statusCode: httpResponse.statusCode, message: errorMessage(from: data))
        }
    }

    static func sessionCookie(from response: HTTPURLResponse) -> String? {
        guard let url = response.url,
              let headers = response.allHeaderFields as? [String: String] else {
            return nil
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        guard !cookies.isEmpty else { return nil }
        return cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

    private static func errorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object["message"] as? String ?? object["error"] as? String
    }
}
