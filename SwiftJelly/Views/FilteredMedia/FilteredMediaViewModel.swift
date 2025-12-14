//
//  FilteredMediaViewModel.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 22/09/2025.
//

import Foundation
import JellyfinAPI

@Observable class FilteredMediaViewModel {
    var items: [BaseItemDto] = []
    var isLoading = false
    var isSorting = false
    var hasNextPage = true
    var sortOption: MediaSortOption = .random
    
    @ObservationIgnored private let filter: MediaFilter
    @ObservationIgnored private let pageSize = 50
    @ObservationIgnored private var currentPage = 0
    
    init(filter: MediaFilter) {
        self.filter = filter
    }
    
    func setSortOption(_ option: MediaSortOption) async {
        guard option != sortOption, !isLoading else { return }
        sortOption = option
        isSorting = true
        await loadInitialItems()
        isSorting = false
    }
    
    func loadInitialItems() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let newItems = try await loadItems(page: 0)
            items = newItems
            hasNextPage = newItems.count >= pageSize
            currentPage = 1
        } catch {
            print("Error loading items: \(error.localizedDescription)")
        }
        
        isLoading = false
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
        
        // Apply sort option
        switch sortOption {
        case .random:
            parameters.sortBy = ["Random"]
        case .nameAscending:
            parameters.sortBy = [ItemSortBy.sortName.rawValue]
            parameters.sortOrder = [.ascending]
        case .nameDescending:
            parameters.sortBy = [ItemSortBy.sortName.rawValue]
            parameters.sortOrder = [.descending]
        case .ratingDescending:
            parameters.sortBy = [ItemSortBy.communityRating.rawValue]
            parameters.sortOrder = [.descending]
        case .ratingAscending:
            parameters.sortBy = [ItemSortBy.communityRating.rawValue]
            parameters.sortOrder = [.ascending]
        case .criticRatingDescending:
            parameters.sortBy = [ItemSortBy.criticRating.rawValue]
            parameters.sortOrder = [.descending]
        case .criticRatingAscending:
            parameters.sortBy = [ItemSortBy.criticRating.rawValue]
            parameters.sortOrder = [.ascending]
        case .yearDescending:
            parameters.sortBy = [ItemSortBy.premiereDate.rawValue]
            parameters.sortOrder = [.descending]
        case .yearAscending:
            parameters.sortBy = [ItemSortBy.premiereDate.rawValue]
            parameters.sortOrder = [.ascending]
        }
        
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
        case .favorites:
            parameters.isFavorite = true
            parameters.isRecursive = true
            parameters.includeItemTypes = [.movie, .series, .boxSet]
        case .person(let id, _):
            parameters.personIDs = [id]
            parameters.isRecursive = true
            parameters.includeItemTypes = [.movie, .series]
        }
        
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await JFAPI.send(request).items ?? []
    }
}
