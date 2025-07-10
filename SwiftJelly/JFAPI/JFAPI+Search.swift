import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Search for media (movies and shows) with a query string
    /// - Parameter query: The search string
    /// - Returns: Array of BaseItemDto matching the query (movies and shows only)
    func searchMedia(query: String) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 40
        parameters.searchTerm = query
        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
}
