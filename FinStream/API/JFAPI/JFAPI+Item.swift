import Foundation
import Get
import JellyfinAPI

extension JFAPI {
    /// Loads a single item (movie, episode, etc) by its id, authenticated for the current user
    static func loadItem(by id: String, fields: [ItemFields]? = nil, context suppliedContext: APIContext? = nil) async throws -> BaseItemDto {
        let context = try suppliedContext ?? getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = fields ?? .MinimumFields
        parameters.ids = [id]
        parameters.enableUserData = true

        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        let response = try await context.client.send(request)
        guard let item = response.value.items?.first else {
            throw JFAPIError.itemNotFound
        }
        return item
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
