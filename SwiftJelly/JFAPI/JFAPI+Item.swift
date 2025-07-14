import Foundation
import JellyfinAPI

extension JFAPI {
    /// Loads a single item (movie, episode, etc) by its id, authenticated for the current user
    static func loadItem(by id: String) async throws -> BaseItemDto {
        let context = try getAPIContext()
        let request = Paths.getItem(itemID: id, userID: context.userID)
        return try await send(request)
    }
}
