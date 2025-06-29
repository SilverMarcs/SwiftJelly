//
//  JellyfinAPIService+Library.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JellyfinAPIService {
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
}
