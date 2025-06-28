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
    
    /// Result type for API setup
    struct APIContext {
        let user: User
        let server: Server
        let client: JellyfinClient
    }
    
    /// Sets up the API context (user, server, client) for making requests
    /// - Returns: APIContext if successful, nil if setup fails
    func setupAPIContext() -> APIContext? {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }),
              let client = dataManager.jellyfinClient(for: currentUser, server: server) else {
            print("JellyfinAPIService: Failed to setup API context - missing user, server, or client")
            return nil
        }
        
        return APIContext(user: currentUser, server: server, client: client)
    }
    
    /// Loads resume items for the current user
    /// - Returns: Array of BaseItemDto representing resume items
    func loadResumeItems() async throws -> [BaseItemDto] {
        guard let context = setupAPIContext() else {
            throw JellyfinAPIError.setupFailed
        }
        
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
        guard let context = setupAPIContext() else {
            throw JellyfinAPIError.setupFailed
        }
        
        let parameters = Paths.GetUserViewsParameters(userID: context.user.id)
        let request = Paths.getUserViews(parameters: parameters)
        let response = try await context.client.send(request)
        
        // Filter to only supported collection types
        let supportedTypes: [CollectionType] = [.movies, .tvshows, .music, .books, .photos]
        return (response.value.items ?? []).filter { item in
            guard let collectionType = item.collectionType else { return false }
            return supportedTypes.contains(collectionType)
        }
    }
    
    /// Loads items for a specific library
    /// - Parameter library: The library to load items from
    /// - Returns: Array of BaseItemDto representing library items
    func loadLibraryItems(for library: BaseItemDto) async throws -> [BaseItemDto] {
        guard let context = setupAPIContext() else {
            throw JellyfinAPIError.setupFailed
        }
        
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
    
    var errorDescription: String? {
        switch self {
        case .setupFailed:
            return "Failed to setup API context - missing user, server, or client"
        }
    }
}
