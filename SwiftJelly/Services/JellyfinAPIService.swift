//
//  JellyfinAPIService.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import JellyfinAPI
import Get

/// Service class that handles common Jellyfin API operations
class JellyfinAPIService {
    static let shared = JellyfinAPIService()
    private let dataManager: DataManager = .shared
    private init() {}

    /// Returns a configured JellyfinClient for the current user/server, or throws if not available
    func getClient() throws -> JellyfinClient {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }),
              let accessToken = currentUser.accessToken else {
            throw JellyfinAPIError.setupFailed
        }
        let configuration = JellyfinClient.Configuration(
            url: server.url,
            client: "SwiftJelly",
            deviceName: "SwiftJelly",
            deviceID: currentUser.id,
            version: "1.0"
        )
        return JellyfinClient(configuration: configuration, accessToken: accessToken)
    }

    /// Returns the API context (user, server, client) or throws if not available
    func getAPIContext() throws -> APIContext {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }) else {
            throw JellyfinAPIError.setupFailed
        }
        let client = try getClient()
        return APIContext(user: currentUser, server: server, client: client)
    }

    /// Result type for API setup
    struct APIContext {
        let user: User
        let server: Server
        let client: JellyfinClient
    }
}

/// Custom errors for JellyfinAPIService
enum JellyfinAPIError: LocalizedError {
    case setupFailed
    case loginFailed
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup API context - missing user, server, or client"
        case .loginFailed:
            return "Login failed - invalid username or password"
        }
    }
}
