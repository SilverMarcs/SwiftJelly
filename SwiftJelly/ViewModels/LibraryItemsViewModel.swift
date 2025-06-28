//
//  LibraryItemsViewModel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 28/06/2025.
//

import Foundation
import JellyfinAPI
import Combine
import Get

@MainActor
class LibraryItemsViewModel: ObservableObject {
    @Published var items: [BaseItemDto] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let dataManager: DataManager = .shared
    private let library: BaseItemDto
    
    init(library: BaseItemDto) {
        self.library = library
    }
    
    func loadItems() async {
        guard let currentUser = dataManager.currentUser,
              let server = dataManager.servers.first(where: { $0.id == currentUser.serverID }),
              let client = dataManager.jellyfinClient(for: currentUser, server: server) else {
            error = "No user, server, or client found"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
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
            
            let request = Paths.getItemsByUserID(userID: currentUser.id, parameters: parameters)
            let response = try await client.send(request)
            items = response.value.items ?? []
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
