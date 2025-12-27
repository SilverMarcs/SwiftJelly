import Foundation
import JellyfinAPI

extension JFAPI {
    static func markItemPlayed(itemId: String) async throws {
        let context = try getAPIContext()
        let request = Paths.markPlayedItem(
            itemID: itemId,
            userID: context.userID
        )
        let _ = try await send(request)
    }
    
    static func markItemUnplayed(itemId: String) async throws {
        let context = try getAPIContext()
        let request = Paths.markUnplayedItem(
            itemID: itemId,
            userID: context.userID
        )
        let _ = try await send(request)
    }
    
    static func toggleItemPlayedStatus(item: BaseItemDto) async throws {
        guard let itemId = item.id else { return }
        let isPlayed = item.userData?.isPlayed == true
        if isPlayed {
            try await markItemUnplayed(itemId: itemId)
        } else {
            try await markItemPlayed(itemId: itemId)
        }
    }
}
