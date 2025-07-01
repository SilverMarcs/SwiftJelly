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
    /// - Returns: Array of BaseItemDto representing next up items
    func loadNextUpItems(limit: Int = 20) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetNextUpParameters()
        parameters.userID = context.userID
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = limit
        let request = Paths.getNextUp(parameters: parameters)
        return try await send(request).items ?? []
    }
}
