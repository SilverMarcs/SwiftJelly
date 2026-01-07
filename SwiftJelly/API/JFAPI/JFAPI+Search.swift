import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Search for media (movies and shows) with a query string
    /// - Parameter query: The search string
    /// - Returns: Array of BaseItemDto matching the query (movies and shows only)
    static func searchMedia(query: String) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 10
        parameters.searchTerm = query
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
    
    /// Search for persons (actors, directors, etc.) with a query string
    /// - Parameter query: The search string
    /// - Returns: Array of BaseItemDto representing persons matching the query
    static func searchPersons(query: String) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetPersonsParameters()
        parameters.searchTerm = query
        parameters.limit = 30
        parameters.enableImages = true
        parameters.userID = context.userID
        let request = Paths.getPersons(parameters: parameters)
        return try await send(request).items ?? []
    }
}
