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
class JFAPI {
    static let shared = JFAPI()
    private let dataManager: DataManager = .shared
    private init() {}

    /// Returns a configured JellyfinClient for the current server, or throws if not available
    func getClient() throws -> JellyfinClient {
        guard let currentServer = dataManager.currentServer,
              currentServer.isAuthenticated,
              let accessToken = currentServer.accessToken else {
            throw JFAPIError.setupFailed
        }
        let configuration = JellyfinClient.Configuration(
            url: currentServer.url,
            client: "SwiftJelly",
            deviceName: "SwiftJelly",
            deviceID: currentServer.id,
            version: "1.0"
        )
        return JellyfinClient(configuration: configuration, accessToken: accessToken)
    }

    /// Returns the API context (server, client) or throws if not available
    func getAPIContext() throws -> APIContext {
        guard let currentServer = dataManager.currentServer,
              currentServer.isAuthenticated else {
            throw JFAPIError.setupFailed
        }
        let client = try getClient()
        return APIContext(server: currentServer, client: client)
    }

    /// Result type for API setup
    struct APIContext {
        let server: Server
        let client: JellyfinClient
    }
}

/// Custom errors for JFAPI
enum JFAPIError: LocalizedError {
    case setupFailed
    case loginFailed
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup API context - missing server or authentication"
        case .loginFailed:
            return "Login failed - invalid username or password"
        }
    }
}
