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
    /// Authenticates a user with the given credentials and server, returning a User on success
    /// - Parameters:
    ///   - username: The username to authenticate
    ///   - password: The password to authenticate
    ///   - server: The server to authenticate against
    /// - Returns: User if authentication is successful
    func authenticateUser(username: String, password: String, server: Server) async throws -> User {
        let configuration = JellyfinClient.Configuration(
            url: server.url,
            client: "SwiftJelly",
            deviceName: "SwiftJelly",
            deviceID: UUID().uuidString,
            version: "1.0"
        )
        let client = JellyfinClient(configuration: configuration)
        let authRequest = Paths.authenticateUserByName(
            AuthenticateUserByName(
                pw: password.isEmpty ? nil : password,
                username: username
            )
        )
        let response = try await client.send(authRequest)
        let authResult = response.value
        guard let accessToken = authResult.accessToken,
              let userData = authResult.user else {
            throw JellyfinAPIError.loginFailed
        }
        return User(
            id: userData.id ?? UUID().uuidString,
            serverID: server.id,
            username: username,
            accessToken: accessToken
        )
    }
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
    
    /// Loads resume items for the current user
    /// - Returns: Array of BaseItemDto representing resume items
    func loadResumeItems() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.user.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .episode]
        parameters.limit = 20
        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
    
    /// Loads user libraries/views
    /// - Returns: Array of BaseItemDto representing user libraries
    func loadLibraries() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        let parameters = Paths.GetUserViewsParameters(userID: context.user.id)
        let request = Paths.getUserViews(parameters: parameters)
        let response = try await context.client.send(request)
        // Filter to only supported collection types
        let supportedTypes: [CollectionType] = [.movies, .tvshows]
        return (response.value.items ?? []).filter { item in
            guard let collectionType = item.collectionType else { return false }
            return supportedTypes.contains(collectionType)
        }
    }
    
    /// Loads items for a specific library
    /// - Parameter library: The library to load items from
    /// - Returns: Array of BaseItemDto representing library items
    func loadLibraryItems(for library: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.parentID = library.id
        parameters.isRecursive = true
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.sortBy = [ItemSortBy.sortName.rawValue]
        parameters.sortOrder = [SortOrder.ascending]
        // Filter by item types based on library collection type
        switch library.collectionType {
        case .movies:
            parameters.includeItemTypes = [.movie]
        case .tvshows:
            parameters.includeItemTypes = [.series]
        case .music:
            parameters.includeItemTypes = [.musicAlbum]
        case .books:
            parameters.includeItemTypes = [.book]
        case .photos:
            parameters.includeItemTypes = [.photo]
        default:
            // For other types, include common media types
            parameters.includeItemTypes = [.movie, .series, .musicAlbum, .book, .photo]
        }
        let request = Paths.getItemsByUserID(userID: context.user.id, parameters: parameters)
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
    
    /// Reports playback progress to the Jellyfin server
    /// - Parameters:
    ///   - item: The item being played
    ///   - positionTicks: Current playback position in ticks
    ///   - isPaused: Whether playback is currently paused
    func reportPlaybackProgress(for item: BaseItemDto, positionTicks: Int64, isPaused: Bool) async throws {
     
    }
    
    /// Reports playback stop to the Jellyfin server
    /// - Parameters:
    ///   - item: The item that was being played
    ///   - positionTicks: Final playback position in ticks
    func reportPlaybackStopped(for item: BaseItemDto, positionTicks: Int64) async throws {
       
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
