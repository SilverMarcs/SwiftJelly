import Foundation
import SwiftUI

import JellyfinAPI

struct ContinueWatchingPlayerWindowData: Codable, Hashable, Identifiable {
    let id: String // BaseItemDto.id
    let item: BaseItemDto
    let serverId: String
    let userId: String

    init(item: BaseItemDto, serverId: String, userId: String) {
        self.id = item.id ?? UUID().uuidString
        self.item = item
        self.serverId = serverId
        self.userId = userId
    }
}
