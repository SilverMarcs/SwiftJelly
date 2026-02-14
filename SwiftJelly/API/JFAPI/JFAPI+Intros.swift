//
//  JFAPI+Intros.swift
//  SwiftJelly
//
//  Created by Rovo Dev on 01/02/2026.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    
    /// Fetches intro/pre-roll items to play before the main media item.
    /// These are typically provided by plugins like Local Intros Plugin.
    /// - Parameter item: The main item that will be played after intros
    /// - Returns: Array of intro items to play before the main content, empty if none
    static func getIntros(for item: BaseItemDto) async throws -> [BaseItemDto] {
        guard let itemID = item.id else {
            return []
        }
        
        let context = try getAPIContext()
        
        // The Jellyfin API endpoint: GET /Items/{itemId}/Intros
        // Returns BaseItemDtoQueryResult with intro items
        let path = "/Items/\(itemID)/Intros"
        let request = Request<BaseItemDtoQueryResult>(
            path: path,
            query: [("userId", context.userID)]
        )
        
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
}
