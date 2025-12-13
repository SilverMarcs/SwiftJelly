//
//  FilteredMediaViewModel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 22/09/2025.
//

import Foundation
import JellyfinAPI

enum MediaFilter {
    case library(BaseItemDto)
    case genre(String)
    case studio(NameGuidPair)
}

@Observable class FilteredMediaViewModel {
    var items: [BaseItemDto] = []
    var isLoading = false
    var hasNextPage = true
    
    @ObservationIgnored private let filter: MediaFilter
    @ObservationIgnored private let pageSize = 50
    @ObservationIgnored private var currentPage = 0
    
    init(filter: MediaFilter) {
        self.filter = filter
    }
    
    func loadInitialItems() async {
        currentPage = 0
        hasNextPage = true
        items = []
        await loadNextPage()
    }
    
    func loadNextPage() async {
        guard hasNextPage, !isLoading else { return }
        
        isLoading = true
        
        do {
            let newItems = try await loadItems(page: currentPage)
            items.append(contentsOf: newItems)
            hasNextPage = newItems.count >= pageSize
            currentPage += 1
        } catch {
            print("Error loading items: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func loadItems(page: Int) async throws -> [BaseItemDto] {
        let context = try JFAPI.getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
//        parameters.sortBy = [ItemSortBy.sortName.rawValue]
//        parameters.sortOrder = [SortOrder.ascending]
        parameters.sortBy = ["Random"]
        parameters.limit = pageSize
        parameters.startIndex = page * pageSize
        
        switch filter {
        case .library(let library):
            parameters.parentID = library.id
            parameters.isRecursive = true
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
        case .genre(let genre):
            parameters.genres = [genre]
            parameters.isRecursive = true
            parameters.includeItemTypes = [.movie, .series]
        case .studio(let studio):
            parameters.studioIDs = [studio.id!]
            parameters.isRecursive = true
            parameters.includeItemTypes = [.movie, .series]
        }
        
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await JFAPI.send(request).items ?? []
    }
}
