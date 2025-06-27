import Foundation
import SwiftUI

struct ContinueWatchingPlayerWindowData: Codable, Hashable, Identifiable {
    let id: String // MediaItem.id
    let item: MediaItem
    let serverId: String
    let userId: String

    init(item: MediaItem, serverId: String, userId: String) {
        self.id = item.id
        self.item = item
        self.serverId = serverId
        self.userId = userId
    }
}
