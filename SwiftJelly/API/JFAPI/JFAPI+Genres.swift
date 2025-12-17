//
//  JFAPI+Genres.swift
//  SwiftJelly
//
//  Created by Zabir Raihan on 13/12/2025.
//

import Foundation
import JellyfinAPI
import Get

extension JFAPI {
    static func loadGenres(limit: Int = 20) async throws -> [BaseItemDto] {
        var parameters = Paths.GetGenresParameters()
        parameters.startIndex = 0
        parameters.limit = limit
        parameters.enableImages = true
        parameters.enableTotalRecordCount = false
        parameters.sortBy = [.sortName]
        parameters.sortOrder = [.ascending]

        let request = Paths.getGenres(parameters: parameters)
        return try await send(request).items ?? []
    }

    // Unused atm
    static func loadRandomItems(_ genre: String, limit: Int = 40) async throws -> [BaseItemDto] {
        let context = try getAPIContext()
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.isRecursive = true
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.genres = [genre]
        parameters.limit = limit
        parameters.sortBy = ["Random"]

        let request = Paths.getItemsByUserID(userID: context.userID, parameters: parameters)
        return try await send(request).items ?? []
    }
}

