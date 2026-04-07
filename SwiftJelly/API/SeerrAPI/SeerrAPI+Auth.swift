//
//  SeerrAPI+Auth.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 04/04/2026.
//

import Foundation

extension SeerrAPI {
    /// Sign in to Seerr using Jellyfin credentials
    /// - Parameter jellyfinHostname: The Jellyfin server URL that Seerr authenticates against (optional, but often required)
    static func login(serverURL: URL, username: String, password: String, jellyfinHostname: String? = nil) async throws -> SeerrUser {
        let url = endpointURL(serverURL: serverURL, path: "auth/jellyfin")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "username": username,
            "password": password
        ]
        if let jellyfinHostname, !jellyfinHostname.isEmpty {
            body["hostname"] = jellyfinHostname
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeerrAPIError.connectionFailed
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "no body"
            print("Seerr login failed (\(httpResponse.statusCode)): \(errorBody)")
            throw SeerrAPIError.loginFailed
        }

        let user = try makeDecoder().decode(SeerrUser.self, from: data)
        UserDefaults.standard.set(true, forKey: "seerrAuthenticated")
        return user
    }

    /// Sign in to Seerr using a local account (email + password)
    static func loginLocal(serverURL: URL, email: String, password: String) async throws -> SeerrUser {
        let url = endpointURL(serverURL: serverURL, path: "auth/local")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SeerrAPIError.loginFailed
        }

        let user = try makeDecoder().decode(SeerrUser.self, from: data)
        UserDefaults.standard.set(true, forKey: "seerrAuthenticated")
        return user
    }

    /// Validates the Seerr session by calling GET /auth/me
    static func validateConnection(serverURL: URL) async throws -> SeerrUser {
        let url = endpointURL(serverURL: serverURL, path: "auth/me")
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SeerrAPIError.connectionFailed
        }

        return try makeDecoder().decode(SeerrUser.self, from: data)
    }

    /// Sign out and clear session
    static func logout(serverURL: URL) async {
        let url = endpointURL(serverURL: serverURL, path: "auth/logout")
        var request = makeRequest(url: url)
        request.httpMethod = "POST"
        _ = try? await session.data(for: request)

        // Clear cookies for this server
        if let cookies = session.configuration.httpCookieStorage?.cookies(for: serverURL) {
            for cookie in cookies {
                session.configuration.httpCookieStorage?.deleteCookie(cookie)
            }
        }

        UserDefaults.standard.set(false, forKey: "seerrAuthenticated")
    }
}

enum SeerrAPIError: LocalizedError {
    case connectionFailed
    case loginFailed
    case requestFailed(Int)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to Seerr server"
        case .loginFailed:
            return "Login failed — invalid username or password"
        case .requestFailed(let code):
            return "Seerr request failed with status \(code)"
        case .notConfigured:
            return "Seerr server is not configured"
        }
    }
}
