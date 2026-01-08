//
//  JFAPI.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import JellyfinAPI
import Get

/// Service class that handles common Jellyfin API operations
enum JFAPI {
    static let dataManager: DataManager = .shared

    /// Returns a configured JellyfinClient for the current server, or throws if not available
    static func getClient() throws -> JellyfinClient {
        guard let server = dataManager.server,
              server.isAuthenticated,
              let accessToken = server.accessToken else {
            throw JFAPIError.setupFailed
        }
        let configuration = JellyfinClient.Configuration(
            url: server.url,
            accessToken: accessToken,
            client: "SwiftJelly",
            deviceName: "SwiftJelly",
            deviceID: server.id,
            version: "1.0"
        )
        return JellyfinClient(configuration: configuration)
    }

    /// Returns the API context (server, client) or throws if not available
    static func getAPIContext() throws -> APIContext {
        guard let server = dataManager.server,
              server.isAuthenticated else {
            throw JFAPIError.setupFailed
        }
        let client = try getClient()
        return APIContext(server: server, client: client)
    }

    /// Result type for API setup
    struct APIContext {
        let server: Server
        let client: JellyfinClient
        var userID: String {
            server.jellyfinUserID ?? ""
        }
    }

    /// Generic helper to send a request using the current API context
    static func send<T>(_ request: Request<T>) async throws -> T where T: Decodable {
        let context = try getAPIContext()
        let response = try await context.client.send(request)
        return response.value
    }
}

/// Custom errors for JFAPI
enum JFAPIError: LocalizedError {
    case setupFailed
    case loginFailed
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup API context - missing server or authentication"
        case .loginFailed:
            return "Login failed - invalid username or password"
        case .itemNotFound:
            return "The requested item could not be found"
        }
    }
}
