import Foundation
import JellyfinAPI

extension JFAPI {
    /// Marks an item as favorite for the current user
    static func markItemFavorite(itemId: String) async throws {
        let context = try getAPIContext()
        let request = Paths.markFavoriteItem(itemID: itemId, userID: context.userID)
        let _ = try await send(request)
    }
    
    /// Removes an item from favorites for the current user
    static func unmarkItemFavorite(itemId: String) async throws {
        let context = try getAPIContext()
        let request = Paths.unmarkFavoriteItem(itemID: itemId, userID: context.userID)
        let _ = try await send(request)
    }
    
    /// Toggles favorite status for an item
    static func toggleItemFavoriteStatus(item: BaseItemDto) async throws {
        guard let itemId = item.id else { return }
        let isFavorite = item.userData?.isFavorite == true
        if isFavorite {
            try await unmarkItemFavorite(itemId: itemId)
        } else {
            try await markItemFavorite(itemId: itemId)
        }
    }
    
    /// Loads favorite movie & series items (minimal implementation)
    static func loadFavoriteItems(limit: Int = 18) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.includeItemTypes = [.movie, .series, .boxSet]
        parameters.isFavorite = true
        parameters.isRecursive = true
        parameters.sortBy = ["Random"]
        parameters.limit = limit
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
}
