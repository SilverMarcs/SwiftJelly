//
//  JFAPI+Library.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Loads user libraries/views
    /// - Returns: Array of BaseItemDto representing user libraries
    static func loadLibraries() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        let parameters = Paths.GetUserViewsParameters(userID: context.userID)
        let request = Paths.getUserViews(parameters: parameters)
        let items = try await send(request).items ?? []
        let supportedTypes: [CollectionType] = [.movies, .tvshows]
        return items.filter { item in
            guard let collectionType = item.collectionType else { return false }
            return supportedTypes.contains(collectionType)
        }
    }
    /// Loads items for a specific library
    /// - Parameter library: The library to load items from
    /// - Returns: Array of BaseItemDto representing library items
    static func loadLibraryItems(for library: BaseItemDto) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.parentID = library.id
        parameters.isRecursive = true
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.sortBy = [ItemSortBy.sortName.rawValue]
        parameters.sortOrder = [SortOrder.ascending]
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
            parameters.includeItemTypes = [.movie, .series, .musicAlbum, .book, .photo]
        }
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
    
    /// Loads recently added items
    /// - Parameter limit: Maximum number of items to return (default: 20)
    /// - Returns: Array of BaseItemDto representing recently added items
    static func loadRecentlyAddedItems(limit: Int = 20) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = limit
        parameters.sortBy = [ItemSortBy.dateCreated.rawValue]
        parameters.sortOrder = [.descending]
        
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
    
    /// Loads latest media for a specific library
    /// - Parameters:
    ///   - library: The library to get latest items from
    ///   - limit: Maximum number of items to return (default: 12)
    /// - Returns: Array of BaseItemDto representing latest items in the library
    static func loadLatestMediaInLibrary(_ library: BaseItemDto, limit: Int = 12) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetLatestMediaParameters()
        parameters.userID = context.userID
        parameters.parentID = library.id
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.limit = limit
        
        let request = Paths.getLatestMedia(parameters: parameters)
        return try await send(request)
    }
}
