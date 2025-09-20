import Foundation
import JellyfinAPI

extension JFAPI {
    /// Loads a single item (movie, episode, etc) by its id, authenticated for the current user
    static func loadItem(by id: String) async throws -> BaseItemDto {
        let context = try getAPIContext()
        let request = Paths.getItem(itemID: id, userID: context.userID)
        return try await send(request)
    }
    
    /// Loads similar/recommended items for a given item
    static func loadSimilarItems(for item: BaseItemDto, limit: Int = 20) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetSimilarItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = limit
        parameters.userID = context.userID
        
        let request = Paths.getSimilarItems(itemID: item.id ?? "", parameters: parameters)
        let response = try await send(request)
        return response.items ?? []
    }
}
