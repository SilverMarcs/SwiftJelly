//
//  JFAPI+NextUp.swift
//  SwiftJelly
//
//  Created by Copilot on 01/07/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Loads Next Up items for the current server (episodes to continue watching)
    /// - Returns: Array of BaseItemDto representing next up items without watch progress
    func loadNextUpItems(limit: Int = 20) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetNextUpParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        let request = Paths.getNextUp(parameters: parameters)
        let items = try await send(request).items ?? []
        
        // Filter out items with watch progress
        return items.filter { item in
            guard let ticks = item.userData?.playbackPositionTicks, let runtime = item.runTimeTicks, runtime > 0 else {
                // If no watchtime data, include the item
                return true
            }
            // Exclude if any watchtime (only include unwatched items)
            return ticks == 0
        }
    }
}
