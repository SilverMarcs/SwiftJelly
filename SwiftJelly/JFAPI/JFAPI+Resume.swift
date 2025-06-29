//
//  JFAPI+Resume.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 29/06/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    /// Loads resume items for the current user
    /// - Returns: Array of BaseItemDto representing resume items
    func loadResumeItems() async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = context.user.id
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .episode]
        parameters.limit = 20
        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await context.client.send(request)
        return response.value.items ?? []
    }
}
